output "resource_group_name" {
  description = "Resource group name"
  value       = azurerm_resource_group.agent.name
}

output "vmss_id" {
  description = "VMSS ID"
  value       = module.agent_vmss.vmss_id
}

output "vmss_name" {
  description = "VMSS name"
  value       = module.agent_vmss.vmss_name
}

output "vmss_principal_id" {
  description = "VMSS managed identity principal ID"
  value       = module.agent_vmss.vmss_principal_id
}

output "vnet_id" {
  description = "Virtual network ID"
  value       = azurerm_virtual_network.agent.id
}

output "subnet_id" {
  description = "Subnet ID"
  value       = azurerm_subnet.agent.id
}

output "nsg_id" {
  description = "Network security group ID"
  value       = azurerm_network_security_group.agent.id
}

output "ssh_private_key" {
  description = "SSH private key (sensitive)"
  value       = tls_private_key.agent.private_key_pem
  sensitive   = true
}

output "connection_command" {
  description = "Example SSH connection command"
  value       = "Save the private key and use: ssh -i agent-key.pem azureuser@<instance-ip>"
}

output "azure_devops_pool" {
  description = "Azure DevOps agent pool name"
  value       = var.azp_pool
}

output "quick_commands" {
  description = "Useful management commands"
  value = {
    list_instances  = "az vmss list-instances --resource-group ${azurerm_resource_group.agent.name} --name ${module.agent_vmss.vmss_name} --output table"
    scale_manual    = "az vmss scale --resource-group ${azurerm_resource_group.agent.name} --name ${module.agent_vmss.vmss_name} --new-capacity <number>"
    view_logs       = "az vmss get-instance-view --resource-group ${azurerm_resource_group.agent.name} --name ${module.agent_vmss.vmss_name} --instance-id <id>"
    ssh_to_instance = "az vmss list-instance-public-ips --resource-group ${azurerm_resource_group.agent.name} --name ${module.agent_vmss.vmss_name}"
  }
}
