output "resource_group_id" {
  value = azurerm_resource_group.rg.id
}

output "virtual_network_ids" {
  value = {
    for vnet_key, vnet in azurerm_virtual_network.vnets :
    vnet_key => vnet.id
  }
}

output "subnet_ids" {
  value = {
    for subnet_key, subnet in azurerm_subnet.subnets :
    subnet_key => subnet.id
  }
}

output "network_security_group_ids" {
  value = {
    for nsg_key, nsg in azurerm_network_security_group.nsg :
    nsg_key => nsg.id
  }
}

output "network_interface_ids" {
  value = {
    for nic_key, nic in azurerm_network_interface.nic :
    nic_key => nic.id
  }
}

output "availability_set_id" {
  value = azurerm_availability_set.availability_set.id
}

output "virtual_machine_ids" {
  value = {
    for vm_key, vm in azurerm_virtual_machine.vm :
    vm_key => vm.id
  }
}

output "recovery_services_vault_id" {
  value = azurerm_recovery_services_vault.rsv.id
}

output "backup_policy_id" {
  value = azurerm_backup_policy_vm.backup_policy.id
}

output "storage_account_id" {
  value = azurerm_storage_account.stgacc.id
}

output "key_vault_id" {
  value = azurerm_key_vault.kv.id
}

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.log_analytics.id
}

output "network_watcher_id" {
  value = azurerm_network_watcher.network_watcher.id
}
