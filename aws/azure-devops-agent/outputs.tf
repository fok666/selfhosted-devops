output "vpc_id" {
  description = "VPC ID"
  value       = local.vpc_id
}

output "subnet_ids" {
  description = "Subnet IDs"
  value       = local.subnet_ids
}

output "security_group_id" {
  description = "Security group ID"
  value       = local.security_group_id
}

output "asg_name" {
  description = "Auto Scaling Group name"
  value       = module.agent_asg.asg_name
}

output "asg_arn" {
  description = "Auto Scaling Group ARN"
  value       = module.agent_asg.asg_arn
}

output "launch_template_id" {
  description = "Launch template ID"
  value       = module.agent_asg.launch_template_id
}

output "iam_role_name" {
  description = "IAM role name"
  value       = aws_iam_role.agent.name
}

output "iam_role_arn" {
  description = "IAM role ARN"
  value       = aws_iam_role.agent.arn
}

output "azure_devops_pool" {
  description = "Azure DevOps agent pool name"
  value       = var.azp_pool
}

output "quick_commands" {
  description = "Useful management commands"
  value = {
    list_instances  = "aws autoscaling describe-auto-scaling-instances --query 'AutoScalingInstances[?AutoScalingGroupName==`${module.agent_asg.asg_name}`]' --output table"
    scale_manual    = "aws autoscaling set-desired-capacity --auto-scaling-group-name ${module.agent_asg.asg_name} --desired-capacity <number>"
    view_activity   = "aws autoscaling describe-scaling-activities --auto-scaling-group-name ${module.agent_asg.asg_name} --max-records 10"
    ssh_to_instance = "aws ssm start-session --target <instance-id>"
    view_logs       = "aws logs tail /aws/ec2/azure-devops-agent --follow"
  }
}

output "monitoring_urls" {
  description = "CloudWatch monitoring URLs"
  value = {
    asg_metrics   = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#alarmsV2:alarm/${module.agent_asg.asg_name}"
    ec2_metrics   = "https://console.aws.amazon.com/ec2/v2/home?region=${var.aws_region}#Instances:tag:aws:autoscaling:groupName=${module.agent_asg.asg_name}"
    cost_explorer = "https://console.aws.amazon.com/cost-management/home?region=${var.aws_region}#/cost-explorer"
  }
}
