terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Get latest Ubuntu 22.04 LTS AMI if not specified
data "aws_ami" "ubuntu" {
  count       = var.ami_id == "" ? 1 : 0
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security group for runners
resource "aws_security_group" "runner" {
  name_prefix = "${var.name_prefix}-runner-"
  description = "Security group for CI/CD runners"
  vpc_id      = var.vpc_id

  # Allow outbound internet access (required for pulling Docker images, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  # Optional SSH access
  dynamic "ingress" {
    for_each = length(var.ingress_cidr_blocks) > 0 ? [1] : []
    content {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.ingress_cidr_blocks
      description = "SSH access"
    }
  }

  tags = merge(
    var.tags,
    {
      Name      = "${var.name_prefix}-runner-sg"
      ManagedBy = "Terraform"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# IAM role for EC2 instances
resource "aws_iam_role" "runner" {
  name_prefix = "${var.name_prefix}-runner-"

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

  tags = merge(
    var.tags,
    {
      Name      = "${var.name_prefix}-runner-role"
      ManagedBy = "Terraform"
    }
  )
}

# Attach SSM policy for Session Manager access (optional but recommended)
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.runner.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance profile
resource "aws_iam_instance_profile" "runner" {
  name_prefix = "${var.name_prefix}-runner-"
  role        = aws_iam_role.runner.name

  tags = merge(
    var.tags,
    {
      Name      = "${var.name_prefix}-runner-profile"
      ManagedBy = "Terraform"
    }
  )
}

# Launch template
resource "aws_launch_template" "runner" {
  name_prefix   = "${var.name_prefix}-runner-"
  image_id      = var.ami_id != "" ? var.ami_id : data.aws_ami.ubuntu[0].id
  instance_type = var.use_spot_instances ? null : var.instance_type
  key_name      = var.key_name != "" ? var.key_name : null
  user_data     = base64encode(var.user_data)

  # Spot instance configuration
  dynamic "instance_market_options" {
    for_each = var.use_spot_instances ? [1] : []
    content {
      market_type = "spot"
      spot_options {
        max_price          = var.spot_max_price != "" ? var.spot_max_price : null
        spot_instance_type = "one-time"
      }
    }
  }

  # Network interfaces
  network_interfaces {
    associate_public_ip_address = var.associate_public_ip_address
    security_groups             = [aws_security_group.runner.id]
    delete_on_termination       = true
  }

  # Block device mappings
  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size           = var.root_volume_size
      volume_type           = var.root_volume_type
      delete_on_termination = true
      encrypted             = true
    }
  }

  # IAM instance profile
  iam_instance_profile {
    arn = aws_iam_instance_profile.runner.arn
  }

  # Metadata options (IMDSv2)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = var.enable_imdsv2 ? "required" : "optional"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  # Monitoring
  monitoring {
    enabled = var.enable_monitoring
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.tags,
      {
        Name         = "${var.name_prefix}-runner"
        ManagedBy    = "Terraform"
        SpotInstance = var.use_spot_instances ? "true" : "false"
      }
    )
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(
      var.tags,
      {
        Name      = "${var.name_prefix}-runner-volume"
        ManagedBy = "Terraform"
      }
    )
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "runner" {
  name_prefix         = "${var.name_prefix}-runner-"
  vpc_zone_identifier = var.subnet_ids
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity

  health_check_type         = var.health_check_type
  health_check_grace_period = var.health_check_grace_period
  termination_policies      = var.termination_policies
  capacity_rebalance        = var.use_spot_instances && var.capacity_rebalance

  # Mixed instances policy for spot diversification
  dynamic "mixed_instances_policy" {
    for_each = var.use_spot_instances ? [1] : []
    content {
      launch_template {
        launch_template_specification {
          launch_template_id = aws_launch_template.runner.id
          version            = "$Latest"
        }

        dynamic "override" {
          for_each = var.spot_instance_types
          content {
            instance_type = override.value
          }
        }
      }

      instances_distribution {
        on_demand_base_capacity                  = 0
        on_demand_percentage_above_base_capacity = 0
        spot_allocation_strategy                 = "price-capacity-optimized"
        spot_instance_pools                      = length(var.spot_instance_types)
        spot_max_price                           = var.spot_max_price != "" ? var.spot_max_price : ""
      }
    }
  }

  # Use launch template directly if not using spot instances
  dynamic "launch_template" {
    for_each = var.use_spot_instances ? [] : [1]
    content {
      id      = aws_launch_template.runner.id
      version = "$Latest"
    }
  }

  # Warm pool configuration
  dynamic "warm_pool" {
    for_each = var.warm_pool_enabled ? [1] : []
    content {
      pool_state                  = "Stopped"
      min_size                    = var.warm_pool_min_size
      max_group_prepared_capacity = var.max_size
    }
  }

  # Instance refresh for rolling updates
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 300
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.name_prefix}-runner"
    propagate_at_launch = true
  }

  tag {
    key                 = "ManagedBy"
    value               = "Terraform"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }
}

# Target tracking scaling policy - CPU utilization
resource "aws_autoscaling_policy" "cpu_tracking" {
  name                   = "${var.name_prefix}-cpu-tracking"
  autoscaling_group_name = aws_autoscaling_group.runner.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

# Scale-in protection during builds (optional, can be enabled via API)
resource "aws_autoscaling_lifecycle_hook" "scale_in_protection" {
  name                   = "${var.name_prefix}-scale-in-protection"
  autoscaling_group_name = aws_autoscaling_group.runner.name
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_TERMINATING"
  default_result         = "CONTINUE"
  heartbeat_timeout      = 300
}
