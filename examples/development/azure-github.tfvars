# =============================================================================
# DEVELOPMENT CONFIGURATION - Azure GitHub Actions Runner
# =============================================================================
# Best for: Dev/test environments, small-medium teams, cost-conscious
# Estimated cost: $40-80/month
#
# Features:
# ✓ Maintains 1 baseline instance (fast response)
# ✓ Spot instances for cost savings
# ✓ Balanced VM size (2 vCPU, 8GB RAM)
# ✓ 100GB disk for Docker caching
# ✓ Handles 5-10 concurrent jobs
#
# Copy this file to your deployment directory:
#   cp examples/development/azure-github.tfvars azure/github-runner/terraform.tfvars
# =============================================================================

# -----------------------------------------------------------------------------
# REQUIRED: You MUST customize these values
# -----------------------------------------------------------------------------
project_name = "dev-github-runner"                 # Change to your project name
github_url   = "https://github.com"                # Or GitHub Enterprise URL
github_token = "ghp_xxxxx"                         # Get from GitHub: Settings > Developer settings > PAT
github_scope = "repo"                              # Repository or organization name

# -----------------------------------------------------------------------------
# Azure Configuration
# -----------------------------------------------------------------------------
location = "East US"                               # Change to your preferred region

# -----------------------------------------------------------------------------
# Runner Configuration
# -----------------------------------------------------------------------------
runner_tags = "docker,linux,azure,development"     # Tags for job matching

# -----------------------------------------------------------------------------
# Compute Configuration - Balanced for development
# -----------------------------------------------------------------------------
vm_sku             = "Standard_D2s_v3"             # 2 vCPU, 8GB RAM (~$70/mo on-demand, ~$21/mo spot)
use_spot_instances = true                          # Use spot for cost savings
spot_max_price     = -1                            # Pay up to on-demand price

# -----------------------------------------------------------------------------
# Autoscaling - Maintain 1 baseline instance
# -----------------------------------------------------------------------------
min_instances     = 1                              # Always 1 instance available
max_instances     = 5                              # Scale up to 5 for peak load
default_instances = 1                              # Start with 1 instance

# -----------------------------------------------------------------------------
# Runner Instances per VM
# -----------------------------------------------------------------------------
runner_count_per_vm = 0                            # 0 = auto (will use 2 for 2 vCPU)

# -----------------------------------------------------------------------------
# Docker Configuration
# -----------------------------------------------------------------------------
docker_image = "fok666/github-runner:latest"       # Pre-configured GitHub Actions Runner

# -----------------------------------------------------------------------------
# Storage - Good space for Docker caching
# -----------------------------------------------------------------------------
os_disk_size_gb = 100                              # 100GB for good caching
os_disk_type    = "StandardSSD_LRS"                # Standard SSD

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
  Application = "GitHub-Runner"
  ManagedBy   = "Terraform"
  CostCenter  = "Development-CI-CD"
}
