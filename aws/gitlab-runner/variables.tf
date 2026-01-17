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

variable "vpc_id" {
  description = "VPC ID (defaults to default VPC)"
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "Subnet IDs (defaults to all subnets in VPC)"
  type        = list(string)
  default     = []
}

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

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "Production"
    Application = "GitLab-Runner"
    ManagedBy   = "Terraform"
  }
}
