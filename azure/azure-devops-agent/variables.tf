variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "azdevops-agent"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
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
  default     = "azure-agent"
}

# Networking
variable "vnet_address_space" {
  description = "Address space for VNet"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_address_prefix" {
  description = "Address prefix for subnet"
  type        = string
  default     = "10.0.1.0/24"
}

# VM Configuration
variable "vm_sku" {
  description = "Azure VM size"
  type        = string
  default     = "Standard_D2s_v3"

  validation {
    condition     = can(regex("^Standard_", var.vm_sku))
    error_message = "VM SKU must start with 'Standard_'"
  }
}

variable "use_spot_instances" {
  description = "Use Azure Spot instances for cost savings"
  type        = bool
  default     = true
}

variable "spot_max_price" {
  description = "Maximum price for spot instances (-1 for pay up to on-demand price)"
  type        = number
  default     = -1
}

variable "zones" {
  description = "Availability zones for VMSS"
  type        = list(string)
  default     = ["1", "2", "3"]
}

# Autoscaling Configuration
variable "enable_autoscaling" {
  description = "Enable autoscaling for VMSS"
  type        = bool
  default     = true
}

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

variable "scale_out_cpu_threshold" {
  description = "CPU threshold to scale out"
  type        = number
  default     = 75

  validation {
    condition     = var.scale_out_cpu_threshold > 0 && var.scale_out_cpu_threshold <= 100
    error_message = "CPU threshold must be between 1 and 100"
  }
}

variable "scale_in_cpu_threshold" {
  description = "CPU threshold to scale in"
  type        = number
  default     = 25

  validation {
    condition     = var.scale_in_cpu_threshold > 0 && var.scale_in_cpu_threshold <= 100
    error_message = "CPU threshold must be between 1 and 100"
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
