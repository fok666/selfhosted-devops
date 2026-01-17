variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the Auto Scaling Group"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the Auto Scaling Group"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "use_spot_instances" {
  description = "Whether to use spot instances"
  type        = bool
  default     = true
}

variable "spot_max_price" {
  description = "Maximum price for spot instances (empty for on-demand price)"
  type        = string
  default     = ""
}

variable "spot_instance_types" {
  description = "List of instance types for spot instances (for diversification)"
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

variable "ami_id" {
  description = "AMI ID for instances (defaults to latest Ubuntu 22.04 LTS)"
  type        = string
  default     = "" # Will use data source if empty
}

variable "key_name" {
  description = "EC2 key pair name for SSH access"
  type        = string
  default     = ""
}

variable "user_data" {
  description = "User data script for instance initialization"
  type        = string
}

variable "runner_count_per_instance" {
  description = <<-EOT
    Number of runners per EC2 instance. Set to 0 for auto-detection based on vCPU count.
    
    **Resource Allocation:**
    - 0 = Auto-detect (recommended): Uses number of vCPUs
    - 1 = Dedicated: One runner with full instance resources
    - 2+ = Shared: Multiple runners sharing instance resources
    
    **Cost/Performance Tradeoff:**
    - Higher count = Better instance utilization = Lower cost per runner
    - Lower count = More resources per runner = Better performance
    
    **Default:** 0 (auto-detect based on vCPU count)
  EOT
  type        = number
  default     = 0
}

variable "docker_image" {
  description = "Docker image for runners"
  type        = string
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 100
}

variable "root_volume_type" {
  description = "Root volume type (gp3, gp2, io1, io2)"
  type        = string
  default     = "gp3"
}

variable "enable_monitoring" {
  description = "Enable detailed monitoring"
  type        = bool
  default     = true
}

variable "health_check_type" {
  description = "Health check type (EC2 or ELB)"
  type        = string
  default     = "EC2"
}

variable "health_check_grace_period" {
  description = "Health check grace period in seconds"
  type        = number
  default     = 300
}

variable "termination_policies" {
  description = "List of termination policies"
  type        = list(string)
  default     = ["OldestInstance", "Default"]
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "enable_imdsv2" {
  description = <<-EOT
    Enable IMDSv2 (Instance Metadata Service v2) - STRONGLY RECOMMENDED.
    IMDSv2 requires session tokens for metadata access, protecting against SSRF attacks
    and unauthorized credential theft. Setting to false should only be done for legacy
    application compatibility. Default: true (secure)
  EOT
  type        = bool
  default     = true
}

variable "associate_public_ip_address" {
  description = <<-EOT
    Associate public IP addresses to instances - USE WITH CAUTION.
    Public IPs expose instances directly to the internet. Consider using NAT Gateway
    or VPC endpoints for internet access instead. Default: false (secure)
  EOT
  type        = bool
  default     = false
}

variable "ingress_cidr_blocks" {
  description = <<-EOT
    CIDR blocks for SSH ingress - ONLY USED IF KEY_NAME IS PROVIDED.
    Leave empty to disable SSH access (recommended). If SSH is required,
    specify restrictive CIDR blocks (e.g., your VPN or office IPs).
    NEVER use ["0.0.0.0/0"] - this exposes instances to the entire internet.
    Default: [] (secure - no SSH access)
  EOT
  type        = list(string)
  default     = []
}

variable "egress_cidr_blocks" {
  description = <<-EOT
    CIDR blocks for outbound traffic - USE WITH UNDERSTANDING.
    Default ["0.0.0.0/0"] allows all outbound traffic, which is typically required for:
    - Pulling Docker images from public registries
    - Downloading packages and dependencies
    - Connecting to CI/CD platforms (GitHub, GitLab, Azure DevOps)
    - Accessing public APIs and services
    
    Security Considerations:
    ✓ RECOMMENDED for most CI/CD use cases (default)
    ⚠️ Restrict if you have strict egress filtering requirements
    ⚠️ Use VPC endpoints for AWS services to keep traffic in AWS network
    ⚠️ Consider using NAT Gateway logs for monitoring outbound traffic
    
    To restrict egress (advanced):
    - Specify only required CIDR blocks (e.g., your private network ranges)
    - Use VPC endpoints for AWS services (S3, ECR, etc.)
    - Configure security groups for specific destination ports/protocols
    - May break CI/CD functionality if misconfigured
    
    Default: ["0.0.0.0/0"] (allows all outbound - required for typical CI/CD)
  EOT
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "egress_from_port" {
  description = <<-EOT
    Starting port for outbound traffic - USE WITH UNDERSTANDING.
    Default 0 with protocol "-1" allows all ports, which is typically required for CI/CD.
    
    Common port restrictions:
    - 443 only: HTTPS traffic only (may break some CI/CD operations)
    - 80,443: HTTP/HTTPS only
    - 0: All ports (default, required for typical CI/CD)
    
    Note: When protocol is "-1" (all), this must be 0.
    Default: 0 (all ports)
  EOT
  type        = number
  default     = 0
}

variable "egress_to_port" {
  description = <<-EOT
    Ending port for outbound traffic - USE WITH UNDERSTANDING.
    Default 0 with protocol "-1" allows all ports, which is typically required for CI/CD.
    
    Note: When protocol is "-1" (all), this must be 0.
    Default: 0 (all ports)
  EOT
  type        = number
  default     = 0
}

variable "egress_protocol" {
  description = <<-EOT
    Protocol for outbound traffic - USE WITH UNDERSTANDING.
    Default "-1" allows all protocols (TCP, UDP, ICMP, etc.), required for typical CI/CD.
    
    Common values:
    - "-1": All protocols (default, required for typical CI/CD)
    - "tcp": TCP only (port 6)
    - "udp": UDP only (port 17)
    - "icmp": ICMP only (port 1)
    
    Note: Use protocol numbers (6 for TCP, 17 for UDP) or "-1" for all.
    Default: "-1" (all protocols)
  EOT
  type        = string
  default     = "-1"
}

variable "capacity_rebalance" {
  description = "Enable capacity rebalancing for spot instances"
  type        = bool
  default     = true
}

variable "warm_pool_enabled" {
  description = "Enable warm pool for faster scaling"
  type        = bool
  default     = false
}

variable "warm_pool_min_size" {
  description = "Minimum size of warm pool"
  type        = number
  default     = 0
}
