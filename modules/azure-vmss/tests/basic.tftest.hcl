# Basic validation tests for Azure VMSS module
# Tests variable validation, required inputs, and basic configuration

mock_provider "azurerm" {}

run "validate_required_inputs" {
  command = plan

  variables {
    vmss_name           = "test-runner-vmss"
    location            = "eastus"
    resource_group_name = "test-rg"
    subnet_id           = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/test-subnet"
    ssh_public_key      = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDH+Vf2zYPMMosigz84uLIm5Cg9qx7tBmJMCQiGOJiVdEtoHtHHtDtlLbnL0vCJ5JsPUCeWYtFYXdplNtv0JDdnRSA/J8wFZhZbMpboKOMsfbHU3GVfhcWGGfp6oYw9i3RG/VE3SmZGuwDl95jKHQRKANlOSsfcLibx8s1vEf/oOXvfNHoTSCK20rKzhOt+U+MTKVy8gr8Xu0cCOPLKOTcBpg8qEOY9Ffnety9wo3T2Iu0HJn2QWGy3awqULcYKQpR+pqgekejvdQY/GeoS4/oHR2KSY61WFhFSUbFOFUi9iaggCUmXjbefpKS9QuB77w4PScn0IMJcqQo/PGsVrRe3 test"
    custom_data         = base64encode("#cloud-config\npackages:\n  - docker")
    docker_image        = "ubuntu:22.04"
    vm_sku              = "Standard_D2s_v3"
    use_spot_instances  = false
    min_instances       = 0
    max_instances       = 5
    default_instances   = 1
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
    condition     = azurerm_linux_virtual_machine_scale_set.vmss.priority == "Regular"
    error_message = "VMSS should use Regular priority when spot is disabled"
  }
}

run "validate_spot_configuration" {
  command = plan

  variables {
    vmss_name           = "test-runner-vmss"
    location            = "eastus"
    resource_group_name = "test-rg"
    subnet_id           = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/test-subnet"
    ssh_public_key      = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDH+Vf2zYPMMosigz84uLIm5Cg9qx7tBmJMCQiGOJiVdEtoHtHHtDtlLbnL0vCJ5JsPUCeWYtFYXdplNtv0JDdnRSA/J8wFZhZbMpboKOMsfbHU3GVfhcWGGfp6oYw9i3RG/VE3SmZGuwDl95jKHQRKANlOSsfcLibx8s1vEf/oOXvfNHoTSCK20rKzhOt+U+MTKVy8gr8Xu0cCOPLKOTcBpg8qEOY9Ffnety9wo3T2Iu0HJn2QWGy3awqULcYKQpR+pqgekejvdQY/GeoS4/oHR2KSY61WFhFSUbFOFUi9iaggCUmXjbefpKS9QuB77w4PScn0IMJcqQo/PGsVrRe3 test"
    custom_data         = base64encode("#cloud-config\npackages:\n  - docker")
    docker_image        = "ubuntu:22.04"
    vm_sku              = "Standard_D2s_v3"
    use_spot_instances  = true
    spot_max_price      = 0.05
    min_instances       = 0
    max_instances       = 3
    default_instances   = 1
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
    vmss_name           = "test-runner-vmss"
    location            = "eastus"
    resource_group_name = "test-rg"
    subnet_id           = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/test-subnet"
    ssh_public_key      = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDH+Vf2zYPMMosigz84uLIm5Cg9qx7tBmJMCQiGOJiVdEtoHtHHtDtlLbnL0vCJ5JsPUCeWYtFYXdplNtv0JDdnRSA/J8wFZhZbMpboKOMsfbHU3GVfhcWGGfp6oYw9i3RG/VE3SmZGuwDl95jKHQRKANlOSsfcLibx8s1vEf/oOXvfNHoTSCK20rKzhOt+U+MTKVy8gr8Xu0cCOPLKOTcBpg8qEOY9Ffnety9wo3T2Iu0HJn2QWGy3awqULcYKQpR+pqgekejvdQY/GeoS4/oHR2KSY61WFhFSUbFOFUi9iaggCUmXjbefpKS9QuB77w4PScn0IMJcqQo/PGsVrRe3 test"
    custom_data         = base64encode("#cloud-config\npackages:\n  - docker")
    docker_image        = "ubuntu:22.04"
    vm_sku              = "Standard_D2s_v3"
    min_instances       = 0
    max_instances       = 3
    default_instances   = 1
  }

  # Verify secure defaults
  assert {
    condition     = length(azurerm_linux_virtual_machine_scale_set.vmss.admin_ssh_key) > 0
    error_message = "SSH key should be configured"
  }

  # Verify managed identity is configured
  assert {
    condition     = length(azurerm_linux_virtual_machine_scale_set.vmss.identity) > 0 && azurerm_linux_virtual_machine_scale_set.vmss.identity[0].type == "SystemAssigned"
    error_message = "Module should configure SystemAssigned identity"
  }

  # Verify disk configuration
  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.vmss.os_disk[0].caching == "ReadWrite"
    error_message = "OS disk caching should be ReadWrite"
  }
}

