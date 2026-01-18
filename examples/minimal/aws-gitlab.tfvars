# =============================================================================
# MINIMAL CONFIGURATION - AWS GitLab Runner
# =============================================================================
# Best for: Learning, testing, absolute minimum cost
# Estimated cost: $3-15/month (only when running)
#
# Features:
# ✓ Scale to zero when idle (no baseline cost)
# ✓ Spot instances only (90% savings)
# ✓ Small instance size (2 vCPU, 4GB RAM)
# ✓ 64GB disk (sufficient for most workloads)
#
# Copy this file to your deployment directory:
#   cp examples/minimal/aws-gitlab.tfvars aws/gitlab-runner/terraform.tfvars
# =============================================================================

# -----------------------------------------------------------------------------
# REQUIRED: You MUST customize these values
# -----------------------------------------------------------------------------
project_name = "my-gitlab-runner"   # Change to your project name
gitlab_url   = "https://gitlab.com" # Or your GitLab instance URL
gitlab_token = "glrt-xxxxx"         # Get from GitLab: Settings > CI/CD > Runners

# -----------------------------------------------------------------------------
# AWS Configuration
# -----------------------------------------------------------------------------
region = "us-east-1" # Change to your preferred region

# -----------------------------------------------------------------------------
# Runner Configuration
# -----------------------------------------------------------------------------
runner_tags = "docker,linux,aws,spot,minimal" # Tags for job matching

# -----------------------------------------------------------------------------
# Compute Configuration - Optimized for minimum cost
# -----------------------------------------------------------------------------
instance_type      = "t3.medium" # 2 vCPU, 4GB RAM (~$30/mo on-demand, ~$3/mo spot)
use_spot_instances = true        # 90% cost savings
spot_max_price     = ""          # Empty = pay up to on-demand (recommended)

# -----------------------------------------------------------------------------
# Autoscaling - Scale to zero for minimum cost
# -----------------------------------------------------------------------------
min_size         = 0 # Scale to ZERO when idle
max_size         = 3 # Limit to prevent runaway costs
desired_capacity = 0 # Start with zero instances

# -----------------------------------------------------------------------------
# Runner Instances per VM
# -----------------------------------------------------------------------------
runner_count_per_instance = 0 # 0 = auto (will use 2 for 2 vCPU)

# -----------------------------------------------------------------------------
# Docker Configuration
# -----------------------------------------------------------------------------
docker_image = "fok666/gitlab-runner:latest" # Pre-configured GitLab Runner

# -----------------------------------------------------------------------------
# Storage - Minimal but sufficient
# -----------------------------------------------------------------------------
root_volume_size = 64    # 64GB sufficient for most workloads
root_volume_type = "gp3" # General Purpose SSD (~$5/mo for 64GB)

# -----------------------------------------------------------------------------
# Network Configuration - Use defaults
# -----------------------------------------------------------------------------
# vpc_cidr          = "10.0.0.0/16"                # Uncomment to customize
# public_subnet_cidr = "10.0.1.0/24"               # Uncomment to customize

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------
tags = {
  Environment = "Development"
  Application = "GitLab-Runner"
  ManagedBy   = "Terraform"
  CostCenter  = "Minimal"
}
