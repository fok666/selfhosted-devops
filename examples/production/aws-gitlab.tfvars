# =============================================================================
# PRODUCTION CONFIGURATION - AWS GitLab Runner
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
#   cp examples/production/aws-gitlab.tfvars aws/gitlab-runner/terraform.tfvars
# =============================================================================

# -----------------------------------------------------------------------------
# REQUIRED: You MUST customize these values
# -----------------------------------------------------------------------------
project_name = "production-gitlab-runner" # Change to your project name
gitlab_url   = "https://gitlab.com"       # Or your GitLab instance URL
gitlab_token = "glrt-xxxxx"               # Get from GitLab: Settings > CI/CD > Runners

# -----------------------------------------------------------------------------
# AWS Configuration
# -----------------------------------------------------------------------------
region = "us-east-1" # Change to your preferred region

# -----------------------------------------------------------------------------
# Runner Configuration
# -----------------------------------------------------------------------------
runner_tags = "docker,linux,aws,production" # Tags for job matching

# -----------------------------------------------------------------------------
# Compute Configuration - Production-grade
# -----------------------------------------------------------------------------
instance_type      = "t3.large" # 2 vCPU, 8GB RAM (~$60/mo on-demand, ~$18/mo spot)
use_spot_instances = true       # Still use spot for cost savings
spot_max_price     = ""         # Empty = pay up to on-demand

# -----------------------------------------------------------------------------
# Autoscaling - Always maintain baseline capacity
# -----------------------------------------------------------------------------
min_size         = 2  # Always 2 instances for availability
max_size         = 10 # Scale up to 10 for peak load
desired_capacity = 3  # Normal load baseline

# -----------------------------------------------------------------------------
# Runner Instances per VM
# -----------------------------------------------------------------------------
runner_count_per_instance = 0 # 0 = auto (will use 2 for 2 vCPU)

# -----------------------------------------------------------------------------
# Docker Configuration
# -----------------------------------------------------------------------------
docker_image = "fok666/gitlab-runner:latest" # Pre-configured GitLab Runner

# -----------------------------------------------------------------------------
# Storage - More space for Docker caching
# -----------------------------------------------------------------------------
root_volume_size = 128   # 128GB for extensive caching
root_volume_type = "gp3" # General Purpose SSD

# -----------------------------------------------------------------------------
# Network Configuration - Use defaults
# -----------------------------------------------------------------------------
# vpc_cidr           = "10.0.0.0/16"               # Uncomment to customize
# public_subnet_cidr = "10.0.1.0/24"               # Uncomment to customize

# -----------------------------------------------------------------------------
# Autoscaling Thresholds - Tuned for production
# -----------------------------------------------------------------------------
# Scale out more aggressively, scale in conservatively
target_cpu_utilization = 65 # Target 65% CPU utilization

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------
tags = {
  Environment = "Production"
  Application = "GitLab-Runner"
  ManagedBy   = "Terraform"
  CostCenter  = "Production-CI-CD"
  Criticality = "High"
}

# =============================================================================
# ✨ PRODUCTION FEATURES (Recommended for Enterprise Deployments)
# =============================================================================
# These optional features enhance operational excellence, troubleshooting,
# and observability for production GitLab Runner deployments.
#
# Total additional cost: ~$10-50/month
# ROI: Significantly reduced incident resolution time, better performance
# =============================================================================

# -----------------------------------------------------------------------------
# Distributed Caching - S3 Shared Cache
# -----------------------------------------------------------------------------
# Benefits:
# - ✓ 2-5x faster builds through shared cache
# - ✓ Persistent cache across ephemeral instances
# - ✓ Reduces bandwidth and package download costs
# - ✓ Essential for autoscaling and spot instance workloads
#
# Cost: ~$2-10/month (S3 storage + requests)
#
# Setup:
# 1. Create S3 bucket: aws s3 mb s3://my-gitlab-runner-cache --region us-east-1
# 2. Uncomment variables below
# 3. Ensure IAM role has s3:GetObject, s3:PutObject, s3:ListBucket permissions
# -----------------------------------------------------------------------------
enable_distributed_cache = true
cache_s3_bucket_name     = "my-gitlab-runner-cache" # Change to your bucket name
cache_s3_bucket_region   = "us-east-1"              # Same as aws_region for best performance
cache_shared             = true                     # Share cache between all runners

# -----------------------------------------------------------------------------
# Centralized Logging - CloudWatch Logs Integration
# -----------------------------------------------------------------------------
# Benefits:
# - ✓ Essential for troubleshooting ephemeral runners
# - ✓ Long-term log retention for audit and compliance
# - ✓ Advanced search and filtering with CloudWatch Insights
# - ✓ Integration with CloudWatch alarms for error detection
# - ✓ Searchable history of all runner activities
#
# Cost: ~$5-20/month (ingestion + storage)
#
# Setup:
# 1. Log group will be created automatically
# 2. Uncomment variables below
# 3. Ensure IAM role has logs:CreateLogGroup, logs:CreateLogStream, logs:PutLogEvents
# -----------------------------------------------------------------------------
enable_centralized_logging = true
log_group_name             = "/aws/gitlab-runner/production"
log_retention_days         = 30 # 30 days for production (7, 30, 90, 365 available)

# -----------------------------------------------------------------------------
# Runner Monitoring - Prometheus Metrics
# -----------------------------------------------------------------------------
# Benefits:
# - ✓ Track job success rate, duration, queue depth in real-time
# - ✓ Monitor runner health and performance
# - ✓ Integration with CloudWatch, Grafana, Datadog
# - ✓ Proactive alerting on issues (long queues, failing jobs)
# - ✓ Capacity planning insights
#
# Cost: Minimal (~$3-9/month for CloudWatch custom metrics)
#
# Setup:
# 1. Uncomment variables below
# 2. Configure CloudWatch metrics collection or Prometheus scraping
# 3. Set up Grafana dashboards (templates available)
# 4. Ensure security group allows access from monitoring infrastructure
# -----------------------------------------------------------------------------
enable_runner_monitoring    = true
metrics_port                = 9252            # GitLab Runner standard metrics port
metrics_allowed_cidr_blocks = ["10.0.0.0/16"] # Your VPC CIDR for monitoring access
