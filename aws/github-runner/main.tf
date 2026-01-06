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

locals {
  runner_name = "${var.project_name}-github-runner"
  
  user_data = templatefile("${path.module}/user-data.sh", {
    github_url          = var.github_url
    github_token        = var.github_token
    runner_labels       = var.runner_labels
    runner_count        = var.runner_count_per_instance
    docker_image        = var.docker_image
    runner_docker_image = "fok666/github-runner:latest"
  })
}

# Get default VPC if not specified
data "aws_vpc" "default" {
  count   = var.vpc_id == "" ? 1 : 0
  default = true
}

# Get default subnets if not specified
data "aws_subnets" "default" {
  count = length(var.subnet_ids) == 0 ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [var.vpc_id != "" ? var.vpc_id : data.aws_vpc.default[0].id]
  }
}

# Auto Scaling Group using shared module
module "github_runner_asg" {
  source = "../../modules/aws-asg"

  name_prefix         = local.runner_name
  vpc_id              = var.vpc_id != "" ? var.vpc_id : data.aws_vpc.default[0].id
  subnet_ids          = length(var.subnet_ids) > 0 ? var.subnet_ids : data.aws_subnets.default[0].ids
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
  tags                = var.tags
}
