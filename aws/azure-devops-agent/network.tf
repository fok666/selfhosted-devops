# =============================================================================
# Network Infrastructure Configuration
# =============================================================================
# This file contains all network-related resources for Azure DevOps agents.
# Supports both creating new network infrastructure and using existing resources.

# =============================================================================
# Data Sources
# =============================================================================

data "aws_availability_zones" "available" {
  state = "available"
}

# Existing VPC (when using existing infrastructure)
data "aws_vpc" "existing" {
  count = var.create_vpc ? 0 : 1
  id    = var.existing_vpc_id
}

# Existing Subnets (when using existing infrastructure)
data "aws_subnet" "existing" {
  count = var.create_subnets ? 0 : length(var.existing_subnet_ids)
  id    = var.existing_subnet_ids[count.index]
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

resource "aws_vpc" "agent" {
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
# Internet Gateway (created only if create_internet_gateway = true)
# =============================================================================

resource "aws_internet_gateway" "agent" {
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

resource "aws_subnet" "agent" {
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

resource "aws_route_table" "agent" {
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

resource "aws_route_table_association" "agent" {
  count = var.create_route_table && var.create_subnets ? length(aws_subnet.agent) : 0

  subnet_id      = aws_subnet.agent[count.index].id
  route_table_id = aws_route_table.agent[0].id
}

# =============================================================================
# Security Group (created only if create_security_group = true)
# =============================================================================

resource "aws_security_group" "agent" {
  count = var.create_security_group ? 1 : 0

  name        = "${var.project_name}-agent-sg"
  description = "Security group for Azure DevOps agents"
  vpc_id      = local.vpc_id

  # Allow outbound traffic (configurable, defaults to all traffic for Azure DevOps connectivity)
  egress {
    from_port   = var.egress_from_port
    to_port     = var.egress_to_port
    protocol    = var.egress_protocol
    cidr_blocks = var.egress_cidr_blocks
    description = "Allow outbound traffic to specified CIDR blocks"
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
      Name = "${var.project_name}-agent-sg"
    }
  )
}

# =============================================================================
# Local Values - Network Resource IDs
# =============================================================================

locals {
  # VPC ID
  vpc_id = var.create_vpc ? aws_vpc.agent[0].id : var.existing_vpc_id

  # Internet Gateway ID
  internet_gateway_id = var.create_internet_gateway ? aws_internet_gateway.agent[0].id : (
    var.existing_internet_gateway_id != "" ? var.existing_internet_gateway_id : null
  )

  # Subnet IDs
  subnet_ids = var.create_subnets ? aws_subnet.agent[*].id : var.existing_subnet_ids

  # Security Group ID
  security_group_id = var.create_security_group ? aws_security_group.agent[0].id : var.existing_security_group_id
}
