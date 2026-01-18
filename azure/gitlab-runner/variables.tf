variable "project_name" {
  description = "Project name (used as prefix for resources)"
  type        = string
  default     = "gitlab-runner"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "East US"
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
  default     = "docker,linux,azure,spot"
}

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
  description = "Maximum price for spot instances (-1 for on-demand price)"
  type        = number
  default     = -1
}

variable "min_instances" {
  description = "Minimum number of instances"
  type        = number
  default     = 0
}

variable "max_instances" {
  description = "Maximum number of instances"
  type        = number
  default     = 10
}

variable "default_instances" {
  description = "Default number of instances"
  type        = number
  default     = 1
}

variable "runner_count_per_instance" {
  description = <<-EOT
    Number of GitLab runners per VM/instance (0 = auto-detect based on vCPU count).
    
    Cost/Performance Tradeoff:
    - Lower values (1-2): More stable, easier to manage, better isolation
    - Higher values (4+): Better resource utilization, lower cost per runner
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
    
    Default true allows all outbound traffic, which is typically required for:
    - Connecting to GitLab (gitlab.com or your GitLab instance)
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
    - May break GitLab Runner functionality if not properly configured
    - More secure but requires additional infrastructure
    
    Default: true (allows outbound internet - required for typical CI/CD)
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

# trivy:ignore:AVD-AZU-0047 "Unrestricted outbound internet required for CI/CD: GitLab, Docker Hub, package repos, etc."
# tfsec:ignore:azure-network-no-public-egress "CI/CD runners require internet access for typical operations"
variable "nsg_outbound_destination_address_prefix" {
  description = <<-EOT
    Destination address prefix for default NSG outbound rule - USE WITH UNDERSTANDING.
    
    Default "Internet" allows outbound to any internet address, required for:
    - Connecting to GitLab (gitlab.com or your GitLab instance)
    - Pulling Docker images from public registries
    - Downloading packages and dependencies
    
    Security Considerations:
    - "Internet": All internet addresses (RECOMMENDED for CI/CD)
    - Specific CIDR: Restrict to specific IP ranges (advanced, may break CI/CD)
    - Service Tag: Use Azure Service Tags (e.g., "Internet")
    
    Default: "Internet" (required for typical CI/CD)
  EOT
  type        = string
  default     = "Internet"
}

variable "docker_image" {
  description = "Docker image for GitLab runner"
  type        = string
  default     = "fok666/gitlab-runner:latest"
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
  description = "Address space for new VNet (only used when create_vnet = true, CIDR notation)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_address_prefix" {
  description = "Address prefix for new subnet (only used when create_subnet = true, CIDR notation)"
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

# OS and Disk Configuration
variable "zones" {
  description = "Availability zones for VMSS (improves availability, may increase cost slightly)"
  type        = list(string)
  default     = ["1", "2", "3"]
}

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
    Enable distributed caching using Azure Blob Storage for shared cache across ephemeral runners.
    
    ✨ NEW PRODUCTION FEATURE
    
    **Benefits:**
    - ✓ 2-5x faster builds (shared cache across ephemeral runners)
    - ✓ Consistent performance even when instances are replaced
    - ✓ Reduces bandwidth and package download costs
    - ✓ Works with autoscaling and spot instances
    
    **Cost Impact:**
    - Blob Storage: ~$0.018/GB/month (Hot tier)
    - Typical usage: 10-50 GB = $0.18-$0.90/month
    - Transactions: ~$0.0004 per 10,000 operations
    - Total estimated cost: $2-10/month for typical workloads
    
    **When to Enable:**
    - ✓ Production deployments with frequent builds
    - ✓ Large codebases with significant dependencies
    - ✓ Teams prioritizing build speed
    
    **Default:** false (backward compatible)
    **Requires:** Storage account, container, IAM permissions
    **See:** PRODUCTION_FEATURES.md for setup guide
  EOT
  type        = bool
  default     = false
}

variable "cache_type" {
  description = <<-EOT
    Cache storage type for GitLab Runner distributed caching.
    
    **Supported Values:**
    - azurerm: Azure Blob Storage (RECOMMENDED for Azure deployments)
    
    **Default:** "azurerm"
  EOT
  type        = string
  default     = "azurerm"

  validation {
    condition     = contains(["azurerm"], var.cache_type)
    error_message = "cache_type must be 'azurerm' for Azure deployments"
  }
}

variable "cache_storage_account_name" {
  description = <<-EOT
    Name of the Azure Storage Account for distributed caching.
    
    **Requirements:**
    - Storage account must exist before deployment
    - Must be in the same region as runners for best performance
    - Must be globally unique, 3-24 lowercase alphanumeric characters
    - Requires appropriate RBAC permissions
    
    **Example:** "myglcachestorage"
    
    **Required if:** enable_distributed_cache = true
  EOT
  type        = string
  default     = ""

  validation {
    condition     = !var.enable_distributed_cache || (var.enable_distributed_cache && var.cache_storage_account_name != "")
    error_message = "cache_storage_account_name is required when enable_distributed_cache is true"
  }
}

variable "cache_storage_container_name" {
  description = <<-EOT
    Name of the blob container for caching.
    
    **Best Practice:** Use descriptive name like "gitlab-runner-cache"
    
    **Note:** Container will be created if it doesn't exist
    
    **Default:** "runner-cache"
  EOT
  type        = string
  default     = "runner-cache"
}

variable "cache_storage_account_key" {
  description = <<-EOT
    Storage account access key for authentication.
    
    **Security:** Mark as sensitive, use Azure Key Vault in production
    
    **Alternative:** Use managed identity (future enhancement)
    
    **Required if:** enable_distributed_cache = true
  EOT
  type        = string
  default     = ""
  sensitive   = true

  validation {
    condition     = !var.enable_distributed_cache || (var.enable_distributed_cache && var.cache_storage_account_key != "")
    error_message = "cache_storage_account_key is required when enable_distributed_cache is true"
  }
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
    Enable centralized logging using Azure Log Analytics for runner logs and job output.
    
    ✨ NEW PRODUCTION FEATURE
    
    **Benefits:**
    - ✓ Essential for troubleshooting ephemeral runners
    - ✓ Long-term log retention (30-730 days)
    - ✓ Advanced search with KQL (Kusto Query Language)
    - ✓ Integration with Azure Monitor
    - ✓ Alerting on errors and anomalies
    
    **Cost Impact:**
    - Data ingestion: ~$2.76/GB
    - Data retention (first 31 days): Free
    - Extended retention: ~$0.12/GB/month
    - Typical usage: 2-10 GB/month = $5.52-$27.60/month
    - Total estimated cost: $10-40/month for typical workloads
    
    **When to Enable:**
    - ✓ Production deployments requiring audit trail
    - ✓ Compliance requirements (SOC2, ISO27001)
    - ✓ Teams needing advanced troubleshooting
    - ✓ Large teams with many concurrent jobs
    
    **Default:** false (backward compatible)
    **Requires:** Log Analytics workspace, RBAC permissions
    **See:** PRODUCTION_FEATURES.md for setup guide
  EOT
  type        = bool
  default     = false
}

variable "log_analytics_workspace_id" {
  description = <<-EOT
    Azure Log Analytics Workspace ID for centralized logging.
    
    **Format:** Full resource ID like:
    /subscriptions/{subscription-id}/resourceGroups/{rg-name}/providers/Microsoft.OperationalInsights/workspaces/{workspace-name}
    
    **Required if:** enable_centralized_logging = true
  EOT
  type        = string
  default     = ""

  validation {
    condition     = !var.enable_centralized_logging || (var.enable_centralized_logging && var.log_analytics_workspace_id != "")
    error_message = "log_analytics_workspace_id is required when enable_centralized_logging is true"
  }
}

variable "log_analytics_workspace_key" {
  description = <<-EOT
    Azure Log Analytics Workspace primary or secondary key.
    
    **Security:** Marked as sensitive, use Azure Key Vault in production
    
    **Required if:** enable_centralized_logging = true
  EOT
  type        = string
  default     = ""
  sensitive   = true

  validation {
    condition     = !var.enable_centralized_logging || (var.enable_centralized_logging && var.log_analytics_workspace_key != "")
    error_message = "log_analytics_workspace_key is required when enable_centralized_logging is true"
  }
}

variable "log_retention_days" {
  description = <<-EOT
    Number of days to retain logs in Log Analytics workspace.
    
    **Common Values:**
    - 30: One month (FREE with workspace, RECOMMENDED)
    - 90: Three months (compliance, ~$0.12/GB/month)
    - 180: Six months (extended compliance)
    - 365: One year (strict compliance)
    - 730: Two years (regulatory requirements)
    
    **Cost Impact:**
    - 0-31 days: Included with workspace (free)
    - 31+ days: ~$0.12/GB/month for extended retention
    
    **Default:** 30 days (free tier)
  EOT
  type        = number
  default     = 30

  validation {
    condition     = var.log_retention_days >= 30 && var.log_retention_days <= 730
    error_message = "log_retention_days must be between 30 and 730 days"
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
    - ✓ Integration with Grafana, Azure Monitor, Datadog
    - ✓ Proactive alerting on issues
    - ✓ Capacity planning insights
    
    **Cost Impact:**
    - Azure Monitor metrics: ~$0.25/metric/month
    - Typical usage: 10-30 custom metrics = $2.50-$7.50/month
    - Total estimated cost: Minimal (included in infrastructure)
    
    **When to Enable:**
    - ✓ Production deployments
    - ✓ Teams requiring SLA tracking
    - ✓ Organizations with existing monitoring stack
    
    **Default:** false (backward compatible)
    **Requires:** Network security rule for metrics port
    **See:** PRODUCTION_FEATURES.md for Grafana integration
  EOT
  type        = bool
  default     = false
}

variable "metrics_port" {
  description = <<-EOT
    Port for Prometheus metrics endpoint.
    
    **Default:** 9252 (GitLab Runner metrics port)
    
    **Security:** Ensure this port is only accessible from your monitoring infrastructure
  EOT
  type        = number
  default     = 9252

  validation {
    condition     = var.metrics_port >= 1024 && var.metrics_port <= 65535
    error_message = "metrics_port must be between 1024 and 65535"
  }
}
