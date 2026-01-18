# =============================================================================
# MINIMAL CONFIGURATION - Azure GitLab Runner
# =============================================================================
# Best for: Learning, testing, absolute minimum cost
# Estimated cost: $5-20/month (only when running)
#
# Features:
# ✓ Scale to zero when idle (no baseline cost)
# ✓ Spot instances only (90% savings)
# ✓ Small VM size (2 vCPU, 4GB RAM)
# ✓ 64GB disk (sufficient for most workloads)
#
# Copy this file to your deployment directory:
#   cp examples/minimal/azure-gitlab.tfvars azure/gitlab-runner/terraform.tfvars
# =============================================================================

# -----------------------------------------------------------------------------
# REQUIRED: You MUST customize these values
# -----------------------------------------------------------------------------
project_name = "my-gitlab-runner"                  # Change to your project name
gitlab_url   = "https://gitlab.com"                # Or your GitLab instance URL
gitlab_token = "glrt-xxxxx"                        # Get from GitLab: Settings > CI/CD > Runners

# -----------------------------------------------------------------------------
# Azure Configuration
# -----------------------------------------------------------------------------
location = "East US"                               # Change to your preferred region

# -----------------------------------------------------------------------------
# Runner Configuration
# -----------------------------------------------------------------------------
runner_tags = "docker,linux,azure,spot,minimal"    # Tags for job matching

# -----------------------------------------------------------------------------
# Compute Configuration - Optimized for minimum cost
# -----------------------------------------------------------------------------
vm_sku             = "Standard_B2s"                # Burstable, 2 vCPU, 4GB RAM (~$30/mo on-demand, ~$3/mo spot)
use_spot_instances = true                          # 90% cost savings
spot_max_price     = -1                            # Pay up to on-demand price (recommended)

# -----------------------------------------------------------------------------
# Autoscaling - Scale to zero for minimum cost
# -----------------------------------------------------------------------------
min_instances     = 0                              # Scale to ZERO when idle
max_instances     = 3                              # Limit to prevent runaway costs
default_instances = 0                              # Start with zero instances

# -----------------------------------------------------------------------------
# Runner Instances per VM
# -----------------------------------------------------------------------------
runner_count_per_vm = 0                            # 0 = auto (will use 2 for 2 vCPU)

# -----------------------------------------------------------------------------
# Docker Configuration
# -----------------------------------------------------------------------------
docker_image = "fok666/gitlab-runner:latest"       # Pre-configured GitLab Runner

# -----------------------------------------------------------------------------
# Storage - Minimal but sufficient
# -----------------------------------------------------------------------------
os_disk_size_gb = 64                               # 64GB sufficient for most workloads
os_disk_type    = "StandardSSD_LRS"                # Standard SSD (~$5/mo for 64GB)

# -----------------------------------------------------------------------------
# Network Configuration - Use defaults
# -----------------------------------------------------------------------------
# vnet_cidr   = "10.0.0.0/16"                      # Uncomment to customize
# subnet_cidr = "10.0.1.0/24"                      # Uncomment to customize

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------
tags = {
  Environment = "Development"
  Application = "GitLab-Runner"
  ManagedBy   = "Terraform"
  CostCenter  = "Minimal"
}
