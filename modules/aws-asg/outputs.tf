output "asg_id" {
  description = "ID of the Auto Scaling Group"
  value       = aws_autoscaling_group.runner.id
}

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.runner.name
}

output "asg_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.runner.arn
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = aws_launch_template.runner.id
}

output "launch_template_latest_version" {
  description = "Latest version of the launch template"
  value       = aws_launch_template.runner.latest_version
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.runner.id
}

output "iam_role_arn" {
  description = "ARN of the IAM role"
  value       = aws_iam_role.runner.arn
}

output "iam_role_name" {
  description = "Name of the IAM role"
  value       = aws_iam_role.runner.name
}

output "instance_profile_arn" {
  description = "ARN of the instance profile"
  value       = aws_iam_instance_profile.runner.arn
}
