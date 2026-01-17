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

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC
resource "aws_vpc" "agent" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-vpc"
    }
  )
}

# Internet Gateway
resource "aws_internet_gateway" "agent" {
  vpc_id = aws_vpc.agent.id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-igw"
    }
  )
}

# Subnets
resource "aws_subnet" "agent" {
  count = min(length(data.aws_availability_zones.available.names), 3)

  vpc_id                  = aws_vpc.agent.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-subnet-${count.index + 1}"
    }
  )
}

# Route Table
resource "aws_route_table" "agent" {
  vpc_id = aws_vpc.agent.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.agent.id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-rt"
    }
  )
}

# Route Table Association
resource "aws_route_table_association" "agent" {
  count = length(aws_subnet.agent)

  subnet_id      = aws_subnet.agent[count.index].id
  route_table_id = aws_route_table.agent.id
}

# Security Group
resource "aws_security_group" "agent" {
  name        = "${var.project_name}-agent-sg"
  description = "Security group for Azure DevOps agents"
  vpc_id      = aws_vpc.agent.id

  # Allow all outbound traffic (required for Azure DevOps)
  egress {
    from_port   = 0
    to_port     = 443
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS outbound traffic"
  }

  # Optional SSH access (disabled by default for security)
  dynamic "ingress" {
    for_each = var.enable_ssh_access && length(var.ssh_cidr_blocks) > 0 ? [1] : []
    content {
      from_port   = 0
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.ssh_cidr_blocks
      description = "SSH access from specified CIDR blocks"
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-agent-sg"
    }
  )
}

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

# Prepare user data
locals {
  user_data_rendered = templatefile("${path.module}/user-data.sh", {
    azp_url        = var.azp_url
    azp_token      = var.azp_token
    azp_pool       = var.azp_pool
    azp_agent_name = var.azp_agent_name_prefix
    agent_count    = var.agent_count_per_instance
  })
}

# Azure DevOps Agent ASG
module "agent_asg" {
  source = "../../modules/aws-asg"

  name_prefix = "${var.project_name}-azdevops-agent"
  vpc_id      = aws_vpc.agent.id
  subnet_ids  = aws_subnet.agent[*].id

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
