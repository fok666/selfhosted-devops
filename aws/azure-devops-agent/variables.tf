variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "azdevops-agent"
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

# Azure DevOps Configuration
variable "azp_url" {
  description = "Azure DevOps organization URL (e.g., https://dev.azure.com/your-org)"
  type        = string
  sensitive   = false
}

variable "azp_token" {
  description = "Azure DevOps Personal Access Token with Agent Pools (read, manage) scope"
  type        = string
  sensitive   = true
}

variable "azp_pool" {
  description = "Azure DevOps agent pool name"
  type        = string
  default     = "Default"
}

variable "azp_agent_name_prefix" {
  description = "Prefix for Azure DevOps agent names"
  type        = string
  default     = "aws-agent"
}

variable "agent_count_per_instance" {
  description = "Number of Azure DevOps agents per instance (0 = auto-detect based on vCPU)"
  type        = number
  default     = 0
}

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
# Network Configuration
# =============================================================================

# Network Creation Flags
variable "create_vpc" {
  description = <<-EOT
    Create a new VPC or use an existing one.
    
    - true: Create new VPC (default)
    - false: Use existing VPC (specify existing_vpc_id)
    
    Default: true
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
    
    - true: Create new subnets (default)
    - false: Use existing subnets (specify existing_subnet_ids)
    
    Default: true
  EOT
  type        = bool
  default     = true
}

variable "create_internet_gateway" {
  description = <<-EOT
    Create a new Internet Gateway or use an existing one.
    
    - true: Create new IGW (default)
    - false: Use existing IGW (specify existing_internet_gateway_id)
    
    Default: true
  EOT
  type        = bool
  default     = true
}

variable "create_route_table" {
  description = <<-EOT
    Create a new Route Table with routes or use existing one.
    
    - true: Create new route table with internet route (default)
    - false: Use existing route table (must already be configured)
    
    Default: true
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
  description = "ID of existing VPC (required when create_vpc = false)"
  type        = string
  default     = ""

  validation {
    condition     = var.create_vpc || var.existing_vpc_id != ""
    error_message = "existing_vpc_id must be provided when create_vpc is false"
  }
}

