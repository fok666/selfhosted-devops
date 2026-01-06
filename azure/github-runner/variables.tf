variable "project_name" {
  description = "Project name (used as prefix for resources)"
  type        = string
  default     = "github-runner"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "East US"
}

variable "github_url" {
  description = "GitHub URL (e.g., https://github.com/owner/repo or https://github.com/organization)"
  type        = string
}

variable "github_token" {
  description = "GitHub runner registration token"
  type        = string
  sensitive   = true
}

variable "runner_labels" {
  description = "Comma-separated runner labels"
  type        = string
  default     = "self-hosted,linux,x64,azure,spot"
}

variable "vm_sku" {
  description = "Azure VM SKU"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "use_spot_instances" {
  description = "Use spot instances for cost savings"
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

variable "runner_count_per_vm" {
  description = "Number of GitHub runners per VM (0 = auto-detect based on vCPU)"
  type        = number
  default     = 0
}

variable "docker_image" {
  description = "Docker image for GitHub runner"
  type        = string
  default     = "fok666/github-runner:latest"
}

variable "os_disk_size_gb" {
  description = "OS disk size in GB"
  type        = number
  default     = 100
}

variable "os_disk_type" {
  description = "OS disk type"
  type        = string
  default     = "StandardSSD_LRS"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "Production"
    Application = "GitHub-Runner"
    ManagedBy   = "Terraform"
  }
}
