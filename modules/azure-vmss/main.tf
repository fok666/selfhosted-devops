terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0, < 5.0"
    }
  }
}

resource "azurerm_linux_virtual_machine_scale_set" "vmss" {
  name                = var.vmss_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.vm_sku
  instances           = var.default_instances
  admin_username      = var.admin_username
  upgrade_mode        = var.upgrade_mode

  # Spot instance configuration
  priority        = var.use_spot_instances ? "Spot" : "Regular"
  eviction_policy = var.use_spot_instances ? "Delete" : null
  max_bid_price   = var.use_spot_instances ? var.spot_max_price : null

  # Zones for high availability
  zones = var.zones

  # SSH key authentication
  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  # Source image
  source_image_reference {
    publisher = var.source_image_reference.publisher
    offer     = var.source_image_reference.offer
    sku       = var.source_image_reference.sku
    version   = var.source_image_reference.version
  }

  # OS disk configuration
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_type
    disk_size_gb         = var.os_disk_size_gb
  }

  # Network configuration
  network_interface {
    name                          = "${var.vmss_name}-nic"
    primary                       = true
    enable_accelerated_networking = var.enable_accelerated_networking

    ip_configuration {
      name                                   = "internal"
      primary                                = true
      subnet_id                              = var.subnet_id
      load_balancer_backend_address_pool_ids = var.health_probe_id != null ? [var.health_probe_id] : null
    }
  }

  # Custom data (cloud-init)
  custom_data = base64encode(var.custom_data)

  # Automatic instance repairs (requires health probe)
  dynamic "automatic_instance_repair" {
    for_each = var.health_probe_id != null ? [1] : []
    content {
      enabled      = true
      grace_period = "PT10M"
    }
  }

  # Scale-in policy
  scale_in {
    rule                   = "OldestVM"
    force_deletion_enabled = true
  }

  # Boot diagnostics
  boot_diagnostics {
    storage_account_uri = null # Use managed storage
  }

  # Automatic OS upgrades disabled for custom images
  automatic_os_upgrade_policy {
    disable_automatic_rollback  = false
    enable_automatic_os_upgrade = false
  }

  # Rolling upgrade policy (if upgrade_mode is "Rolling")
  dynamic "rolling_upgrade_policy" {
    for_each = var.upgrade_mode == "Rolling" ? [1] : []
    content {
      max_batch_instance_percent              = 20
      max_unhealthy_instance_percent          = 20
      max_unhealthy_upgraded_instance_percent = 20
      pause_time_between_batches              = "PT2M"
    }
  }

  # Identity for accessing Azure resources
  identity {
    type = "SystemAssigned"
  }

  tags = merge(
    var.tags,
    {
      ManagedBy    = "Terraform"
      SpotInstance = var.use_spot_instances ? "true" : "false"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Autoscale settings
resource "azurerm_monitor_autoscale_setting" "vmss_autoscale" {
  name                = "${var.vmss_name}-autoscale"
  resource_group_name = var.resource_group_name
  location            = var.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.vmss.id

  profile {
    name = "defaultProfile"

    capacity {
      default = var.default_instances
      minimum = var.min_instances
      maximum = var.max_instances
    }

    # Scale out when CPU > 75%
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 75
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    # Scale in when CPU < 25%
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT10M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT10M"
      }
    }
  }

  notification {
    email {
      send_to_subscription_administrator    = false
      send_to_subscription_co_administrator = false
    }
  }

  tags = var.tags
}
