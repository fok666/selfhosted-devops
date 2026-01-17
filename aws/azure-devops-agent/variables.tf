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
