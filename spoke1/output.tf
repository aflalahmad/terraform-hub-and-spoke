output "resource_group_id" {
  description = "The ID of the Azure resource group."
  value = azurerm_resource_group.rg.id
}

output "virtual_network_ids" {
  description = "Map of virtual network names to their IDs."
  value = {
    for vnet_key, vnet in azurerm_virtual_network.vnets :
    vnet_key => vnet.id
  }
}

output "subnet_ids" {
  description = "Map of subnet names to their IDs."
  value = {
    for subnet_key, subnet in azurerm_subnet.subnets :
    subnet_key => subnet.id
  }
}

output "network_security_group_ids" {
  description = "Map of network security group names to their IDs."
  value = {
    for nsg_key, nsg in azurerm_network_security_group.nsg :
    nsg_key => nsg.id
  }
}

output "network_interface_ids" {
  description = "Map of network interface names to their IDs."
  value = {
    for nic_key, nic in azurerm_network_interface.nic :
    nic_key => nic.id
  }
}

output "availability_set_id" {
  description = "The ID of the availability set."
  value = azurerm_availability_set.availability_set.id
}

output "virtual_machine_ids" {
  description = "Map of virtual machine names to their IDs."
  value = {
    for vm_key, vm in azurerm_virtual_machine.vm :
    vm_key => vm.id
  }
}

output "recovery_services_vault_id" {
  description = "The ID of the Azure Recovery Services Vault."
  value = azurerm_recovery_services_vault.rsv.id
}

output "backup_policy_id" {
  description = "The ID of the backup policy."
  value = azurerm_backup_policy_vm.backup_policy.id
}

output "storage_account_id" {
  description = "The ID of the Azure Storage Account."
  value = azurerm_storage_account.stgacc.id
}

output "key_vault_id" {
  description = "The ID of the Azure Key Vault."
  value = azurerm_key_vault.kv.id
}

output "log_analytics_workspace_id" {
  description = "The ID of the Azure Log Analytics Workspace."
  value = azurerm_log_analytics_workspace.log_analytics.id
}

output "network_watcher_id" {
  description = "The ID of the Azure Network Watcher."
  value = azurerm_network_watcher.network_watcher.id
}
