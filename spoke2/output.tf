output "resource_group_name" {
  description = "The name of the Azure resource group."
  value = azurerm_resource_group.rg.name
}

output "virtual_network_name" {
  description = "The name of the Azure virtual network."
  value = azurerm_virtual_network.vnet.name
}

output "subnet_ids" {
  description = "Map of subnet names to their IDs."
  value = {
    for subnet_key, subnet in azurerm_subnet.subnets : subnet_key => subnet.id
  }
}

output "nsg_ids" {
  description = "Map of network security group names to their IDs."
  value = {
    for subnet_key, nsg in azurerm_network_security_group.nsg : subnet_key => nsg.id
  }
}

output "vmss_name" {
  description = "The name of the Azure virtual machine scale set."
  value = azurerm_windows_virtual_machine_scale_set.vmss.name
}

output "vmss_instances" {
  description = "List of instance IDs in the Azure virtual machine scale set."
  value = azurerm_windows_virtual_machine_scale_set.vmss.instance_ids
}

