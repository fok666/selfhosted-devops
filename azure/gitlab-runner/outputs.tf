output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.runner.name
}

output "vmss_id" {
  description = "ID of the VM Scale Set"
  value       = module.gitlab_runner_vmss.vmss_id
}

output "vmss_name" {
  description = "Name of the VM Scale Set"
  value       = module.gitlab_runner_vmss.vmss_name
}

output "ssh_private_key" {
  description = "SSH private key for VM access (keep secure!)"
  value       = tls_private_key.runner.private_key_pem
  sensitive   = true
}

output "runner_info" {
  description = "GitLab runner information"
  value = {
    gitlab_url   = var.gitlab_url
    runner_tags  = var.runner_tags
    docker_image = var.docker_image
    vm_sku       = var.vm_sku
    spot_enabled = var.use_spot_instances
  }
}
