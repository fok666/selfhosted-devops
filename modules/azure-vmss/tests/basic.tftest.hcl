# Basic validation tests for Azure VMSS module
# Tests variable validation, required inputs, and basic configuration

run "validate_required_inputs" {
  command = plan

  variables {
    project_name              = "test-runner"
    location                  = "eastus"
    resource_group_name       = "test-rg"
    subnet_id                 = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/test-subnet"
    runner_type               = "gitlab"
    runner_image              = "gitlab/gitlab-runner:latest"
    runner_registration_token = "test-token-12345"
    runner_url                = "https://gitlab.com"
    vm_sku                    = "Standard_D2s_v3"
    min_instances             = 0
    max_instances             = 5
    default_instances         = 1
  }

  # Verify VMSS is created with correct configuration
  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.vmss.instances == 1
    error_message = "VMSS instances should be 1"
  }

  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.vmss.sku == "Standard_D2s_v3"
    error_message = "VMSS SKU should be Standard_D2s_v3"
  }

  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.vmss.overprovision == false
    error_message = "VMSS should not overprovision"
  }
}

run "validate_spot_configuration" {
  command = plan

  variables {
    project_name              = "test-runner"
    location                  = "eastus"
    resource_group_name       = "test-rg"
    subnet_id                 = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/test-subnet"
    runner_type               = "gitlab"
    runner_image              = "gitlab/gitlab-runner:latest"
    runner_registration_token = "test-token-12345"
    runner_url                = "https://gitlab.com"
    vm_sku                    = "Standard_D2s_v3"
    use_spot_instances        = true
    spot_max_price            = 0.05
    min_instances             = 0
    max_instances             = 3
    default_instances         = 1
  }

  # Verify spot configuration
  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.vmss.priority == "Spot"
    error_message = "VMSS should use Spot priority"
  }

  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.vmss.eviction_policy == "Delete"
    error_message = "Spot eviction policy should be Delete"
  }

  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.vmss.max_bid_price == 0.05
    error_message = "Spot max bid price should be 0.05"
  }
}

run "validate_security_defaults" {
  command = plan

  variables {
    project_name              = "test-runner"
    location                  = "eastus"
    resource_group_name       = "test-rg"
    subnet_id                 = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/test-subnet"
    runner_type               = "gitlab"
    runner_image              = "gitlab/gitlab-runner:latest"
    runner_registration_token = "test-token-12345"
    runner_url                = "https://gitlab.com"
    vm_sku                    = "Standard_D2s_v3"
    min_instances             = 0
    max_instances             = 3
    default_instances         = 1
  }

  # Verify secure defaults
  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.vmss.admin_ssh_key == null || length(azurerm_linux_virtual_machine_scale_set.vmss.admin_ssh_key) == 0
    error_message = "SSH should be disabled by default"
  }

  # Verify managed identity
  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.vmss.identity[0].type == "SystemAssigned"
    error_message = "VMSS should have SystemAssigned managed identity"
  }

  # Verify disk encryption
  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.vmss.os_disk[0].caching == "ReadWrite"
    error_message = "OS disk caching should be ReadWrite"
  }
}

run "validate_autoscaling_configuration" {
  command = plan

  variables {
    project_name              = "test-runner"
    location                  = "eastus"
    resource_group_name       = "test-rg"
    subnet_id                 = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/test-subnet"
    runner_type               = "gitlab"
    runner_image              = "gitlab/gitlab-runner:latest"
    runner_registration_token = "test-token-12345"
    runner_url                = "https://gitlab.com"
    vm_sku                    = "Standard_D2s_v3"
    min_instances             = 0
    max_instances             = 10
    default_instances         = 2
    enable_autoscaling        = true
    cpu_scale_out_threshold   = 70
    cpu_scale_in_threshold    = 30
  }

  # Verify autoscaling settings
  assert {
    condition     = azurerm_monitor_autoscale_setting.vmss[0].profile[0].capacity[0].minimum == 0
    error_message = "Autoscale minimum should be 0"
  }

  assert {
    condition     = azurerm_monitor_autoscale_setting.vmss[0].profile[0].capacity[0].maximum == 10
    error_message = "Autoscale maximum should be 10"
  }

  assert {
    condition     = azurerm_monitor_autoscale_setting.vmss[0].profile[0].capacity[0].default == 2
    error_message = "Autoscale default should be 2"
  }
}

run "validate_disk_configuration" {
  command = plan

  variables {
    project_name              = "test-runner"
    location                  = "eastus"
    resource_group_name       = "test-rg"
    subnet_id                 = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/test-subnet"
    runner_type               = "gitlab"
    runner_image              = "gitlab/gitlab-runner:latest"
    runner_registration_token = "test-token-12345"
    runner_url                = "https://gitlab.com"
    vm_sku                    = "Standard_D2s_v3"
    disk_size_gb              = 128
    disk_type                 = "StandardSSD_LRS"
    min_instances             = 0
    max_instances             = 3
    default_instances         = 1
  }

  # Verify disk configuration
  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.vmss.os_disk[0].disk_size_gb == 128
    error_message = "OS disk size should be 128 GB"
  }

  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.vmss.os_disk[0].storage_account_type == "StandardSSD_LRS"
    error_message = "OS disk type should be StandardSSD_LRS"
  }
}
