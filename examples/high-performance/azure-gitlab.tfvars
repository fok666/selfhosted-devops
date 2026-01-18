# =============================================================================
# HIGH-PERFORMANCE CONFIGURATION - Azure GitLab Runner
# =============================================================================
# Best for: Large enterprises, compute-intensive workloads, large codebases
# Estimated cost: $500-1000/month
#
# Features:
# ✓ Large VM sizes (4 vCPU, 16GB RAM)
# ✓ Higher baseline capacity (3 instances)
# ✓ Premium SSD disks for faster I/O
# ✓ 256GB disk for extensive caching
# ✓ Handles 30-40+ concurrent jobs
#
# Copy this file to your deployment directory:
#   cp examples/high-performance/azure-gitlab.tfvars azure/gitlab-runner/terraform.tfvars
# =============================================================================

# -----------------------------------------------------------------------------
# REQUIRED: You MUST customize these values
# -----------------------------------------------------------------------------
project_name = "high-perf-gitlab-runner"           # Change to your project name
gitlab_url   = "https://gitlab.com"                # Or your GitLab instance URL
gitlab_token = "glrt-xxxxx"                        # Get from GitLab: Settings > CI/CD > Runners

# -----------------------------------------------------------------------------
# Azure Configuration
# -----------------------------------------------------------------------------
location = "East US"                               # Change to your preferred region

# -----------------------------------------------------------------------------
# Runner Configuration
# -----------------------------------------------------------------------------
runner_tags = "docker,linux,azure,high-performance" # Tags for job matching

# -----------------------------------------------------------------------------
# Compute Configuration - High performance
# -----------------------------------------------------------------------------
vm_sku             = "Standard_D4s_v3"             # 4 vCPU, 16GB RAM (~$140/mo on-demand, ~$42/mo spot)
use_spot_instances = true                          # Still use spot where possible
spot_max_price     = -1                            # Pay up to on-demand price

# -----------------------------------------------------------------------------
# Autoscaling - Higher baseline capacity
# -----------------------------------------------------------------------------
min_instances     = 3                              # Always 3 instances for capacity
max_instances     = 20                             # Scale up to 20 for peak load
default_instances = 5                              # Normal load baseline

# -----------------------------------------------------------------------------
# Runner Instances per VM
# -----------------------------------------------------------------------------
runner_count_per_vm = 0                            # 0 = auto (will use 4 for 4 vCPU)

# -----------------------------------------------------------------------------
# Docker Configuration
# -----------------------------------------------------------------------------
docker_image = "fok666/gitlab-runner:latest"       # Pre-configured GitLab Runner

# -----------------------------------------------------------------------------
# Storage - Maximum space for extensive caching
# -----------------------------------------------------------------------------
os_disk_size_gb = 256                              # 256GB for maximum caching
os_disk_type    = "Premium_LRS"                    # Premium SSD for best I/O

# -----------------------------------------------------------------------------
# Network Configuration - Use defaults
# -----------------------------------------------------------------------------
# vnet_cidr   = "10.0.0.0/16"                      # Uncomment to customize
# subnet_cidr = "10.0.1.0/24"                      # Uncomment to customize

# -----------------------------------------------------------------------------
# Autoscaling Thresholds - Very aggressive for performance
# -----------------------------------------------------------------------------
cpu_scale_out_threshold = 60                       # Scale out at 60% CPU (very aggressive)
cpu_scale_in_threshold  = 20                       # Scale in at 20% CPU (very conservative)

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------
tags = {
  Environment = "Production"
  Application = "GitLab-Runner"
  ManagedBy   = "Terraform"
  CostCenter  = "High-Performance-CI-CD"
  Criticality = "Mission-Critical"
}
