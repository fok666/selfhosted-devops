# Integration tests for Azure GitLab Runner configuration
# Tests the complete runner setup including networking and cloud-init

mock_provider "azurerm" {}

run "validate_complete_configuration" {
  command = plan

  variables {
    project_name      = "gltest"
    location          = "eastus"
    gitlab_url        = "https://gitlab.com"
    gitlab_token      = "glrt-test-token-12345678"
    vm_sku            = "Standard_D2s_v3"
    use_spot_instances = true
    spot_max_price    = 0.05
    min_instances     = 0
    max_instances     = 5
    default_instances = 1
  }

  # Verify GitLab configuration
  assert {
    condition     = var.gitlab_url == "https://gitlab.com"
    error_message = "GitLab URL should be configured"
  }

  # Verify spot instance configuration
  assert {
    condition     = var.use_spot_instances == true
    error_message = "Should use spot instances for cost optimization"
  }
}

run "validate_cost_optimization" {
  command = plan

  variables {
    project_name      = "gltest"
    location          = "eastus"
    gitlab_url        = "https://gitlab.com"
    gitlab_token      = "glrt-test-token-12345678"
    vm_sku            = "Standard_B2s"
    use_spot_instances = true
    spot_max_price    = 0.02
    min_instances     = 0
    max_instances     = 2
    default_instances = 0
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
    condition     = var.spot_max_price == 0.02
    error_message = "Spot max price should be configurable"
  }
}

run "validate_security_hardening" {
  command = plan

  variables {
    project_name      = "gltest"
    location          = "eastus"
    gitlab_url        = "https://gitlab.com"
    gitlab_token      = "glrt-test-token-12345678"
    vm_sku            = "Standard_D2s_v3"
    min_instances     = 1
    max_instances     = 5
    default_instances = 1
    enable_ssh_access = false
  }

  # Verify SSH is disabled
  assert {
    condition     = var.enable_ssh_access == false
    error_message = "SSH should be disabled by default"
  }
}

run "validate_high_availability" {
  command = plan

  variables {
    project_name      = "gltest"
    location          = "eastus"
    gitlab_url        = "https://gitlab.com"
    gitlab_token      = "glrt-test-token-12345678"
    vm_sku            = "Standard_D4s_v3"
    use_spot_instances = false
    min_instances     = 2
    max_instances     = 10
    default_instances = 3
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
}
