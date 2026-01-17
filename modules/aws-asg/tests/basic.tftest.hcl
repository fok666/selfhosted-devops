# Basic validation tests for AWS ASG module
# Tests variable validation, required inputs, and basic configuration

# Provider configuration for testing (uses environment variables or mock credentials)
provider "aws" {
  region                      = "us-east-1"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  # Use fake credentials for testing
  access_key = "test"
  secret_key = "test"
}

run "validate_required_inputs" {
  command = plan

  variables {
    name_prefix      = "test-runner"
    vpc_id           = "vpc-12345678"
    subnet_ids       = ["subnet-12345678", "subnet-87654321"]
    user_data        = "#!/bin/bash\necho 'test'"
    docker_image     = "gitlab/gitlab-runner:latest"
    instance_type    = "t3.medium"
    ami_id           = "ami-test123456" # Provide AMI to skip data source
    min_size         = 0
    max_size         = 5
    desired_capacity = 1
  }

  # Verify ASG is created with correct configuration
  assert {
    condition     = aws_autoscaling_group.runner.min_size == 0
    error_message = "ASG min_size should be 0"
  }

  assert {
    condition     = aws_autoscaling_group.runner.max_size == 5
    error_message = "ASG max_size should be 5"
  }

  assert {
    condition     = aws_autoscaling_group.runner.desired_capacity == 1
    error_message = "ASG desired_capacity should be 1"
  }
}

run "validate_spot_configuration" {
  command = plan

  variables {
    name_prefix        = "test-runner"
    vpc_id             = "vpc-12345678"
    subnet_ids         = ["subnet-12345678"]
    user_data          = "#!/bin/bash\necho 'test'"
    docker_image       = "gitlab/gitlab-runner:latest"
    instance_type      = "t3.medium"
    ami_id             = "ami-test123456"
    use_spot_instances = true
    spot_max_price     = "0.05"
    min_size           = 0
    max_size           = 3
    desired_capacity   = 1
  }

  # Verify spot configuration exists
  assert {
    condition     = length(aws_launch_template.runner.instance_market_options) > 0
    error_message = "Launch template should have instance market options for spot"
  }
}

run "validate_security_defaults" {
  command = plan

  variables {
    name_prefix      = "test-runner"
    vpc_id           = "vpc-12345678"
    subnet_ids       = ["subnet-12345678"]
    user_data        = "#!/bin/bash\necho 'test'"
    docker_image     = "gitlab/gitlab-runner:latest"
    instance_type    = "t3.medium"
    ami_id           = "ami-test123456"
    min_size         = 0
    max_size         = 3
    desired_capacity = 1
  }

  # Verify secure defaults
  assert {
    condition     = aws_launch_template.runner.metadata_options[0].http_tokens == "required"
    error_message = "IMDSv2 should be required"
  }

  assert {
    condition     = aws_launch_template.runner.metadata_options[0].http_put_response_hop_limit == 1
    error_message = "IMDS hop limit should be 1"
  }

  # Verify no public IP by default
  assert {
    condition     = var.associate_public_ip_address == false
    error_message = "Public IP should not be assigned by default"
  }

  # Verify egress allows internet access for CI/CD
  assert {
    condition     = contains(var.egress_cidr_blocks, "0.0.0.0/0")
    error_message = "Egress should allow internet access for CI/CD operations"
  }
}

run "validate_disk_configuration" {
  command = plan

  variables {
    name_prefix      = "test-runner"
    vpc_id           = "vpc-12345678"
    subnet_ids       = ["subnet-12345678"]
    user_data        = "#!/bin/bash\necho 'test'"
    docker_image     = "gitlab/gitlab-runner:latest"
    instance_type    = "t3.medium"
    ami_id           = "ami-test123456"
    root_volume_size = 128
    root_volume_type = "gp3"
    min_size         = 0
    max_size         = 3
    desired_capacity = 1
  }

  # Verify disk configuration
  assert {
    condition     = aws_launch_template.runner.block_device_mappings[0].ebs[0].volume_size == 128
    error_message = "Root volume size should be 128 GB"
  }

  assert {
    condition     = aws_launch_template.runner.block_device_mappings[0].ebs[0].volume_type == "gp3"
    error_message = "Root volume type should be gp3"
  }
}
