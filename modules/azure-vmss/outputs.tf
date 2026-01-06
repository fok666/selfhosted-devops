output "vmss_id" {
  description = "ID of the VM Scale Set"
  value       = azurerm_linux_virtual_machine_scale_set.vmss.id
}

output "vmss_name" {
  description = "Name of the VM Scale Set"
  value       = azurerm_linux_virtual_machine_scale_set.vmss.name
}

output "vmss_principal_id" {
  description = "Principal ID of the system-assigned managed identity"
  value       = azurerm_linux_virtual_machine_scale_set.vmss.identity[0].principal_id
}

output "vmss_unique_id" {
  description = "Unique ID of the VM Scale Set"
  value       = azurerm_linux_virtual_machine_scale_set.vmss.unique_id
}

output "autoscale_setting_id" {
  description = "ID of the autoscale setting"
  value       = azurerm_monitor_autoscale_setting.vmss_autoscale.id
}
