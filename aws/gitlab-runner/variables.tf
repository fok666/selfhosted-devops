variable "project_name" {
  description = "Project name (used as prefix for resources)"
  type        = string
  default     = "gitlab-runner"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

# =============================================================================
# Network Configuration
# =============================================================================

# Network Creation Flags
variable "create_vpc" {
  description = <<-EOT
    Create a new VPC or use an existing one.
    
    - true: Create new VPC (isolated network, production-ready)
    - false: Use existing VPC (specify existing_vpc_id) or default VPC
    
    Default: true (consistent with Azure pattern, provides network isolation)
  EOT
  type        = bool
  default     = true
}

variable "enable_vpc_flow_logs" {
  description = <<-EOT
    Enable VPC Flow Logs for network traffic monitoring and security analysis.
    
    Security Best Practice: ENABLED (default)
    
    Benefits:
    - Monitor and troubleshoot connectivity issues
    - Detect anomalous traffic patterns
    - Investigate security incidents
    - Meet compliance requirements (PCI-DSS, HIPAA, etc.)
    
    Cost Impact:
    - CloudWatch Logs storage: ~$0.50/GB/month
    - Typical CI/CD runner: ~1-5 GB/month = $0.50-$2.50/month
    
    Default: true (security best practice, logs REJECT traffic only)
  EOT
  type        = bool
  default     = true
}

variable "vpc_flow_logs_traffic_type" {
  description = <<-EOT
    Type of traffic to log in VPC Flow Logs.
    
    Security Best Practice: "REJECT" (default) - logs only rejected traffic
    
    Options:
    - "REJECT": Log only rejected traffic (RECOMMENDED - security-focused, lower cost)
    - "ACCEPT": Log only accepted traffic (troubleshooting)
    - "ALL": Log all traffic (comprehensive but higher cost)
    
    Default: "REJECT" (security best practice, lower cost)
  EOT
  type        = string
  default     = "REJECT"

  validation {
    condition     = contains(["ACCEPT", "REJECT", "ALL"], var.vpc_flow_logs_traffic_type)
    error_message = "vpc_flow_logs_traffic_type must be one of: ACCEPT, REJECT, ALL"
  }
}

variable "vpc_flow_logs_retention_days" {
  description = <<-EOT
    Number of days to retain VPC Flow Logs in CloudWatch.
    
    Common values:
    - 7: One week (compliance minimum)
    - 30: One month (RECOMMENDED for most use cases)
    - 90: Three months (extended security analysis)
    - 365: One year (compliance requirements)
    - 0: Never expire (not recommended, unlimited cost growth)
    
    Default: 30 days (balanced cost and security)
  EOT
  type        = number
  default     = 30

  validation {
    condition     = var.vpc_flow_logs_retention_days >= 0
    error_message = "vpc_flow_logs_retention_days must be >= 0"
  }
}

variable "create_subnets" {
  description = <<-EOT
    Create new Subnets or use existing ones.
    
    - true: Create new subnets (isolated subnets, production-ready)
    - false: Use existing subnets (specify existing_subnet_ids) or default subnets
    
    Default: true (consistent with Azure pattern, provides subnet isolation)
  EOT
  type        = bool
  default     = true
}

variable "create_internet_gateway" {
  description = <<-EOT
    Create a new Internet Gateway or use an existing one.
    
    - true: Create new IGW (only used when create_vpc = true)
    - false: Use existing IGW or VPC's existing IGW
    
    Default: true
  EOT
  type        = bool
  default     = true
}

variable "create_route_table" {
  description = <<-EOT
    Create a new Route Table with routes or use existing one.
    
    - true: Create new route table with internet route
    - false: Use existing route table (must already be configured)
    
    Default: true (only when create_subnets = true)
  EOT
  type        = bool
  default     = true
}

variable "create_security_group" {
  description = <<-EOT
    Create a new Security Group or use an existing one.
    
    - true: Create new security group (default)
    - false: Use existing security group (specify existing_security_group_id)
    
    Default: true
  EOT
  type        = bool
  default     = true
}

# New Network Configuration (when creating new resources)
variable "vpc_cidr" {
  description = "CIDR block for new VPC (only used when create_vpc = true)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_count" {
  description = "Number of subnets to create across availability zones (only used when create_subnets = true)"
  type        = number
  default     = 3

  validation {
    condition     = var.subnet_count >= 1 && var.subnet_count <= 6
    error_message = "subnet_count must be between 1 and 6"
  }
}

variable "map_public_ip_on_launch" {
  description = <<-EOT
    Assign public IPs to instances launched in subnets.
    
    ⚠️ Security Impact:
    - true: Public subnet + public IPs (increased attack surface)
    - false: Private subnet (requires NAT for internet access)
    
    Default: false (secure by default, align with security-first principle)
    
    Note: If false, you must configure NAT Gateway for outbound internet access.
  EOT
  type        = bool
  default     = false
}

# Existing Network Configuration (when using existing resources)
variable "existing_vpc_id" {
  description = "ID of existing VPC (optional, falls back to default VPC if not specified and create_vpc = false)"
  type        = string
  default     = ""
}

# Backwards compatibility - these will be deprecated
variable "vpc_id" {
  description = "[DEPRECATED] Use existing_vpc_id instead. VPC ID (defaults to default VPC)"
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "[DEPRECATED] Use existing_subnet_ids instead. Subnet IDs (defaults to all subnets in VPC)"
  type        = list(string)
  default     = []
}

variable "existing_subnet_ids" {
  description = "List of existing subnet IDs (optional, falls back to default subnets if not specified and create_subnets = false)"
  type        = list(string)
  default     = []
}

variable "existing_internet_gateway_id" {
  description = "ID of existing Internet Gateway (optional, only used when create_vpc = true and create_internet_gateway = false)"
  type        = string
  default     = ""
}

variable "existing_security_group_id" {
  description = "ID of existing Security Group (required when create_security_group = false)"
  type        = string
  default     = ""

  validation {
    condition     = var.create_security_group || var.existing_security_group_id != ""
    error_message = "existing_security_group_id must be provided when create_security_group is false"
  }
}

# Additional Security Group Rules
variable "additional_ingress_rules" {
  description = <<-EOT
    Additional ingress rules for the security group (only used when create_security_group = true).
    
    Example:
    [
      {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["10.0.0.0/8"]
        description = "HTTPS from private network"
      }
    ]
  EOT
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = []
}

variable "additional_egress_rules" {
  description = <<-EOT
    Additional egress rules for the security group (only used when create_security_group = true).
    Note: Default egress rule is automatically created.
    
    Example:
    [
      {
        from_port   = 3306
        to_port     = 3306
        protocol    = "tcp"
        cidr_blocks = ["10.0.0.0/8"]
        description = "MySQL to private network"
      }
    ]
  EOT
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = []
}

# =============================================================================
# SSH Access Configuration (for debugging only)
# =============================================================================

variable "enable_ssh_access" {
  description = "Enable SSH access to instances (not recommended for production)"
  type        = bool
  default     = false
}

variable "ssh_cidr_blocks" {
  description = "CIDR blocks allowed to SSH (only used if enable_ssh_access is true)"
  type        = list(string)
  default     = []

  validation {
    condition     = var.enable_ssh_access == false || length(var.ssh_cidr_blocks) > 0
    error_message = "ssh_cidr_blocks must be provided when enable_ssh_access is true. Use specific CIDR blocks, not 0.0.0.0/0."
  }
}

# =============================================================================
# GitLab Configuration
# =============================================================================

variable "gitlab_url" {
  description = "GitLab URL (e.g., https://gitlab.com)"
  type        = string
}

variable "gitlab_token" {
  description = "GitLab runner registration token"
  type        = string
  sensitive   = true
}

variable "runner_tags" {
  description = "Comma-separated runner tags"
  type        = string
  default     = "docker,linux,aws,spot"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "use_spot_instances" {
  description = "Use spot instances for cost savings"
  type        = bool
  default     = true
}

variable "spot_max_price" {
  description = "Maximum price for spot instances (empty for on-demand price)"
  type        = string
  default     = ""
}

variable "spot_instance_types" {
  description = "List of instance types for spot diversification"
  type        = list(string)
  default     = ["t3.medium", "t3a.medium", "t2.medium"]
}

variable "min_size" {
  description = "Minimum number of instances"
  type        = number
  default     = 0
}

variable "max_size" {
  description = "Maximum number of instances"
  type        = number
  default     = 10
}

variable "desired_capacity" {
  description = "Desired number of instances"
  type        = number
  default     = 1
}

variable "runner_count_per_instance" {
  description = "Number of GitLab runners per instance (0 = auto-detect based on vCPU)"
  type        = number
  default     = 0
}

variable "docker_image" {
  description = "Docker image for GitLab runner"
  type        = string
  default     = "fok666/gitlab-runner:latest"
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 100
}

variable "root_volume_type" {
  description = "Root volume type"
  type        = string
  default     = "gp3"
}

# Security Configuration
variable "enable_imdsv2" {
  description = <<-EOT
    Enable IMDSv2 (Instance Metadata Service version 2) - STRONGLY RECOMMENDED.
    
    IMDSv2 adds session-oriented security to prevent unauthorized access to instance metadata,
    protecting against SSRF attacks and credential theft. Setting this to false increases
    security risk and should only be done for legacy application compatibility.
    
    Security Impact:
    - true (default): Requires session tokens for metadata access (secure)
    - false: Allows open metadata access (vulnerable to SSRF attacks)
  EOT
  type        = bool
  default     = true
}

variable "associate_public_ip_address" {
  description = <<-EOT
    Associate public IP addresses to instances - USE WITH CAUTION.
    
    Public IPs expose instances directly to the internet and increase attack surface.
    Consider using NAT Gateway or VPC endpoints instead for outbound internet access.
    
    Security Impact:
    - false (default): Instances only have private IPs (more secure)
    - true: Instances get public IPs (increased exposure to internet threats)
    
    Note: Outbound internet access is required for CI/CD operations. If set to false,
    ensure you have NAT Gateway configured in your VPC.
  EOT
  type        = bool
  default     = false
}

# trivy:ignore:AVD-AWS-0104 "Unrestricted egress required for CI/CD: GitLab, Docker Hub, package repos, etc."
# tfsec:ignore:aws-ec2-no-public-egress-sgr "CI/CD runners require internet access for typical operations"
variable "egress_cidr_blocks" {
  description = <<-EOT
    CIDR blocks for outbound traffic from security group - USE WITH UNDERSTANDING.
    Default ["0.0.0.0/0"] allows all outbound traffic, which is typically required for:
    - Connecting to GitLab (gitlab.com)
    - Pulling Docker images from public registries
    - Downloading packages and dependencies
    - Accessing public APIs and services
    
    Security Considerations:
    ✓ RECOMMENDED for most CI/CD use cases (default)
    ⚠️ Restrict if you have strict egress filtering requirements
    ⚠️ Use VPC endpoints for AWS services to keep traffic in AWS network
    ⚠️ Consider using VPC Flow Logs for monitoring outbound traffic
    
    To restrict egress (advanced):
    - Specify only required CIDR blocks (e.g., GitLab IP ranges)
    - Use VPC endpoints for AWS services (S3, ECR, etc.)
    - May break GitLab connectivity if misconfigured
    
    Default: ["0.0.0.0/0"] (allows all outbound - required for typical CI/CD)
  EOT
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "egress_from_port" {
  description = <<-EOT
    Starting port for outbound traffic - USE WITH UNDERSTANDING.
    Default 443 with protocol "tcp" allows HTTPS traffic only.
    
    Common port restrictions:
    - 443 only: HTTPS traffic only (may break some CI/CD operations)
    - 80,443: HTTP/HTTPS only
    - 0: All ports (required for some CI/CD operations)
    
    Note: When protocol is "-1" (all), this must be 0.
    Default: 443 (HTTPS only)
  EOT
  type        = number
  default     = 443
}

variable "egress_to_port" {
  description = <<-EOT
    Ending port for outbound traffic - USE WITH UNDERSTANDING.
    Default 443 with protocol "tcp" allows HTTPS traffic only.
    
    Note: When protocol is "-1" (all), this must be 0.
    Default: 443 (HTTPS only)
  EOT
  type        = number
  default     = 443
}

variable "egress_protocol" {
  description = <<-EOT
    Protocol for outbound traffic - USE WITH UNDERSTANDING.
    Default "tcp" allows TCP traffic only (e.g., HTTPS on port 443).
    
    Common values:
    - "tcp": TCP only (default, for HTTPS/HTTP traffic)
    - "udp": UDP only (port 17)
    - "icmp": ICMP only (port 1)
    - "-1": All protocols (required for some CI/CD operations)
    
    Note: Use protocol numbers (6 for TCP, 17 for UDP) or "-1" for all.
    Default: "tcp" (TCP only)
  EOT
  type        = string
  default     = "tcp"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "Production"
    Application = "GitLab-Runner"
    ManagedBy   = "Terraform"
  }
}

# =============================================================================
# Production Features - Distributed Caching (Optional)
# =============================================================================

variable "enable_distributed_cache" {
  description = <<-EOT
    Enable distributed caching using S3 for shared cache across ephemeral runners.
    
    ✨ NEW PRODUCTION FEATURE
    
    **Benefits:**
    - ✓ 2-5x faster builds (shared cache across ephemeral runners)
    - ✓ Consistent performance even when instances are replaced
    - ✓ Reduces bandwidth and package download costs
    - ✓ Works with autoscaling and spot instances
    
    **Cost Impact:**
    - S3 storage: ~$0.023/GB/month (Standard)
    - Typical usage: 10-50 GB = $0.23-$1.15/month
    - Data transfer out: $0.09/GB (minimal for cache)
    - Total estimated cost: $2-10/month for typical workloads
    
    **When to Enable:**
    - ✓ Production deployments with frequent builds
    - ✓ Large codebases with significant dependencies
    - ✓ Teams prioritizing build speed
    
    **Default:** false (backward compatible)
    **Requires:** S3 bucket, IAM permissions
    **See:** PRODUCTION_FEATURES.md for setup guide
  EOT
  type        = bool
  default     = false
}

variable "cache_s3_bucket_name" {
  description = <<-EOT
    Name of the S3 bucket for distributed caching.
    
    **Requirements:**
    - Bucket must exist before deployment
    - Must be in the same region as runners
    - Requires appropriate IAM permissions
    
    **Example:** "my-gitlab-runner-cache"
    
    **Required if:** enable_distributed_cache = true
  EOT
  type        = string
  default     = ""

  validation {
    condition     = !var.enable_distributed_cache || (var.enable_distributed_cache && var.cache_s3_bucket_name != "")
    error_message = "cache_s3_bucket_name is required when enable_distributed_cache is true"
  }
}

variable "cache_s3_bucket_region" {
  description = <<-EOT
    AWS region of the S3 bucket for caching.
    
    **Best Practice:** Use same region as runners to minimize latency and costs
    
    **Default:** Same as aws_region
  EOT
  type        = string
  default     = ""
}

variable "cache_shared" {
  description = <<-EOT
    Share cache between all runners vs. per-runner caching.
    
    **Shared Cache (true - RECOMMENDED):**
    - ✓ Better cache hit rate across all runners
    - ✓ Faster builds for common dependencies
    - ✓ Lower storage costs
    - ⚠️ Requires careful cache key management
    
    **Per-Runner Cache (false):**
    - ✓ Isolated cache per runner
    - ✓ Better for different workloads
    - ⚠️ Higher storage costs
    - ⚠️ Lower cache hit rate
    
    **Default:** true (shared cache)
  EOT
  type        = bool
  default     = true
}

# =============================================================================
# Production Features - Centralized Logging (Optional)
# =============================================================================

variable "enable_centralized_logging" {
  description = <<-EOT
    Enable centralized logging using CloudWatch for runner logs and job output.
    
    ✨ NEW PRODUCTION FEATURE
    
    **Benefits:**
    - ✓ Essential for troubleshooting ephemeral runners
    - ✓ Long-term log retention (30-365 days)
    - ✓ Advanced search and filtering
    - ✓ Integration with CloudWatch Insights
    - ✓ Alerting on errors and anomalies
    
    **Cost Impact:**
    - CloudWatch Logs ingestion: ~$0.50/GB
    - CloudWatch Logs storage: ~$0.03/GB/month
    - Typical usage: 5-20 GB/month = $2.65-$10.60/month
    - Total estimated cost: $5-20/month for typical workloads
    
    **When to Enable:**
    - ✓ Production deployments requiring audit trail
    - ✓ Compliance requirements (SOC2, ISO27001)
    - ✓ Teams needing advanced troubleshooting
    - ✓ Large teams with many concurrent jobs
    
    **Default:** false (backward compatible)
    **Requires:** CloudWatch log group, IAM permissions
    **See:** PRODUCTION_FEATURES.md for setup guide
  EOT
  type        = bool
  default     = false
}

variable "log_group_name" {
  description = <<-EOT
    CloudWatch log group name for runner logs.
    
    **Best Practice:** Use descriptive name like "/aws/gitlab-runner/<project-name>"
    
    **Example:** "/aws/gitlab-runner/production"
    
    **Note:** Log group will be created if it doesn't exist
    
    **Default:** "/aws/gitlab-runner" (if enabled)
  EOT
  type        = string
  default     = "/aws/gitlab-runner"
}

variable "log_retention_days" {
  description = <<-EOT
    Number of days to retain logs in CloudWatch.
    
    **Common Values:**
    - 7: One week (testing/development)
    - 30: One month (RECOMMENDED for production)
    - 90: Three months (compliance)
    - 365: One year (strict compliance)
    - 0: Never expire (not recommended - unlimited cost growth)
    
    **Cost Impact:**
    - 7 days: Minimal storage cost
    - 30 days: Moderate storage cost (~$1.50-$6/month)
    - 90 days: Higher storage cost (~$4.50-$18/month)
    - 365 days: Significant storage cost (~$18-$72/month)
    
    **Default:** 30 days (balanced cost and retention)
  EOT
  type        = number
  default     = 30

  validation {
    condition     = contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "log_retention_days must be one of: 0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653"
  }
}

# =============================================================================
# Production Features - Runner Monitoring (Optional)
# =============================================================================

variable "enable_runner_monitoring" {
  description = <<-EOT
    Enable Prometheus metrics endpoint for runner monitoring and observability.
    
    ✨ NEW PRODUCTION FEATURE
    
    **Benefits:**
    - ✓ Track job success rate, duration, queue depth
    - ✓ Monitor runner health and performance
    - ✓ Integration with Grafana, CloudWatch, Datadog
    - ✓ Proactive alerting on issues
    - ✓ Capacity planning insights
    
    **Cost Impact:**
    - CloudWatch Metrics: ~$0.30/metric/month
    - Typical usage: 10-30 custom metrics = $3-9/month
    - Total estimated cost: Minimal (included in infrastructure)
    
    **When to Enable:**
    - ✓ Production deployments
    - ✓ Teams requiring SLA tracking
    - ✓ Organizations with existing monitoring stack
    
    **Default:** false (backward compatible)
    **Requires:** Security group rule for metrics port
    **See:** PRODUCTION_FEATURES.md for Grafana integration
  EOT
  type        = bool
  default     = false
}

variable "metrics_port" {
  description = <<-EOT
    Port for Prometheus metrics endpoint.
    
    **Default:** 9252 (GitLab Runner standard metrics port)
    
    **Security:** Ensure this port is only accessible from your monitoring infrastructure
  EOT
  type        = number
  default     = 9252

  validation {
    condition     = var.metrics_port >= 1024 && var.metrics_port <= 65535
    error_message = "metrics_port must be between 1024 and 65535"
  }
}

variable "metrics_allowed_cidr_blocks" {
  description = <<-EOT
    CIDR blocks allowed to access Prometheus metrics endpoint.
    
    **Security Best Practice:** Restrict to monitoring infrastructure only
    
    **Example:** ["10.0.0.0/16"] (VPC CIDR only)
    
    **Required if:** enable_runner_monitoring = true
  EOT
  type        = list(string)
  default     = []

  validation {
    condition     = !var.enable_runner_monitoring || (var.enable_runner_monitoring && length(var.metrics_allowed_cidr_blocks) > 0)
    error_message = "metrics_allowed_cidr_blocks is required when enable_runner_monitoring is true"
  }
}
