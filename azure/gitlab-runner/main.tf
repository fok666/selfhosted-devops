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

locals {
  runner_name = "${var.project_name}-gitlab-runner"

  cloud_init = templatefile("${path.module}/cloud-init.yaml", {
    gitlab_url          = var.gitlab_url
    gitlab_token        = var.gitlab_token
    runner_tags         = var.runner_tags
    runner_count        = var.runner_count_per_vm
    docker_image        = var.docker_image
    runner_docker_image = "fok666/gitlab-runner:latest"
  })
}

# Resource group
resource "azurerm_resource_group" "runner" {
  name     = "${var.project_name}-rg"
  location = var.location
  tags     = var.tags
}

# Virtual network
resource "azurerm_virtual_network" "runner" {
  name                = "${var.project_name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.runner.location
  resource_group_name = azurerm_resource_group.runner.name
  tags                = var.tags
}

# Subnet
resource "azurerm_subnet" "runner" {
  name                 = "${var.project_name}-subnet"
  resource_group_name  = azurerm_resource_group.runner.name
  virtual_network_name = azurerm_virtual_network.runner.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Network security group
resource "azurerm_network_security_group" "runner" {
  name                = "${var.project_name}-nsg"
  location            = azurerm_resource_group.runner.location
  resource_group_name = azurerm_resource_group.runner.name

  # Allow outbound internet access
  security_rule {
    name                       = "AllowInternetOutbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }

  # Optional SSH access (disabled by default for security)
  dynamic "security_rule" {
    for_each = var.enable_ssh_access && length(var.ssh_source_address_prefixes) > 0 ? [1] : []
    content {
      name                       = "AllowSSHInbound"
      priority                   = 1001
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefixes    = var.ssh_source_address_prefixes
      destination_address_prefix = "*"
    }
  }

  tags = var.tags
}

# Associate NSG with subnet
resource "azurerm_subnet_network_security_group_association" "runner" {
  subnet_id                 = azurerm_subnet.runner.id
  network_security_group_id = azurerm_network_security_group.runner.id
}

# Generate SSH key
resource "tls_private_key" "runner" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# VMSS using shared module
module "gitlab_runner_vmss" {
  source = "../../modules/azure-vmss"

  resource_group_name = azurerm_resource_group.runner.name
  location            = azurerm_resource_group.runner.location
  vmss_name           = local.runner_name
  vm_sku              = var.vm_sku
  use_spot_instances  = var.use_spot_instances
  spot_max_price      = var.spot_max_price
  min_instances       = var.min_instances
  max_instances       = var.max_instances
  default_instances   = var.default_instances
  ssh_public_key      = tls_private_key.runner.public_key_openssh
  custom_data         = local.cloud_init
  docker_image        = var.docker_image
  subnet_id           = azurerm_subnet.runner.id
  os_disk_size_gb     = var.os_disk_size_gb
  os_disk_type        = var.os_disk_type
  tags                = var.tags

  source_image_reference = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}