run "validate_instance_configuration" {
  command = plan

  variables {
    vmss_name                 = "test-runner-vmss"
    location                  = "eastus"
    resource_group_name       = "test-rg"
    subnet_id                 = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/test-subnet"
    ssh_public_key            = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDH+Vf2zYPMMosigz84uLIm5Cg9qx7tBmJMCQiGOJiVdEtoHtHHtDtlLbnL0vCJ5JsPUCeWYtFYXdplNtv0JDdnRSA/J8wFZhZbMpboKOMsfbHU3GVfhcWGGfp6oYw9i3RG/VE3SmZGuwDl95jKHQRKANlOSsfcLibx8s1vEf/oOXvfNHoTSCK20rKzhOt+U+MTKVy8gr8Xu0cCOPLKOTcBpg8qEOY9Ffnety9wo3T2Iu0HJn2QWGy3awqULcYKQpR+pqgekejvdQY/GeoS4/oHR2KSY61WFhFSUbFOFUi9iaggCUmXjbefpKS9QuB77w4PScn0IMJcqQo/PGsVrRe3 test"
    custom_data               = base64encode("#cloud-config\npackages:\n  - docker")
    docker_image              = "ubuntu:22.04"
    vm_sku                    = "Standard_D2s_v3"
    min_instances             = 0
    max_instances             = 10
    default_instances         = 2
  }

  # Verify instance configuration
  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.vmss.instances == 2
    error_message = "VMSS instances should be 2"
  }

  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.vmss.sku == "Standard_D2s_v3"
    error_message = "VMSS SKU should be Standard_D2s_v3"
  }
}

run "validate_disk_configuration" {
  command = plan

  variables {
    vmss_name           = "test-runner-vmss"
    location            = "eastus"
    resource_group_name = "test-rg"
    subnet_id           = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/test-subnet"
    ssh_public_key      = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDH+Vf2zYPMMosigz84uLIm5Cg9qx7tBmJMCQiGOJiVdEtoHtHHtDtlLbnL0vCJ5JsPUCeWYtFYXdplNtv0JDdnRSA/J8wFZhZbMpboKOMsfbHU3GVfhcWGGfp6oYw9i3RG/VE3SmZGuwDl95jKHQRKANlOSsfcLibx8s1vEf/oOXvfNHoTSCK20rKzhOt+U+MTKVy8gr8Xu0cCOPLKOTcBpg8qEOY9Ffnety9wo3T2Iu0HJn2QWGy3awqULcYKQpR+pqgekejvdQY/GeoS4/oHR2KSY61WFhFSUbFOFUi9iaggCUmXjbefpKS9QuB77w4PScn0IMJcqQo/PGsVrRe3 test"
    custom_data         = base64encode("#cloud-config\npackages:\n  - docker")
    docker_image        = "ubuntu:22.04"
    vm_sku              = "Standard_D2s_v3"
    os_disk_size_gb     = 128
    os_disk_type        = "StandardSSD_LRS"
    min_instances       = 0
    max_instances       = 3
    default_instances   = 1
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
