# =============================================================================
# PRODUCTION CONFIGURATION - Azure GitLab Runner
# =============================================================================
# Best for: Production workloads, medium-large teams, business-critical CI/CD
# Estimated cost: $180-350/month (includes caching, logging, monitoring)
#
# Features:
# ✓ Higher availability (min 2 instances)
# ✓ Distributed caching for faster builds
# ✓ Centralized logging for troubleshooting
# ✓ Prometheus metrics for monitoring
# ✓ Mix of spot and on-demand for reliability
# ✓ Standard VM size (2 vCPU, 8GB RAM)
# ✓ 128GB disk for extensive Docker caching
# ✓ Handles 10-20+ concurrent jobs
#
# Copy this file to your deployment directory:
#   cp examples/production/azure-gitlab.tfvars azure/gitlab-runner/terraform.tfvars
# =============================================================================

# -----------------------------------------------------------------------------
# REQUIRED: You MUST customize these values
# -----------------------------------------------------------------------------
project_name = "production-gitlab-runner"          # Change to your project name
gitlab_url   = "https://gitlab.com"                # Or your GitLab instance URL
gitlab_token = "glrt-xxxxx"                        # Get from GitLab: Settings > CI/CD > Runners

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
docker_image = "fok666/gitlab-runner:latest"       # Pre-configured GitLab Runner

# -----------------------------------------------------------------------------
# Storage - More space for Docker caching
# -----------------------------------------------------------------------------
os_disk_size_gb = 128                              # 128GB for extensive caching
os_disk_type    = "StandardSSD_LRS"                # Standard SSD (good balance)

# =============================================================================
# PRODUCTION FEATURES - Enable for production deployments
# =============================================================================

# -----------------------------------------------------------------------------
# Distributed Caching - HIGHLY RECOMMENDED for production
# -----------------------------------------------------------------------------
enable_distributed_cache     = true
cache_type                   = "azurerm"
cache_shared                 = true
cache_storage_account_name   = "prodgitlabrunnercache" # CHANGE THIS - must be globally unique
cache_storage_container_name = "runner-cache"
# cache_storage_account_key  = ""                  # Leave empty to use Managed Identity (recommended)

# Benefits:
# - 2-5x faster builds (cached dependencies shared across runners)
# - Reduced bandwidth costs
# - Essential for ephemeral runners
# Cost: ~$2-5/month for 100GB cache

# -----------------------------------------------------------------------------
# Centralized Logging - HIGHLY RECOMMENDED for production
# -----------------------------------------------------------------------------
enable_centralized_logging  = true
# log_analytics_workspace_id  = "/subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.OperationalInsights/workspaces/{workspace}"
# log_analytics_workspace_key = "your-workspace-key"
log_retention_days          = 30

# To get Log Analytics workspace credentials:
# 1. Create workspace: az monitor log-analytics workspace create --name myworkspace --resource-group myrg --location eastus
# 2. Get workspace ID: az monitor log-analytics workspace show --name myworkspace --resource-group myrg --query id -o tsv
# 3. Get workspace key: az monitor log-analytics workspace get-shared-keys --name myworkspace --resource-group myrg --query primarySharedKey -o tsv

# Benefits:
# - Troubleshoot ephemeral runners after termination
# - Long-term log retention for compliance
# - Advanced alerting and anomaly detection
# Cost: ~$0.50/GB ingested + $0.03/GB/month retention (~$5-15/month typical)

# -----------------------------------------------------------------------------
# Runner Monitoring - HIGHLY RECOMMENDED for production
# -----------------------------------------------------------------------------
enable_runner_monitoring = true
metrics_port             = 9252

# Benefits:
# - Track job duration, queue depth, success rate
# - Proactive alerting on runner failures
# - Capacity planning insights
# - Integration with Grafana, Azure Monitor
# Cost: Minimal (uses existing Azure Monitor)

# =============================================================================
# END PRODUCTION FEATURES
# =============================================================================

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
  Application = "GitLab-Runner"
  ManagedBy   = "Terraform"
  CostCenter  = "Production-CI-CD"
  Monitoring  = "Enabled"
  Caching     = "Enabled"
}
  Criticality = "High"
}
