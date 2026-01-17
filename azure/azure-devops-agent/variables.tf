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

variable "runner_count_per_instance" {
  description = <<-EOT
    Number of Azure DevOps agents per VM/instance (0 = auto-detect based on vCPU count).
    
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

variable "nsg_outbound_protocol" {
  description = <<-EOT
    Protocol for default NSG outbound rule - USE WITH UNDERSTANDING.
    
    Security Best Practice: Use "Tcp" for HTTPS-only (port 443)
    Compatibility: Use "*" if your CI/CD requires multiple protocols
    
    Common values:
    - "Tcp": TCP only (RECOMMENDED - secure, covers HTTPS)
    - "*": All protocols (use only if required by your CI/CD workflow)
    
    Default: "Tcp" (secure by default, HTTPS-only)
  EOT
  type        = string
  default     = "Tcp"

  validation {
    condition     = contains(["Tcp", "Udp", "Icmp", "*"], var.nsg_outbound_protocol)
    error_message = "nsg_outbound_protocol must be one of: Tcp, Udp, Icmp, *"
  }
}

variable "nsg_outbound_destination_port_range" {
  description = <<-EOT
    Destination port range for default NSG outbound rule - USE WITH UNDERSTANDING.
    
    Security Best Practice: Use "443" for HTTPS-only
    Compatibility: Use "*" if your CI/CD requires multiple ports
    
    Common values:
    - "443": HTTPS only (RECOMMENDED - secure, covers most CI/CD)
    - "80,443": HTTP and HTTPS
    - "*": All ports (use only if required by your CI/CD workflow)
    
    Default: "443" (secure by default, HTTPS-only)
  EOT
  type        = string
  default     = "443"
}

variable "nsg_outbound_destination_address_prefix" {
  description = <<-EOT
    Destination address prefix for default NSG outbound rule - USE WITH UNDERSTANDING.
    
    Default "Internet" allows outbound to any internet address, required for:
    - Connecting to Azure DevOps (dev.azure.com)
    - Pulling Docker images from public registries
    - Downloading packages and dependencies
    
    Security Considerations:
    - "Internet": All internet addresses (RECOMMENDED for CI/CD)
    - Specific CIDR: Restrict to specific IP ranges (advanced, may break CI/CD)
    - Service Tag: Use Azure Service Tags (e.g., "AzureDevOps")
    
    Default: "Internet" (required for typical CI/CD)
  EOT
  type        = string
  default     = "Internet"
}

# =============================================================================
# Network Configuration
# =============================================================================

# Network Creation Flags
variable "create_vnet" {
  description = <<-EOT
    Create a new Virtual Network or use an existing one.
    
    - true: Create new VNet (default)
    - false: Use existing VNet (specify existing_vnet_name)
    
    Default: true
  EOT
  type        = bool
  default     = true
}

variable "create_subnet" {
  description = <<-EOT
    Create a new Subnet or use an existing one.
    
    - true: Create new subnet (default)
    - false: Use existing subnet (specify existing_subnet_name)
    
    Default: true
  EOT
  type        = bool
  default     = true
}

variable "create_nsg" {
  description = <<-EOT
    Create a new Network Security Group or use an existing one.
    
    - true: Create new NSG (default)
    - false: Use existing NSG (specify existing_nsg_name)
    
    Default: true
  EOT
  type        = bool
  default     = true
}

variable "create_nsg_association" {
  description = <<-EOT
    Associate Network Security Group with Subnet.
    
    - true: Associate NSG with subnet (default)
    - false: Skip association (useful if NSG is already associated)
    
    Default: true
  EOT
  type        = bool
  default     = true
}

# New Network Configuration (when creating new resources)
variable "vnet_address_space" {
  description = "Address space for new VNet (only used when create_vnet = true)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_address_prefix" {
  description = "Address prefix for new subnet (only used when create_subnet = true)"
  type        = string
  default     = "10.0.1.0/24"
}

# Existing Network Configuration (when using existing resources)
variable "existing_vnet_name" {
  description = "Name of existing VNet (required when create_vnet = false)"
  type        = string
  default     = ""

  validation {
    condition     = var.create_vnet || var.existing_vnet_name != ""
    error_message = "existing_vnet_name must be provided when create_vnet is false"
  }
}

variable "existing_vnet_resource_group_name" {
  description = <<-EOT
    Resource group name of existing VNet (optional, defaults to main resource group).
    Use this when the VNet is in a different resource group.
  EOT
  type        = string
  default     = ""
}

variable "existing_subnet_name" {
  description = "Name of existing subnet (required when create_subnet = false)"
  type        = string
  default     = ""

  validation {
    condition     = var.create_subnet || var.existing_subnet_name != ""
    error_message = "existing_subnet_name must be provided when create_subnet is false"
  }
}

variable "existing_nsg_name" {
  description = "Name of existing Network Security Group (required when create_nsg = false)"
  type        = string
  default     = ""

  validation {
    condition     = var.create_nsg || var.existing_nsg_name != ""
    error_message = "existing_nsg_name must be provided when create_nsg is false"
  }
}

variable "existing_nsg_resource_group_name" {
  description = <<-EOT
    Resource group name of existing NSG (optional, defaults to main resource group).
    Use this when the NSG is in a different resource group.
  EOT
  type        = string
  default     = ""
}

# Additional NSG Rules
variable "additional_nsg_rules" {
  description = <<-EOT
    Additional Network Security Group rules to create (only used when create_nsg = true).
    
    Example:
    [
      {
        name                         = "allow-https"
        priority                     = 200
        direction                    = "Inbound"
        access                       = "Allow"
        protocol                     = "Tcp"
        source_port_range            = "*"
        destination_port_range       = "443"
        source_address_prefix        = "*"
        destination_address_prefix   = "*"
        source_address_prefixes      = null
        destination_address_prefixes = null
      }
    ]
  EOT
  type = list(object({
    name                         = string
    priority                     = number
    direction                    = string
    access                       = string
    protocol                     = string
    source_port_range            = string
    destination_port_range       = string
    source_address_prefix        = string
    destination_address_prefix   = string
    source_address_prefixes      = list(string)
    destination_address_prefixes = list(string)
  }))
  default = []
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
