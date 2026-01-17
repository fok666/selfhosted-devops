# =============================================================================
# Network Infrastructure Configuration
# =============================================================================
# This file contains all network-related resources for GitLab runners.
# Supports both creating new network infrastructure and using existing resources.

# =============================================================================
# Data Sources
# =============================================================================

# Existing VPC (when using existing infrastructure)
data "aws_vpc" "existing" {
  count = var.create_vpc ? 0 : 1
  id    = var.existing_vpc_id
}

# Default VPC (fallback if neither creating nor specifying existing VPC)
data "aws_vpc" "default" {
  count   = !var.create_vpc && var.existing_vpc_id == "" ? 1 : 0
  default = true
}

# Existing Subnets (when using existing infrastructure)
data "aws_subnet" "existing" {
  count = var.create_subnets ? 0 : length(var.existing_subnet_ids)
  id    = var.existing_subnet_ids[count.index]
}

# Default Subnets (fallback)
data "aws_subnets" "default" {
  count = !var.create_subnets && length(var.existing_subnet_ids) == 0 ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }
}

# Existing Security Group (when using existing infrastructure)
data "aws_security_group" "existing" {
  count = var.create_security_group ? 0 : 1
  id    = var.existing_security_group_id
}

# Existing Internet Gateway (when using existing infrastructure with new VPC)
data "aws_internet_gateway" "existing" {
  count = var.create_vpc && !var.create_internet_gateway && var.existing_internet_gateway_id != "" ? 1 : 0
  filter {
    name   = "internet-gateway-id"
    values = [var.existing_internet_gateway_id]
  }
}

# =============================================================================
# VPC (created only if create_vpc = true)
# =============================================================================

resource "aws_vpc" "runner" {
  count = var.create_vpc ? 1 : 0

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

# =============================================================================
# VPC Flow Logs (created only if create_vpc = true and enable_vpc_flow_logs = true)
# =============================================================================

# CloudWatch Log Group for VPC Flow Logs
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  count = var.create_vpc && var.enable_vpc_flow_logs ? 1 : 0

  name              = "/aws/vpc/flowlogs/${var.project_name}"
  retention_in_days = var.vpc_flow_logs_retention_days

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-vpc-flow-logs"
    }
  )
}

# IAM Role for VPC Flow Logs
resource "aws_iam_role" "vpc_flow_logs" {
  count = var.create_vpc && var.enable_vpc_flow_logs ? 1 : 0

  name = "${var.project_name}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSVPCFlowLogsAssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-vpc-flow-logs-role"
    }
  )
}

# IAM Policy for VPC Flow Logs
resource "aws_iam_role_policy" "vpc_flow_logs" {
  count = var.create_vpc && var.enable_vpc_flow_logs ? 1 : 0

  name = "${var.project_name}-vpc-flow-logs-policy"
  role = aws_iam_role.vpc_flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

# VPC Flow Logs
resource "aws_flow_log" "vpc" {
  count = var.create_vpc && var.enable_vpc_flow_logs ? 1 : 0

  vpc_id          = aws_vpc.runner[0].id
  traffic_type    = var.vpc_flow_logs_traffic_type
  iam_role_arn    = aws_iam_role.vpc_flow_logs[0].arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs[0].arn

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-vpc-flow-logs"
    }
  )
}

# =============================================================================
# Internet Gateway (created only if create_internet_gateway = true)
# =============================================================================

resource "aws_internet_gateway" "runner" {
  count = var.create_internet_gateway ? 1 : 0

  vpc_id = local.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-igw"
    }
  )
}

# =============================================================================
# Subnets (created only if create_subnets = true)
# =============================================================================

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "runner" {
  count = var.create_subnets ? min(length(data.aws_availability_zones.available.names), var.subnet_count) : 0

  vpc_id                  = local.vpc_id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-subnet-${count.index + 1}"
    }
  )
}

# =============================================================================
# Route Table (created only if create_route_table = true)
# =============================================================================

resource "aws_route_table" "runner" {
  count = var.create_route_table ? 1 : 0

  vpc_id = local.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = local.internet_gateway_id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-rt"
    }
  )
}

# =============================================================================
# Route Table Associations (created only if create_route_table = true)
# =============================================================================

resource "aws_route_table_association" "runner" {
  count = var.create_route_table && var.create_subnets ? length(aws_subnet.runner) : 0

  subnet_id      = aws_subnet.runner[count.index].id
  route_table_id = aws_route_table.runner[0].id
}

# =============================================================================
# Security Group (created only if create_security_group = true)
# =============================================================================

resource "aws_security_group" "runner" {
  count = var.create_security_group ? 1 : 0

  name        = "${var.project_name}-runner-sg"
  description = "Security group for GitLab runners"
  vpc_id      = local.vpc_id

  # Allow outbound traffic
  egress {
    from_port   = var.egress_from_port
    to_port     = var.egress_to_port
    protocol    = var.egress_protocol
    cidr_blocks = var.egress_cidr_blocks
    description = "Allow outbound traffic"
  }

  # Optional SSH access (disabled by default for security)
  dynamic "ingress" {
    for_each = var.enable_ssh_access && length(var.ssh_cidr_blocks) > 0 ? [1] : []
    content {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.ssh_cidr_blocks
      description = "SSH access from specified CIDR blocks"
    }
  }

  # Additional custom security group rules
  dynamic "ingress" {
    for_each = var.additional_ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
    }
  }

  dynamic "egress" {
    for_each = var.additional_egress_rules
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
      description = egress.value.description
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-runner-sg"
    }
  )
}

# =============================================================================
# Local Values - Network Resource IDs
# =============================================================================

locals {
  # VPC ID - priority: created > existing_vpc_id > vpc_id (deprecated) > default
  vpc_id = var.create_vpc ? aws_vpc.runner[0].id : (
    var.existing_vpc_id != "" ? var.existing_vpc_id : (
      var.vpc_id != "" ? var.vpc_id : data.aws_vpc.default[0].id
    )
  )

  # Internet Gateway ID
  internet_gateway_id = var.create_internet_gateway ? aws_internet_gateway.runner[0].id : (
    var.existing_internet_gateway_id != "" ? var.existing_internet_gateway_id : null
  )

  # Subnet IDs - priority: created > existing_subnet_ids > subnet_ids (deprecated) > default
  subnet_ids = var.create_subnets ? aws_subnet.runner[*].id : (
    length(var.existing_subnet_ids) > 0 ? var.existing_subnet_ids : (
      length(var.subnet_ids) > 0 ? var.subnet_ids : data.aws_subnets.default[0].ids
    )
  )

  # Security Group ID
  security_group_id = var.create_security_group ? aws_security_group.runner[0].id : var.existing_security_group_id
}
