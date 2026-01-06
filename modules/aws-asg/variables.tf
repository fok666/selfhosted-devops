variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the Auto Scaling Group"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the Auto Scaling Group"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "use_spot_instances" {
  description = "Whether to use spot instances"
  type        = bool
  default     = true
}

variable "spot_max_price" {
  description = "Maximum price for spot instances (empty for on-demand price)"
  type        = string
  default     = ""
}

variable "spot_instance_types" {
  description = "List of instance types for spot instances (for diversification)"
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

variable "ami_id" {
  description = "AMI ID for instances (defaults to latest Ubuntu 22.04 LTS)"
  type        = string
  default     = "" # Will use data source if empty
}

variable "key_name" {
  description = "EC2 key pair name for SSH access"
  type        = string
  default     = ""
}

variable "user_data" {
  description = "User data script for instance initialization"
  type        = string
}

variable "runner_count_per_instance" {
  description = "Number of runners per instance (0 = auto-detect based on vCPU count)"
  type        = number
  default     = 0
}

variable "docker_image" {
  description = "Docker image for runners"
  type        = string
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 100
}

variable "root_volume_type" {
  description = "Root volume type (gp3, gp2, io1, io2)"
  type        = string
  default     = "gp3"
}

variable "enable_monitoring" {
  description = "Enable detailed monitoring"
  type        = bool
  default     = true
}

variable "health_check_type" {
  description = "Health check type (EC2 or ELB)"
  type        = string
  default     = "EC2"
}

variable "health_check_grace_period" {
  description = "Health check grace period in seconds"
  type        = number
  default     = 300
}

variable "termination_policies" {
  description = "List of termination policies"
  type        = list(string)
  default     = ["OldestInstance", "Default"]
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "enable_imdsv2" {
  description = "Enable IMDSv2 (recommended for security)"
  type        = bool
  default     = true
}

variable "associate_public_ip_address" {
  description = "Associate public IP address to instances"
  type        = bool
  default     = false
}

variable "ingress_cidr_blocks" {
  description = "CIDR blocks for SSH ingress"
  type        = list(string)
  default     = []
}

variable "capacity_rebalance" {
  description = "Enable capacity rebalancing for spot instances"
  type        = bool
  default     = true
}

variable "warm_pool_enabled" {
  description = "Enable warm pool for faster scaling"
  type        = bool
  default     = false
}

variable "warm_pool_min_size" {
  description = "Minimum size of warm pool"
  type        = number
  default     = 0
}
