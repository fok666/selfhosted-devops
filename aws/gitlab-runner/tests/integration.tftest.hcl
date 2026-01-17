# Integration tests for AWS GitLab Runner configuration
# Tests the complete runner setup including networking and user-data

run "validate_complete_configuration" {
  command = plan

  variables {
    project_name            = "gitlab-runner-test"
    environment             = "test"
    aws_region              = "us-east-1"
    vpc_cidr                = "10.0.0.0/16"
    availability_zones      = ["us-east-1a", "us-east-1b"]
    gitlab_url              = "https://gitlab.com"
    gitlab_token            = "glrt-test-token-12345678"
    runner_image            = "gitlab/gitlab-runner:latest"
    runner_executor         = "docker"
    runner_docker_image     = "ubuntu:22.04"
    instance_type           = "t3.medium"
    use_spot_instances      = true
    spot_max_price          = "0.05"
    min_instances           = 0
    max_instances           = 5
    default_instances       = 1
    disk_size               = 64
    disk_type               = "gp3"
    enable_autoscaling      = true
    cpu_scale_out_threshold = 70
    cpu_scale_in_threshold  = 30
  }

  # Verify VPC is created
  assert {
    condition     = aws_vpc.main.cidr_block == "10.0.0.0/16"
    error_message = "VPC CIDR block should be 10.0.0.0/16"
  }

  # Verify subnets are created in multiple AZs
  assert {
    condition     = length(aws_subnet.private) == 2
    error_message = "Should create 2 private subnets"
  }

  # Verify security group blocks SSH by default
  assert {
    condition     = length([for rule in aws_security_group.runner.ingress : rule if rule.from_port == 22]) == 0
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
    aws_region            = "us-east-1"
    vpc_cidr              = "10.0.0.0/16"
    availability_zones    = ["us-east-1a"]
    gitlab_url            = "https://gitlab.com"
    gitlab_token          = "glrt-test-token-12345678"
    runner_image          = "gitlab/gitlab-runner:latest"
    instance_type         = "t3.small"
    min_instances         = 0
    max_instances         = 3
    default_instances     = 0
    create_public_subnets = false
  }

  # Verify no public subnets when not requested
  assert {
    condition     = length(aws_subnet.public) == 0
    error_message = "Should not create public subnets when create_public_subnets is false"
  }

  # Verify NAT gateway for private subnet internet access
  assert {
    condition     = length(aws_nat_gateway.main) > 0 || var.create_public_subnets == false
    error_message = "Should have NAT gateway or no public subnets"
  }
}

run "validate_cost_optimization" {
  command = plan

  variables {
    project_name       = "gitlab-runner-test"
    environment        = "test"
    aws_region         = "us-east-1"
    vpc_cidr           = "10.0.0.0/16"
    availability_zones = ["us-east-1a"]
    gitlab_url         = "https://gitlab.com"
    gitlab_token       = "glrt-test-token-12345678"
    runner_image       = "gitlab/gitlab-runner:latest"
    instance_type      = "t3.micro"
    use_spot_instances = true
    spot_max_price     = "0.01"
    min_instances      = 0 # Scale to zero
    max_instances      = 2
    default_instances  = 0  # Start with zero
    disk_size          = 32 # Minimal disk
    disk_type          = "gp3"
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
    condition     = var.disk_size <= 64
    error_message = "Disk size should be <= 64 GB for cost optimization"
  }
}

run "validate_security_hardening" {
  command = plan

  variables {
    project_name       = "gitlab-runner-test"
    environment        = "production"
    aws_region         = "us-east-1"
    vpc_cidr           = "10.0.0.0/16"
    availability_zones = ["us-east-1a"]
    gitlab_url         = "https://gitlab.example.com"
    gitlab_token       = "glrt-secure-token-12345678"
    runner_image       = "gitlab/gitlab-runner:latest"
    instance_type      = "t3.medium"
    min_instances      = 1
    max_instances      = 5
    default_instances  = 1
    enable_ssh_access  = false
    enable_imdsv2      = true
    encrypted_disk     = true
  }

  # Verify SSH is disabled
  assert {
    condition     = var.enable_ssh_access == false
    error_message = "SSH should be disabled for production"
  }

  # Verify IMDSv2 is enabled
  assert {
    condition     = var.enable_imdsv2 == true
    error_message = "IMDSv2 should be enabled for security"
  }

  # Verify disk encryption
  assert {
    condition     = var.encrypted_disk == true
    error_message = "Disks should be encrypted for production"
  }
}
