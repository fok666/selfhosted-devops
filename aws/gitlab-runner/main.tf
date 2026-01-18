terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.27"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# =============================================================================
# Locals Configuration
# =============================================================================

locals {
  runner_name = "${var.project_name}-gitlab-runner"

  user_data = templatefile("${path.module}/user-data.sh", {
    gitlab_url          = var.gitlab_url
    gitlab_token        = var.gitlab_token
    runner_tags         = var.runner_tags
    runner_count        = var.runner_count_per_instance
    docker_image        = var.docker_image
    runner_docker_image = "fok666/gitlab-runner:latest"
    
    # Production Features - Distributed Caching
    enable_distributed_cache = var.enable_distributed_cache
    cache_s3_bucket_name     = var.cache_s3_bucket_name
    cache_s3_bucket_region   = var.cache_s3_bucket_region != "" ? var.cache_s3_bucket_region : var.aws_region
    cache_shared             = var.cache_shared
    
    # Production Features - Centralized Logging
    enable_centralized_logging = var.enable_centralized_logging
    log_group_name             = var.log_group_name
    log_retention_days         = var.log_retention_days
    
    # Production Features - Runner Monitoring
    enable_runner_monitoring = var.enable_runner_monitoring
    metrics_port             = var.metrics_port
  })
}

# =============================================================================
# GitLab Runner ASG
# =============================================================================

module "gitlab_runner_asg" {
  source = "../../modules/aws-asg"

  name_prefix         = local.runner_name
  vpc_id              = local.vpc_id
  subnet_ids          = local.subnet_ids
  instance_type       = var.instance_type
  use_spot_instances  = var.use_spot_instances
  spot_max_price      = var.spot_max_price
  spot_instance_types = var.spot_instance_types
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity
  user_data           = local.user_data
  docker_image        = var.docker_image
  root_volume_size    = var.root_volume_size
  root_volume_type    = var.root_volume_type

  # Security configuration
  enable_imdsv2               = var.enable_imdsv2
  associate_public_ip_address = var.associate_public_ip_address
  egress_cidr_blocks          = var.egress_cidr_blocks
  egress_from_port            = var.egress_from_port
  egress_to_port              = var.egress_to_port
  egress_protocol             = var.egress_protocol

  tags = var.tags
}
