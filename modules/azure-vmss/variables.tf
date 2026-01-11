variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "vmss_name" {
  description = "Name of the VM Scale Set"
  type        = string
}

variable "vm_sku" {
  description = "VM SKU/size"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "use_spot_instances" {
  description = "Whether to use spot instances"
  type        = bool
  default     = true
}

variable "spot_max_price" {
  description = "Maximum price for spot instances (-1 for pay as you go up to on-demand)"
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

variable "admin_username" {
  description = "Admin username for VMs"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}

variable "custom_data" {
  description = "Cloud-init script or custom data for VM initialization"
  type        = string
}

variable "runner_count_per_vm" {
  description = "Number of runners per VM (0 = auto-detect based on vCPU count)"
  type        = number
  default     = 0
}

variable "docker_image" {
  description = "Docker image for runners"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet for VMSS"
  type        = string
}

variable "enable_accelerated_networking" {
  description = "Enable accelerated networking"
  type        = bool
  default     = true
}

variable "os_disk_size_gb" {
  description = "OS disk size in GB"
  type        = number
  default     = 100
}

variable "os_disk_type" {
  description = "OS disk type (Standard_LRS, StandardSSD_LRS, Premium_LRS)"
  type        = string
  default     = "StandardSSD_LRS"
}

variable "os_disk_size_gb" {
  description = "OS disk size in GB"
  type        = number
  default     = 100
}

variable "disk_encryption_set_id" {
  description = "ID of the disk encryption set for encrypting managed disks (optional, uses platform-managed keys if not specified)"
  type        = string
  default     = null
}

variable "secure_vm_disk_encryption_set_id" {
  description = "ID of the disk encryption set for secure VMs (optional)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "upgrade_mode" {
  description = "VMSS upgrade mode (Manual, Automatic, Rolling)"
  type        = string
  default     = "Manual"
}

variable "health_probe_id" {
  description = "Optional health probe ID for load balancer"
  type        = string
  default     = null
}

variable "zones" {
  description = "Availability zones for VMSS"
  type        = list(string)
  default     = ["1", "2", "3"]
}

variable "source_image_reference" {
  description = "Source image reference"
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}
