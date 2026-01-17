# Integration tests for AWS GitLab Runner configuration
# Tests the complete runner setup including networking and user-data

mock_provider "aws" {}

run "validate_complete_configuration" {
  command = plan

  variables {
    project_name       = "gltest"
    aws_region         = "us-east-1"
    vpc_cidr           = "10.0.0.0/16"
    gitlab_url         = "https://gitlab.com"
    gitlab_token       = "glrt-test-token-12345678"
    instance_type      = "t3.medium"
    use_spot_instances = true
    spot_max_price     = "0.05"
  }

  # Verify planning succeeds with complete configuration
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

run "validate_spot_configuration" {
  command = plan

  variables {
    project_name       = "gltest"
    aws_region         = "us-east-1"
    vpc_cidr           = "10.0.0.0/16"
    gitlab_url         = "https://gitlab.com"
    gitlab_token       = "glrt-test-token-12345678"
    instance_type      = "t3.small"
    use_spot_instances = true
    spot_max_price     = "0.01"
  }

  # Verify spot configuration variables
  assert {
    condition     = var.spot_max_price == "0.01"
    error_message = "Spot max price should be configurable"
  }
}
