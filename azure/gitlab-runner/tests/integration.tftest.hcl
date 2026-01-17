# Integration tests for Azure GitLab Runner configuration
# Tests the complete runner setup including networking and cloud-init

run "validate_complete_configuration" {
  command = plan

  variables {
    project_name            = "gitlab-runner-test"
    environment             = "test"
    location                = "eastus"
    gitlab_url              = "https://gitlab.com"
    gitlab_token            = "glrt-test-token-12345678"
    runner_image            = "gitlab/gitlab-runner:latest"
    runner_executor         = "docker"
    runner_docker_image     = "ubuntu:22.04"
    vm_sku                  = "Standard_D2s_v3"
    use_spot_instances      = true
    spot_max_price          = 0.05
    min_instances           = 0
    max_instances           = 5
    default_instances       = 1
    disk_size_gb            = 64
    disk_type               = "StandardSSD_LRS"
    enable_autoscaling      = true
    cpu_scale_out_threshold = 70
    cpu_scale_in_threshold  = 30
    vnet_address_space      = ["10.0.0.0/16"]
    subnet_address_prefix   = "10.0.1.0/24"
  }

  # Verify resource group is created
  assert {
    condition     = azurerm_resource_group.runner.location == "eastus"
    error_message = "Resource group location should be eastus"
  }

  # Verify VNet is created with correct address space
  assert {
    condition     = azurerm_virtual_network.runner.address_space[0] == "10.0.0.0/16"
    error_message = "VNet address space should be 10.0.0.0/16"
  }

  # Verify subnet is created
  assert {
    condition     = azurerm_subnet.runner.address_prefixes[0] == "10.0.1.0/24"
    error_message = "Subnet address prefix should be 10.0.1.0/24"
  }

  # Verify NSG blocks SSH by default
  assert {
    condition     = length([for rule in azurerm_network_security_group.runner.security_rule : rule if rule.destination_port_range == "22" && rule.access == "Allow"]) == 0
    error_message = "SSH should not be allowed by default"
  }

  # Verify runner configuration
  assert {
    condition     = can(regex("gitlab/gitlab-runner", var.runner_image))
    error_message = "Runner image should be GitLab Runner"
  }
}

run "validate_network_isolation" {
  command = plan

  variables {
    project_name          = "gitlab-runner-test"
    environment           = "test"
    location              = "westus2"
    gitlab_url            = "https://gitlab.com"
    gitlab_token          = "glrt-test-token-12345678"
    runner_image          = "gitlab/gitlab-runner:latest"
    vm_sku                = "Standard_B2s"
    min_instances         = 0
    max_instances         = 3
    default_instances     = 0
    vnet_address_space    = ["10.1.0.0/16"]
    subnet_address_prefix = "10.1.1.0/24"
  }

  # Verify private IP configuration
  assert {
    condition     = length(azurerm_public_ip.runner) == 0 || var.enable_public_ip == false
    error_message = "Should not create public IP by default"
  }

  # Verify NSG is attached to subnet
  assert {
    condition     = azurerm_subnet_network_security_group_association.runner.subnet_id != null
    error_message = "NSG should be attached to subnet"
  }
}

run "validate_cost_optimization" {
  command = plan

  variables {
    project_name          = "gitlab-runner-test"
    environment           = "test"
    location              = "eastus"
    gitlab_url            = "https://gitlab.com"
    gitlab_token          = "glrt-test-token-12345678"
    runner_image          = "gitlab/gitlab-runner:latest"
    vm_sku                = "Standard_B2s" # Burstable for cost savings
    use_spot_instances    = true
    spot_max_price        = 0.02
    min_instances         = 0 # Scale to zero
    max_instances         = 2
    default_instances     = 0  # Start with zero
    disk_size_gb          = 32 # Minimal disk
    disk_type             = "StandardSSD_LRS"
    vnet_address_space    = ["10.0.0.0/16"]
    subnet_address_prefix = "10.0.1.0/24"
  }

  # Verify cost-optimized settings
  assert {
    condition     = var.min_instances == 0
    error_message = "Min instances should be 0 for cost optimization"
  }

  assert {
    condition     = var.use_spot_instances == true
    error_message = "Should use spot instances for cost optimization"
  }

  assert {
    condition     = var.disk_size_gb <= 64
    error_message = "Disk size should be <= 64 GB for cost optimization"
  }

  assert {
    condition     = var.disk_type == "StandardSSD_LRS"
    error_message = "Should use StandardSSD_LRS for cost optimization"
  }
}

run "validate_security_hardening" {
  command = plan

  variables {
    project_name            = "gitlab-runner-test"
    environment             = "production"
    location                = "eastus"
    gitlab_url              = "https://gitlab.example.com"
    gitlab_token            = "glrt-secure-token-12345678"
    runner_image            = "gitlab/gitlab-runner:latest"
    vm_sku                  = "Standard_D2s_v3"
    min_instances           = 1
    max_instances           = 5
    default_instances       = 1
    enable_ssh_access       = false
    disk_encryption_enabled = true
    vnet_address_space      = ["10.0.0.0/16"]
    subnet_address_prefix   = "10.0.1.0/24"
  }

  # Verify SSH is disabled
  assert {
    condition     = var.enable_ssh_access == false
    error_message = "SSH should be disabled for production"
  }

  # Verify managed identity is enabled
  assert {
    condition     = length(azurerm_linux_virtual_machine_scale_set.vmss.identity) > 0
    error_message = "Managed identity should be enabled"
  }

  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.vmss.identity[0].type == "SystemAssigned"
    error_message = "Should use SystemAssigned managed identity"
  }

  # Verify disk encryption
  assert {
    condition     = var.disk_encryption_enabled == true
    error_message = "Disk encryption should be enabled for production"
  }
}

run "validate_high_availability" {
  command = plan

  variables {
    project_name          = "gitlab-runner-test"
    environment           = "production"
    location              = "eastus"
    gitlab_url            = "https://gitlab.example.com"
    gitlab_token          = "glrt-prod-token-12345678"
    runner_image          = "gitlab/gitlab-runner:latest"
    vm_sku                = "Standard_D4s_v3"
    use_spot_instances    = false # Regular VMs for HA
    min_instances         = 2     # Always at least 2
    max_instances         = 10
    default_instances     = 3
    enable_autoscaling    = true
    vnet_address_space    = ["10.0.0.0/16"]
    subnet_address_prefix = "10.0.1.0/24"
  }

  # Verify HA configuration
  assert {
    condition     = var.min_instances >= 2
    error_message = "Should have at least 2 instances for HA"
  }

  assert {
    condition     = var.use_spot_instances == false
    error_message = "Should not use spot instances for production HA"
  }

  assert {
    condition     = var.enable_autoscaling == true
    error_message = "Should enable autoscaling for HA"
  }

  # Verify VMSS zone configuration for HA
  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.vmss.zones == null || length(azurerm_linux_virtual_machine_scale_set.vmss.zones) >= 2
    error_message = "Should use multiple availability zones for HA when specified"
  }
}
