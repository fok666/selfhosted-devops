output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = module.github_runner_asg.asg_name
}

output "asg_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = module.github_runner_asg.asg_arn
}

output "security_group_id" {
  description = "ID of the security group"
  value       = module.github_runner_asg.security_group_id
}

output "iam_role_name" {
  description = "Name of the IAM role"
  value       = module.github_runner_asg.iam_role_name
}

output "runner_info" {
  description = "GitHub runner information"
  value = {
    github_url          = var.github_url
    runner_labels       = var.runner_labels
    docker_image        = var.docker_image
    instance_type       = var.instance_type
    spot_enabled        = var.use_spot_instances
    spot_instance_types = var.spot_instance_types
  }
}