variable "existing_subnet_ids" {
  description = "List of existing subnet IDs (required when create_subnets = false)"
  type        = list(string)
  default     = []

  validation {
    condition     = var.create_subnets || length(var.existing_subnet_ids) > 0
    error_message = "existing_subnet_ids must be provided when create_subnets is false"
  }
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

# EC2 Configuration
variable "instance_types" {
  description = "List of EC2 instance types for diversification"
  type        = list(string)
  default     = ["t3.medium", "t3a.medium", "t2.medium"]
}

variable "use_spot_instances" {
  description = "Use EC2 Spot instances for cost savings"
  type        = bool
  default     = true
}

variable "spot_max_price" {
  description = "Maximum price for spot instances (optional, empty for on-demand price)"
  type        = string
  default     = ""
}

# Autoscaling Configuration
variable "min_instances" {
  description = "Minimum number of instances"
  type        = number
  default     = 0

  validation {
    condition     = var.min_instances >= 0
    error_message = "Minimum instances must be >= 0"
  }
}

variable "max_instances" {
  description = "Maximum number of instances"
  type        = number
  default     = 10

  validation {
    condition     = var.max_instances > 0 && var.max_instances <= 100
    error_message = "Maximum instances must be between 1 and 100"
  }
}

variable "default_instances" {
  description = "Default number of instances"
  type        = number
  default     = 1

  validation {
    condition     = var.default_instances >= 0
    error_message = "Default instances must be >= 0"
  }
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

# trivy:ignore:AVD-AWS-0104 "Unrestricted egress required for CI/CD: GitHub, Docker Hub, package repos, etc."
# tfsec:ignore:aws-ec2-no-public-egress-sgr "CI/CD runners require internet access for typical operations"
variable "egress_cidr_blocks" {
  description = <<-EOT
    CIDR blocks for outbound traffic from security group - USE WITH UNDERSTANDING.
    Default ["0.0.0.0/0"] allows all outbound traffic, which is typically required for:
    - Connecting to Azure DevOps (dev.azure.com)
    - Pulling Docker images from public registries
    - Downloading packages and dependencies
    - Accessing public APIs and services
    
    Security Considerations:
    ✓ RECOMMENDED for most CI/CD use cases (default)
    ⚠️ Restrict if you have strict egress filtering requirements
    ⚠️ Use VPC endpoints for AWS services to keep traffic in AWS network
    ⚠️ Consider using VPC Flow Logs for monitoring outbound traffic
    
    To restrict egress (advanced):
    - Specify only required CIDR blocks (e.g., Azure DevOps IP ranges)
    - Use VPC endpoints for AWS services (S3, ECR, etc.)
    - May break Azure DevOps connectivity if misconfigured
    
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

# Tags
variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "production"
    ManagedBy   = "terraform"
    Purpose     = "azure-devops-agent"
  }
}
# =============================================================================
# Production Features (Optional)
# =============================================================================

# ---------- Distributed Caching (S3) ----------
variable "enable_distributed_cache" {
  description = <<-EOT
    Enable distributed cache sharing across agents using Amazon S3.
    
    **Benefits:**
    - ✓ Faster build times (cache dependencies, build artifacts)
    - ✓ Reduced bandwidth usage
    - ✓ Shared cache across all agents
    
    **Cost Impact:**
    - S3 storage: ~$0.023/GB/month (Standard)
    - GET requests: $0.0004/1000 requests
    - PUT requests: $0.005/1000 requests
    - **Estimated:** $2-5/month for typical usage (100GB storage)
    
    **Default:** false (disabled)
    **Requires:** cache_s3_bucket_name, cache_s3_region
  EOT
  type        = bool
  default     = false
}

variable "cache_s3_bucket_name" {
  description = <<-EOT
    S3 bucket name for distributed cache storage.
    
    **Requirements:**
    - Must be globally unique across all AWS accounts
    - 3-63 characters, lowercase letters, numbers, hyphens
    - Cannot start or end with hyphen
    
    **Example:** "mycompany-azdevops-cache-us-east-1"
    
    **Required when:** enable_distributed_cache = true
  EOT
  type        = string
  default     = ""
}

variable "cache_s3_region" {
  description = <<-EOT
    AWS region for the S3 cache bucket.
    
    **Recommendation:** Use the same region as your agents for:
    - ✓ Lowest latency
    - ✓ No data transfer costs between regions
    - ✓ Better performance
    
    **Default:** Same as aws_region
    **Required when:** enable_distributed_cache = true
  EOT
  type        = string
  default     = ""
}

variable "cache_s3_prefix" {
  description = <<-EOT
    S3 key prefix for cache objects (folder path).
    
    **Use Cases:**
    - Share bucket across multiple projects: "project-a/cache/"
    - Environment separation: "prod/cache/" vs "dev/cache/"
    - Team isolation: "team-backend/cache/"
    
    **Default:** "cache/" (all agents share same cache)
  EOT
  type        = string
  default     = "cache/"
}

variable "cache_shared" {
  description = <<-EOT
    Enable cache sharing across all agents.
    
    **Options:**
    - "true": All agents share the same cache (recommended for teams)
    - "false": Each agent has its own isolated cache
    
    **Recommendation:** true (faster builds, better cache hit rate)
    
    **Default:** "true"
  EOT
  type        = string
  default     = "true"

  validation {
    condition     = contains(["true", "false"], var.cache_shared)
    error_message = "cache_shared must be either 'true' or 'false' (as string)"
  }
}

# ---------- Centralized Logging (CloudWatch) ----------
variable "enable_centralized_logging" {
  description = <<-EOT
    Enable centralized logging using Amazon CloudWatch Logs.
    
    **Benefits:**
    - ✓ Centralized log aggregation and search
    - ✓ Long-term log retention
    - ✓ Real-time log streaming
    - ✓ Integration with CloudWatch Insights for log analysis
    
    **Cost Impact:**
    - Ingestion: $0.50/GB
    - Storage: $0.03/GB/month
    - Queries: Included (up to reasonable limits)
    - **Estimated:** $2-10/month for typical usage (5-20GB/month)
    
    **What's Logged:**
    - Agent registration logs
    - Build execution logs
    - Docker container logs
    - System logs (syslog)
    
    **Default:** false (disabled)
    **Requires:** cloudwatch_log_group_name
  EOT
  type        = bool
  default     = false
}

variable "cloudwatch_log_group_name" {
  description = <<-EOT
    CloudWatch Logs group name for centralized logging.
    
    **Naming Convention:**
    - /aws/azdevops/agents/{environment}
    - /azdevops-agents/production
    - /agents/azdevops/{team-name}
    
    **Example:** "/aws/azdevops/agents/production"
    
    **Note:** Log group will be created automatically if it doesn't exist
    
    **Required when:** enable_centralized_logging = true
  EOT
  type        = string
  default     = "/aws/azdevops/agents"
}

variable "cloudwatch_log_retention_days" {
  description = <<-EOT
    Number of days to retain logs in CloudWatch.
    
    **Common Values:**
    - 7: Development/testing (cost-optimized)
    - 30: Standard production workloads
    - 90: Compliance requirements
    - 365: Long-term audit requirements
    - 0: Never expire (not recommended - unbounded costs)
    
    **Cost Impact:**
    - Storage cost scales linearly with retention period
    - Example: 7 days = $0.21/GB total, 30 days = $0.90/GB total
    
    **Default:** 7 days
  EOT
  type        = number
  default     = 7

  validation {
    condition = contains([
      0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180,
      365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653
    ], var.cloudwatch_log_retention_days)
    error_message = "cloudwatch_log_retention_days must be a valid CloudWatch retention period"
  }
}

variable "cloudwatch_agent_config" {
  description = <<-EOT
    Custom CloudWatch agent configuration (JSON).
    
    **Use Cases:**
    - Custom log collection paths
    - Specific log parsing rules
    - Advanced metric collection
    
    **Default:** null (uses standard configuration)
    **Reference:** https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-Agent-Configuration-File-Details.html
  EOT
  type        = string
  default     = null
}

# ---------- Agent Monitoring (Prometheus) ----------
variable "enable_agent_monitoring" {
  description = <<-EOT
    Enable Prometheus metrics endpoint for agent monitoring.
    
    **Benefits:**
    - ✓ Real-time agent health monitoring
    - ✓ Resource usage metrics (CPU, memory, disk)
    - ✓ Build queue and execution metrics
    - ✓ Integration with Prometheus/Grafana
    
    **Metrics Exposed:**
    - agent_status (online/offline)
    - agent_cpu_usage_percent
    - agent_memory_usage_bytes
    - agent_disk_usage_percent
    - agent_build_duration_seconds
    - agent_build_success_total
    - agent_build_failure_total
    
    **Cost Impact:**
    - Free (requires external Prometheus server to scrape metrics)
    
    **Security:**
    - Metrics endpoint is exposed on internal network only
    - No authentication required (internal network trust)
    
    **Default:** false (disabled)
    **Requires:** metrics_port
  EOT
  type        = bool
  default     = false
}

variable "metrics_port" {
  description = <<-EOT
    Port for Prometheus metrics endpoint.
    
    **Common Values:**
    - 9090: Prometheus default
    - 9100: Node Exporter default
    - 9091: Pushgateway default
    
    **Note:** Port is only accessible within the VPC (not exposed publicly)
    
    **Default:** 9090
    **Required when:** enable_agent_monitoring = true
  EOT
  type        = number
  default     = 9090

  validation {
    condition     = var.metrics_port > 0 && var.metrics_port <= 65535
    error_message = "metrics_port must be between 1 and 65535"
  }
}

# =============================================================================
