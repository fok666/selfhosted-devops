terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.57"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Generate SSH key pair
resource "tls_private_key" "agent" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Resource group
resource "azurerm_resource_group" "agent" {
  name     = "${var.project_name}-rg"
  location = var.location

  tags = merge(
    var.tags,
    {
      Environment = "production"
      ManagedBy   = "terraform"
      Purpose     = "azure-devops-agent"
    }
  )
}

# Virtual network
resource "azurerm_virtual_network" "agent" {
  name                = "${var.project_name}-vnet"
  address_space       = [var.vnet_address_space]
  location            = azurerm_resource_group.agent.location
  resource_group_name = azurerm_resource_group.agent.name

  tags = var.tags
}

# Subnet
resource "azurerm_subnet" "agent" {
  name                 = "${var.project_name}-subnet"
  resource_group_name  = azurerm_resource_group.agent.name
  virtual_network_name = azurerm_virtual_network.agent.name
  address_prefixes     = [var.subnet_address_prefix]
}

# Network Security Group
resource "azurerm_network_security_group" "agent" {
  name                = "${var.project_name}-nsg"
  location            = azurerm_resource_group.agent.location
  resource_group_name = azurerm_resource_group.agent.name

  # Allow outbound internet (required for Azure DevOps)
  security_rule {
    name                       = "allow-outbound-internet"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }

  # Optional SSH access (disabled by default for security)
  dynamic "security_rule" {
    for_each = var.enable_ssh_access && length(var.ssh_source_address_prefixes) > 0 ? [1] : []
    content {
      name                         = "allow-ssh"
      priority                     = 1001
      direction                    = "Inbound"
      access                       = "Allow"
      protocol                     = "Tcp"
      source_port_range            = "*"
      destination_port_range       = "22"
      source_address_prefixes      = var.ssh_source_address_prefixes
      destination_address_prefix   = "*"
    }
  }

  tags = var.tags
}

# Associate NSG with subnet
resource "azurerm_subnet_network_security_group_association" "agent" {
  subnet_id                 = azurerm_subnet.agent.id
  network_security_group_id = azurerm_network_security_group.agent.id
}

# Prepare cloud-init data
locals {
  cloud_init_rendered = templatefile("${path.module}/cloud-init.yaml", {
    azp_url        = var.azp_url
    azp_token      = var.azp_token
    azp_pool       = var.azp_pool
    azp_agent_name = var.azp_agent_name_prefix    agent_count    = var.agent_count_per_vm  })
}

# Azure DevOps Agent VMSS
module "agent_vmss" {
  source = "../../modules/azure-vmss"

  vmss_name           = "${var.project_name}-azdevops-agent"
  location            = azurerm_resource_group.agent.location
  resource_group_name = azurerm_resource_group.agent.name

  subnet_id      = azurerm_subnet.agent.id
  ssh_public_key = tls_private_key.agent.public_key_openssh

  custom_data  = base64encode(local.cloud_init_rendered)
  docker_image = "fok666/azuredevops:latest"

  vm_sku             = var.vm_sku
  min_instances      = var.min_instances
  max_instances      = var.max_instances
  default_instances  = var.default_instances
  use_spot_instances = var.use_spot_instances
  spot_max_price     = var.spot_max_price
  zones              = var.zones

  tags = merge(
    var.tags,
    {
      Agent = "azure-devops"
      Pool  = var.azp_pool
    }
  )
}
