# =============================================================================
# DEVELOPMENT CONFIGURATION - AWS GitLab Runner
# =============================================================================
# Best for: Dev/test environments, small-medium teams, cost-conscious
# Estimated cost: $35-70/month
#
# Features:
# ✓ Maintains 1 baseline instance (fast response)
# ✓ Spot instances for cost savings
# ✓ Balanced instance size (2 vCPU, 8GB RAM)
# ✓ 100GB disk for Docker caching
# ✓ Handles 5-10 concurrent jobs
#
# Copy this file to your deployment directory:
#   cp examples/development/aws-gitlab.tfvars aws/gitlab-runner/terraform.tfvars
# =============================================================================

# -----------------------------------------------------------------------------
# REQUIRED: You MUST customize these values
# -----------------------------------------------------------------------------
project_name = "dev-gitlab-runner"  # Change to your project name
gitlab_url   = "https://gitlab.com" # Or your GitLab instance URL
gitlab_token = "glrt-xxxxx"         # Get from GitLab: Settings > CI/CD > Runners

# -----------------------------------------------------------------------------
# AWS Configuration
# -----------------------------------------------------------------------------
region = "us-east-1" # Change to your preferred region

# -----------------------------------------------------------------------------
# Runner Configuration
# -----------------------------------------------------------------------------
runner_tags = "docker,linux,aws,development" # Tags for job matching

# -----------------------------------------------------------------------------
# Compute Configuration - Balanced for development
# -----------------------------------------------------------------------------
instance_type      = "t3.large" # 2 vCPU, 8GB RAM (~$60/mo on-demand, ~$18/mo spot)
use_spot_instances = true       # Use spot for cost savings
spot_max_price     = ""         # Empty = pay up to on-demand

# -----------------------------------------------------------------------------
# Autoscaling - Maintain 1 baseline instance
# -----------------------------------------------------------------------------
min_size         = 1 # Always 1 instance available
max_size         = 5 # Scale up to 5 for peak load
desired_capacity = 1 # Start with 1 instance

# -----------------------------------------------------------------------------
# Runner Instances per VM
# -----------------------------------------------------------------------------
runner_count_per_instance = 0 # 0 = auto (will use 2 for 2 vCPU)

# -----------------------------------------------------------------------------
# Docker Configuration
# -----------------------------------------------------------------------------
docker_image = "fok666/gitlab-runner:latest" # Pre-configured GitLab Runner

# -----------------------------------------------------------------------------
# Storage - Good space for Docker caching
# -----------------------------------------------------------------------------
root_volume_size = 100   # 100GB for good caching
root_volume_type = "gp3" # General Purpose SSD

# -----------------------------------------------------------------------------
# Network Configuration - Use defaults
# -----------------------------------------------------------------------------
# vpc_cidr           = "10.0.0.0/16"               # Uncomment to customize
# public_subnet_cidr = "10.0.1.0/24"               # Uncomment to customize

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------
tags = {
  Environment = "Development"
  Application = "GitLab-Runner"
  ManagedBy   = "Terraform"
  CostCenter  = "Development-CI-CD"
}
