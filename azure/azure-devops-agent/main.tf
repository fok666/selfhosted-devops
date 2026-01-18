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

# =============================================================================
# Resource Group
# =============================================================================

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

# =============================================================================
# SSH Key Generation
# =============================================================================

resource "tls_private_key" "agent" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# =============================================================================
# Cloud-Init Configuration
# =============================================================================

locals {
  agent_name = "${var.project_name}-azdevops-agent"

  cloud_init = templatefile("${path.module}/cloud-init.yaml", {
    azp_url        = var.azp_url
    azp_token      = var.azp_token
    azp_pool       = var.azp_pool
    azp_agent_name = var.azp_agent_name_prefix
    agent_count    = var.runner_count_per_instance

    # Production Features - Distributed Caching
    enable_distributed_cache     = var.enable_distributed_cache
    cache_storage_account_name   = var.cache_storage_account_name
    cache_storage_container_name = var.cache_storage_container_name
    cache_storage_account_key    = var.cache_storage_account_key
    cache_shared                 = var.cache_shared

    # Production Features - Centralized Logging
    enable_centralized_logging  = var.enable_centralized_logging
    log_analytics_workspace_id  = var.log_analytics_workspace_id
    log_analytics_workspace_key = var.log_analytics_workspace_key
    log_retention_days          = var.log_retention_days

    # Production Features - Agent Monitoring
    enable_agent_monitoring = var.enable_agent_monitoring
    metrics_port            = var.metrics_port
  })
}

# =============================================================================
# Azure DevOps Agent VMSS
# =============================================================================

module "agent_vmss" {
  source = "../../modules/azure-vmss"

  vmss_name           = local.agent_name
  location            = azurerm_resource_group.agent.location
  resource_group_name = azurerm_resource_group.agent.name

  subnet_id      = local.subnet_id
  ssh_public_key = tls_private_key.agent.public_key_openssh

  custom_data  = local.cloud_init
  docker_image = "fok666/azuredevops:latest"

  vm_sku             = var.vm_sku
  min_instances      = var.min_instances
  max_instances      = var.max_instances
  default_instances  = var.default_instances
  use_spot_instances = var.use_spot_instances
  spot_max_price     = var.spot_max_price
  zones              = var.zones

  os_disk_size_gb = var.os_disk_size_gb
  os_disk_type    = var.os_disk_type

  source_image_reference = var.source_image_reference

  tags = merge(
    var.tags,
    {
      Agent = "azure-devops"
      Pool  = var.azp_pool
    }
  )
}
