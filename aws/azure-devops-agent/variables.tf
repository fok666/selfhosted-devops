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

# Networking
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
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
