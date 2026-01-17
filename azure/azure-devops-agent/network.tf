# =============================================================================
# Network Infrastructure Configuration
# =============================================================================
# This file contains all network-related resources for Azure DevOps agents.
# Supports both creating new network infrastructure and using existing resources.

# =============================================================================
# Data Sources - Existing Network Resources (when using existing infrastructure)
# =============================================================================

data "azurerm_virtual_network" "existing" {
  count               = var.create_vnet ? 0 : 1
  name                = var.existing_vnet_name
  resource_group_name = var.existing_vnet_resource_group_name != "" ? var.existing_vnet_resource_group_name : azurerm_resource_group.agent.name
}

data "azurerm_subnet" "existing" {
  count                = var.create_subnet ? 0 : 1
  name                 = var.existing_subnet_name
  virtual_network_name = var.create_vnet ? azurerm_virtual_network.agent[0].name : var.existing_vnet_name
  resource_group_name  = var.create_vnet ? azurerm_resource_group.agent.name : (var.existing_vnet_resource_group_name != "" ? var.existing_vnet_resource_group_name : azurerm_resource_group.agent.name)
}

data "azurerm_network_security_group" "existing" {
  count               = var.create_nsg ? 0 : 1
  name                = var.existing_nsg_name
  resource_group_name = var.existing_nsg_resource_group_name != "" ? var.existing_nsg_resource_group_name : azurerm_resource_group.agent.name
}

# =============================================================================
# Virtual Network (created only if create_vnet = true)
# =============================================================================

resource "azurerm_virtual_network" "agent" {
  count               = var.create_vnet ? 1 : 0
  name                = "${var.project_name}-vnet"
  address_space       = [var.vnet_address_space]
  location            = azurerm_resource_group.agent.location
  resource_group_name = azurerm_resource_group.agent.name

  tags = var.tags
}

# =============================================================================
# Subnet (created only if create_subnet = true)
# =============================================================================

resource "azurerm_subnet" "agent" {
  count                = var.create_subnet ? 1 : 0
  name                 = "${var.project_name}-subnet"
  resource_group_name  = azurerm_resource_group.agent.name
  virtual_network_name = var.create_vnet ? azurerm_virtual_network.agent[0].name : var.existing_vnet_name
  address_prefixes     = [var.subnet_address_prefix]
}

# =============================================================================
# Network Security Group (created only if create_nsg = true)
# =============================================================================

resource "azurerm_network_security_group" "agent" {
  count               = var.create_nsg ? 1 : 0
  name                = "${var.project_name}-nsg"
  location            = azurerm_resource_group.agent.location
  resource_group_name = azurerm_resource_group.agent.name

  # Allow outbound internet access (configurable, defaults to HTTPS/TCP only for security)
  dynamic "security_rule" {
    for_each = var.nsg_outbound_internet_access ? [1] : []
    content {
      name                       = "AllowInternetOutbound"
      priority                   = 100
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = var.nsg_outbound_protocol
      source_port_range          = "*"
      destination_port_range     = var.nsg_outbound_destination_port_range
      source_address_prefix      = "*"
      destination_address_prefix = var.nsg_outbound_destination_address_prefix
    }
  }

  # Optional SSH access (disabled by default for security)
  dynamic "security_rule" {
    for_each = var.enable_ssh_access && length(var.ssh_source_address_prefixes) > 0 ? [1] : []
    content {
      name                       = "allow-ssh"
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

  # Additional custom security rules
  dynamic "security_rule" {
    for_each = var.additional_nsg_rules
    content {
      name                         = security_rule.value.name
      priority                     = security_rule.value.priority
      direction                    = security_rule.value.direction
      access                       = security_rule.value.access
      protocol                     = security_rule.value.protocol
      source_port_range            = security_rule.value.source_port_range
      destination_port_range       = security_rule.value.destination_port_range
      source_address_prefix        = security_rule.value.source_address_prefix
      destination_address_prefix   = security_rule.value.destination_address_prefix
      source_address_prefixes      = security_rule.value.source_address_prefixes
      destination_address_prefixes = security_rule.value.destination_address_prefixes
    }
  }

  tags = var.tags
}

# =============================================================================
# Associate NSG with Subnet (only if both are created or if using existing NSG)
# =============================================================================

resource "azurerm_subnet_network_security_group_association" "agent" {
  count                     = var.create_nsg_association ? 1 : 0
  subnet_id                 = local.subnet_id
  network_security_group_id = local.nsg_id
}

# =============================================================================
# Local Values - Network Resource IDs
# =============================================================================

locals {
  # VNet ID
  vnet_id = var.create_vnet ? azurerm_virtual_network.agent[0].id : data.azurerm_virtual_network.existing[0].id

  # Subnet ID
  subnet_id = var.create_subnet ? azurerm_subnet.agent[0].id : data.azurerm_subnet.existing[0].id

  # NSG ID
  nsg_id = var.create_nsg ? azurerm_network_security_group.agent[0].id : data.azurerm_network_security_group.existing[0].id
}
