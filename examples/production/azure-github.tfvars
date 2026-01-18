# =============================================================================
# PRODUCTION CONFIGURATION - Azure GitHub Actions Runner
# =============================================================================
# Best for: Production workloads, medium-large teams, business-critical CI/CD
# Estimated cost: $150-300/month
#
# Features:
# ✓ Higher availability (min 2 instances)
# ✓ Mix of spot and on-demand for reliability
# ✓ Standard VM size (2 vCPU, 8GB RAM)
# ✓ 128GB disk for extensive Docker caching
# ✓ Handles 10-20+ concurrent jobs
#
# Copy this file to your deployment directory:
#   cp examples/production/azure-github.tfvars azure/github-runner/terraform.tfvars
# =============================================================================

# -----------------------------------------------------------------------------
# REQUIRED: You MUST customize these values
# -----------------------------------------------------------------------------
project_name = "production-github-runner"          # Change to your project name
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
runner_tags = "docker,linux,azure,production"      # Tags for job matching

# -----------------------------------------------------------------------------
# Compute Configuration - Production-grade
# -----------------------------------------------------------------------------
vm_sku             = "Standard_D2s_v3"             # 2 vCPU, 8GB RAM (~$70/mo on-demand, ~$21/mo spot)
use_spot_instances = true                          # Still use spot for cost savings
spot_max_price     = -1                            # Pay up to on-demand price

# -----------------------------------------------------------------------------
# Autoscaling - Always maintain baseline capacity
# -----------------------------------------------------------------------------
min_instances     = 2                              # Always 2 instances for availability
max_instances     = 10                             # Scale up to 10 for peak load
default_instances = 3                              # Normal load baseline

# -----------------------------------------------------------------------------
# Runner Instances per VM
# -----------------------------------------------------------------------------
runner_count_per_vm = 0                            # 0 = auto (will use 2 for 2 vCPU)

# -----------------------------------------------------------------------------
# Docker Configuration
# -----------------------------------------------------------------------------
docker_image = "fok666/github-runner:latest"       # Pre-configured GitHub Actions Runner

# -----------------------------------------------------------------------------
# Storage - More space for Docker caching
# -----------------------------------------------------------------------------
os_disk_size_gb = 128                              # 128GB for extensive caching
os_disk_type    = "StandardSSD_LRS"                # Standard SSD (good balance)

# -----------------------------------------------------------------------------
# Network Configuration - Use defaults
# -----------------------------------------------------------------------------
# vnet_cidr   = "10.0.0.0/16"                      # Uncomment to customize
# subnet_cidr = "10.0.1.0/24"                      # Uncomment to customize

# -----------------------------------------------------------------------------
# Autoscaling Thresholds - Tuned for production
# -----------------------------------------------------------------------------
# Scale out more aggressively, scale in conservatively
cpu_scale_out_threshold = 65                       # Scale out at 65% CPU (more aggressive)
cpu_scale_in_threshold  = 25                       # Scale in at 25% CPU (more conservative)

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------
tags = {
  Environment = "Production"
  Application = "GitHub-Runner"
  ManagedBy   = "Terraform"
  CostCenter  = "Production-CI-CD"
  Criticality = "High"
}
