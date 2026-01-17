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

variable "instance_count_per_vm" {
  description = <<-EOT
    Number of Azure DevOps agents per VM (0 = auto-detect based on vCPU count).
    
    Cost/Performance Tradeoff:
    - Lower values (1-2): More stable, easier to manage, better isolation
    - Higher values (4+): Better resource utilization, lower cost per agent
    - Auto (0): Optimal for varying workloads, matches vCPU count
    
    Default: 0 (auto-detect - balances cost and performance)
  EOT
  type        = number
  default     = 0
}

variable "enable_ssh_access" {
  description = "Enable SSH access to VMs (not recommended for production)"
  type        = bool
  default     = false
}

variable "ssh_source_address_prefixes" {
  description = "Source address prefixes allowed for SSH (only used if enable_ssh_access is true)"
  type        = list(string)
  default     = []

  validation {
    condition     = var.enable_ssh_access == false || length(var.ssh_source_address_prefixes) > 0
    error_message = "ssh_source_address_prefixes must be provided when enable_ssh_access is true. Use specific CIDR blocks, not '*' or 'Internet'."
  }
}

variable "nsg_outbound_internet_access" {
  description = <<-EOT
    Allow outbound internet access from Network Security Group - USE WITH UNDERSTANDING.
    
    Default true allows outbound traffic, which is required for:
    - Connecting to Azure DevOps (dev.azure.com)
    - Pulling Docker images from public registries
    - Downloading packages and dependencies
    - Accessing public APIs and services
    
    Security Considerations:
    ✓ RECOMMENDED for most CI/CD use cases (default: true)
    ⚠️ Set to false only if you have alternative outbound connectivity (NAT Gateway, Azure Firewall)
    ⚠️ Consider using NSG Flow Logs for monitoring outbound traffic
    ⚠️ Use Azure Firewall or Network Virtual Appliance for URL-based filtering
    
    When false:
    - No default outbound internet access
    - Must configure NAT Gateway or Azure Firewall for outbound connectivity
    - Will break Azure DevOps Agent functionality if not properly configured
    - More secure but requires additional infrastructure
    
    Default: true (allows outbound internet - required for Azure DevOps)
  EOT
  type        = bool
  default     = true
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
  description = <<-EOT
    Azure VM size/SKU.
    
    Cost/Performance Tradeoffs:
    - Standard_B2s: Lowest cost (~$30/mo), burstable CPU, good for light workloads
    - Standard_D2s_v3: Balanced cost/performance (~$70/mo), consistent CPU (RECOMMENDED)
    - Standard_D4s_v3: Higher performance (~$140/mo), 4 vCPUs, for compute-intensive jobs
    - Standard_F4s_v2: Compute-optimized (~$150/mo), best CPU performance
    
    Default: Standard_D2s_v3 (balanced cost and consistent performance)
  EOT
  type        = string
  default     = "Standard_D2s_v3"

  validation {
    condition     = can(regex("^Standard_", var.vm_sku))
    error_message = "VM SKU must start with 'Standard_'"
  }
}

variable "use_spot_instances" {
  description = <<-EOT
    Use Azure Spot instances for significant cost savings (up to 90% discount).
    
    Cost/Reliability Tradeoff:
    - true: 60-90% cost savings, but instances can be evicted with 30s notice
    - false: Higher cost, guaranteed availability, predictable performance
    
    Recommendation: true for dev/test, false for critical production pipelines
    Default: true (optimized for cost)
  EOT
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

# OS and Disk Configuration
variable "source_image_reference" {
  description = <<-EOT
    Source image reference for VMs.
    Default: Ubuntu 24.04 LTS (latest stable, long-term support until 2029)
  EOT
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}

variable "os_disk_size_gb" {
  description = <<-EOT
    OS disk size in GB.
    
    Cost/Performance Tradeoff:
    - 64GB: Lowest cost, sufficient for most CI/CD workloads (RECOMMENDED)
    - 128GB: Better for workloads with large Docker images/build artifacts
    - 256GB+: For very large monorepos or extensive caching
    
    Note: Larger disks cost more (~$5-10/month per 64GB)
    Default: 64 (optimized for cost while meeting typical needs)
  EOT
  type        = number
  default     = 64

  validation {
    condition     = var.os_disk_size_gb >= 30 && var.os_disk_size_gb <= 4096
    error_message = "OS disk size must be between 30 GB and 4096 GB"
  }
}

variable "os_disk_type" {
  description = <<-EOT
    OS disk storage type.
    
    Cost/Performance Tradeoff:
    - Standard_LRS: Lowest cost (~$2/mo for 64GB), HDD, slowest (not recommended)
    - StandardSSD_LRS: Balanced cost (~$5/mo for 64GB), good performance (RECOMMENDED)
    - Premium_LRS: Higher cost (~$10/mo for 64GB), best performance, SSD
    - Premium_ZRS: Highest cost, zone-redundant, maximum durability
    
    Default: StandardSSD_LRS (best balance of cost, performance, and reliability)
  EOT
  type        = string
  default     = "StandardSSD_LRS"

  validation {
    condition     = contains(["Standard_LRS", "StandardSSD_LRS", "Premium_LRS", "StandardSSD_ZRS", "Premium_ZRS"], var.os_disk_type)
    error_message = "OS disk type must be one of: Standard_LRS, StandardSSD_LRS, Premium_LRS, StandardSSD_ZRS, Premium_ZRS"
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
