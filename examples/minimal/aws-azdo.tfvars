# =============================================================================
# MINIMAL CONFIGURATION - Azure DevOps Agent (AWS)
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
#   cp examples/minimal/aws-azdo.tfvars aws/azure-devops-agent/terraform.tfvars
# =============================================================================

# -----------------------------------------------------------------------------
# REQUIRED: You MUST customize these values
# -----------------------------------------------------------------------------
project_name = "my-azdo-agent"                     # Change to your project name
azdo_url     = "https://dev.azure.com/yourorg"     # Your Azure DevOps organization URL
azdo_token   = "xxxxx"                             # Get from Azure DevOps: User Settings > PAT
azdo_pool    = "Default"                           # Agent pool name

# -----------------------------------------------------------------------------
# AWS Configuration
# -----------------------------------------------------------------------------
region = "us-east-1"                               # Change to your preferred region

# -----------------------------------------------------------------------------
# Agent Configuration
# -----------------------------------------------------------------------------
agent_tags = "docker,linux,aws,spot,minimal"       # Tags for job matching

# -----------------------------------------------------------------------------
# Compute Configuration - Optimized for minimum cost
# -----------------------------------------------------------------------------
instance_type      = "t3.medium"                   # 2 vCPU, 4GB RAM (~$30/mo on-demand, ~$3/mo spot)
use_spot_instances = true                          # 90% cost savings
spot_max_price     = ""                            # Empty = pay up to on-demand (recommended)

# -----------------------------------------------------------------------------
# Autoscaling - Scale to zero for minimum cost
# -----------------------------------------------------------------------------
min_size         = 0                               # Scale to ZERO when idle
max_size         = 3                               # Limit to prevent runaway costs
desired_capacity = 0                               # Start with zero instances

# -----------------------------------------------------------------------------
# Agent Instances per VM
# -----------------------------------------------------------------------------
agent_count_per_instance = 0                       # 0 = auto (will use 2 for 2 vCPU)

# -----------------------------------------------------------------------------
# Docker Configuration
# -----------------------------------------------------------------------------
docker_image = "fok666/azure-devops-agent:latest"  # Pre-configured Azure DevOps Agent

# -----------------------------------------------------------------------------
# Storage - Minimal but sufficient
# -----------------------------------------------------------------------------
root_volume_size = 64                              # 64GB sufficient for most workloads
root_volume_type = "gp3"                           # General Purpose SSD (~$5/mo for 64GB)

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
  Application = "Azure-DevOps-Agent"
  ManagedBy   = "Terraform"
  CostCenter  = "Minimal"
}
