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

  default_tags {
    tags = merge(
      var.tags,
      {
        Environment = "production"
        ManagedBy   = "terraform"
        Purpose     = "azure-devops-agent"
      }
    )
  }
}

# =============================================================================
# IAM Configuration
# =============================================================================

# IAM Role for EC2 instances
resource "aws_iam_role" "agent" {
  name = "${var.project_name}-agent-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Role Policy - SSM for Session Manager
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.agent.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM Role Policy - CloudWatch Logs
resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.agent.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "agent" {
  name = "${var.project_name}-agent-profile"
  role = aws_iam_role.agent.name

  tags = var.tags
}

# =============================================================================
# User Data Configuration
# =============================================================================

locals {
  user_data_rendered = templatefile("${path.module}/user-data.sh", {
    azp_url        = var.azp_url
    azp_token      = var.azp_token
    azp_pool       = var.azp_pool
    azp_agent_name = var.azp_agent_name_prefix
    agent_count    = var.agent_count_per_instance
  })
}

# =============================================================================
# Azure DevOps Agent ASG
# =============================================================================

module "agent_asg" {
  source = "../../modules/aws-asg"

  name_prefix = "${var.project_name}-azdevops-agent"
  vpc_id      = local.vpc_id
  subnet_ids  = local.subnet_ids

  user_data    = base64encode(local.user_data_rendered)
  docker_image = "fok666/azuredevops:latest"

  instance_type       = var.instance_types[0]
  spot_instance_types = var.instance_types
  use_spot_instances  = var.use_spot_instances
  spot_max_price      = var.spot_max_price

  min_size         = var.min_instances
  max_size         = var.max_instances
  desired_capacity = var.default_instances

  enable_monitoring = true

  # Security configuration
  enable_imdsv2               = var.enable_imdsv2
  associate_public_ip_address = var.associate_public_ip_address

  tags = merge(
    var.tags,
    {
      Agent = "azure-devops"
      Pool  = var.azp_pool
    }
  )
}
