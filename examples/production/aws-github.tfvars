# =============================================================================
# PRODUCTION CONFIGURATION - AWS GitHub Actions Runner
# =============================================================================
# Best for: Production workloads, medium-large teams, business-critical CI/CD
# Estimated cost: $120-250/month
#
# Features:
# ✓ Higher availability (min 2 instances)
# ✓ Mix of spot and on-demand for reliability
# ✓ Standard instance size (2 vCPU, 8GB RAM)
# ✓ 128GB disk for extensive Docker caching
# ✓ Handles 10-20+ concurrent jobs
#
# Copy this file to your deployment directory:
#   cp examples/production/aws-github.tfvars aws/github-runner/terraform.tfvars
# =============================================================================

# -----------------------------------------------------------------------------
# REQUIRED: You MUST customize these values
# -----------------------------------------------------------------------------
project_name = "production-github-runner"          # Change to your project name
github_url   = "https://github.com"                # Or GitHub Enterprise URL
github_token = "ghp_xxxxx"                         # Get from GitHub: Settings > Developer settings > PAT
github_scope = "repo"                              # Repository or organization name

# -----------------------------------------------------------------------------
# AWS Configuration
# -----------------------------------------------------------------------------
region = "us-east-1"                               # Change to your preferred region

# -----------------------------------------------------------------------------
# Runner Configuration
# -----------------------------------------------------------------------------
runner_tags = "docker,linux,aws,production"        # Tags for job matching

# -----------------------------------------------------------------------------
# Compute Configuration - Production-grade
# -----------------------------------------------------------------------------
instance_type      = "t3.large"                    # 2 vCPU, 8GB RAM (~$60/mo on-demand, ~$18/mo spot)
use_spot_instances = true                          # Still use spot for cost savings
spot_max_price     = ""                            # Empty = pay up to on-demand

# -----------------------------------------------------------------------------
# Autoscaling - Always maintain baseline capacity
# -----------------------------------------------------------------------------
min_size         = 2                               # Always 2 instances for availability
max_size         = 10                              # Scale up to 10 for peak load
desired_capacity = 3                               # Normal load baseline

# -----------------------------------------------------------------------------
# Runner Instances per VM
# -----------------------------------------------------------------------------
runner_count_per_instance = 0                      # 0 = auto (will use 2 for 2 vCPU)

# -----------------------------------------------------------------------------
# Docker Configuration
# -----------------------------------------------------------------------------
docker_image = "fok666/github-runner:latest"       # Pre-configured GitHub Actions Runner

# -----------------------------------------------------------------------------
# Storage - More space for Docker caching
# -----------------------------------------------------------------------------
root_volume_size = 128                             # 128GB for extensive caching
root_volume_type = "gp3"                           # General Purpose SSD

# -----------------------------------------------------------------------------
# Network Configuration - Use defaults
# -----------------------------------------------------------------------------
# vpc_cidr           = "10.0.0.0/16"               # Uncomment to customize
# public_subnet_cidr = "10.0.1.0/24"               # Uncomment to customize

# -----------------------------------------------------------------------------
# Autoscaling Thresholds - Tuned for production
# -----------------------------------------------------------------------------
# Scale out more aggressively, scale in conservatively
target_cpu_utilization = 65                        # Target 65% CPU utilization

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
