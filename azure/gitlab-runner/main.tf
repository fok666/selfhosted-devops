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

resource "azurerm_resource_group" "runner" {
  name     = "${var.project_name}-rg"
  location = var.location
  tags     = var.tags
}

# =============================================================================
# SSH Key Generation
# =============================================================================

resource "tls_private_key" "runner" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# =============================================================================
# Cloud-Init Configuration
# =============================================================================

locals {
  runner_name = "${var.project_name}-gitlab-runner"

  cloud_init = templatefile("${path.module}/cloud-init.yaml", {
    gitlab_url                   = var.gitlab_url
    gitlab_token                 = var.gitlab_token
    runner_tags                  = var.runner_tags
    runner_count                 = var.runner_count_per_instance
    docker_image                 = var.docker_image
    runner_docker_image          = "fok666/gitlab-runner:latest"
    enable_distributed_cache     = var.enable_distributed_cache
    cache_type                   = var.cache_type
    cache_shared                 = var.cache_shared
    cache_storage_account_name   = var.cache_storage_account_name
    cache_storage_container_name = var.cache_storage_container_name
    cache_storage_account_key    = var.cache_storage_account_key
    enable_centralized_logging   = var.enable_centralized_logging
    log_analytics_workspace_id   = var.log_analytics_workspace_id
    log_analytics_workspace_key  = var.log_analytics_workspace_key
    enable_runner_monitoring     = var.enable_runner_monitoring
    metrics_port                 = var.metrics_port
  })
}

# =============================================================================
# GitLab Runner VMSS
# =============================================================================

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
  zones               = var.zones
  ssh_public_key      = tls_private_key.runner.public_key_openssh
  custom_data         = local.cloud_init
  docker_image        = var.docker_image
  subnet_id           = local.subnet_id
  os_disk_size_gb     = var.os_disk_size_gb
  os_disk_type        = var.os_disk_type

  source_image_reference = var.source_image_reference

  tags = var.tags
}
