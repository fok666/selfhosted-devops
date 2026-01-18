# =============================================================================
# HIGH-PERFORMANCE CONFIGURATION - AWS GitHub Actions Runner
# =============================================================================
# Best for: Large enterprises, compute-intensive workloads, large codebases
# Estimated cost: $400-800/month
#
# Features:
# ✓ Large instance sizes (4 vCPU, 16GB RAM)
# ✓ Higher baseline capacity (3 instances)
# ✓ Premium storage for faster I/O
# ✓ 256GB disk for extensive caching
# ✓ Handles 30-40+ concurrent jobs
#
# Copy this file to your deployment directory:
#   cp examples/high-performance/aws-github.tfvars aws/github-runner/terraform.tfvars
# =============================================================================

# -----------------------------------------------------------------------------
# REQUIRED: You MUST customize these values
# -----------------------------------------------------------------------------
project_name = "high-perf-github-runner" # Change to your project name
github_url   = "https://github.com"      # Or GitHub Enterprise URL
github_token = "ghp_xxxxx"               # Get from GitHub: Settings > Developer settings > PAT
github_scope = "repo"                    # Repository or organization name

# -----------------------------------------------------------------------------
# AWS Configuration
# -----------------------------------------------------------------------------
region = "us-east-1" # Change to your preferred region

# -----------------------------------------------------------------------------
# Runner Configuration
# -----------------------------------------------------------------------------
runner_tags = "docker,linux,aws,high-performance" # Tags for job matching

# -----------------------------------------------------------------------------
# Compute Configuration - High performance
# -----------------------------------------------------------------------------
instance_type      = "t3.xlarge" # 4 vCPU, 16GB RAM (~$120/mo on-demand, ~$36/mo spot)
use_spot_instances = true        # Still use spot where possible
spot_max_price     = ""          # Empty = pay up to on-demand

# -----------------------------------------------------------------------------
# Autoscaling - Higher baseline capacity
# -----------------------------------------------------------------------------
min_size         = 3  # Always 3 instances for capacity
max_size         = 20 # Scale up to 20 for peak load
desired_capacity = 5  # Normal load baseline

# -----------------------------------------------------------------------------
# Runner Instances per VM
# -----------------------------------------------------------------------------
runner_count_per_instance = 0 # 0 = auto (will use 4 for 4 vCPU)

# -----------------------------------------------------------------------------
# Docker Configuration
# -----------------------------------------------------------------------------
docker_image = "fok666/github-runner:latest" # Pre-configured GitHub Actions Runner

# -----------------------------------------------------------------------------
# Storage - Maximum space for extensive caching
# -----------------------------------------------------------------------------
root_volume_size = 256   # 256GB for maximum caching
root_volume_type = "gp3" # General Purpose SSD with better performance
root_volume_iops = 3000  # Higher IOPS for better I/O

# -----------------------------------------------------------------------------
# Network Configuration - Use defaults
# -----------------------------------------------------------------------------
# vpc_cidr           = "10.0.0.0/16"               # Uncomment to customize
# public_subnet_cidr = "10.0.1.0/24"               # Uncomment to customize

# -----------------------------------------------------------------------------
# Autoscaling Thresholds - Very aggressive for performance
# -----------------------------------------------------------------------------
target_cpu_utilization = 60 # Target 60% CPU (very aggressive)

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------
tags = {
  Environment = "Production"
  Application = "GitHub-Runner"
  ManagedBy   = "Terraform"
  CostCenter  = "High-Performance-CI-CD"
  Criticality = "Mission-Critical"
}
