variable "project_name" {
  description = "Project name (used as prefix for resources)"
  type        = string
  default     = "github-runner"
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
  default     = "self-hosted,linux,x64,aws,spot"
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
  description = "Number of GitHub runners per instance (0 = auto-detect based on vCPU)"
  type        = number
  default     = 0
}

variable "docker_image" {
  description = "Docker image for GitHub runner"
  type        = string
  default     = "fok666/github-runner:latest"
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

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "Production"
    Application = "GitHub-Runner"
    ManagedBy   = "Terraform"
  }
}
