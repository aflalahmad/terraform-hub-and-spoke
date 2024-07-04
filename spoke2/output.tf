output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "virtual_network_name" {
  value = azurerm_virtual_network.vnet.name
}

output "subnet_ids" {
  value = {
    for subnet_key, subnet in azurerm_subnet.subnets : subnet_key => subnet.id
  }
}

output "nsg_ids" {
  value = {
    for subnet_key, nsg in azurerm_network_security_group.nsg : subnet_key => nsg.id
  }
}

output "vmss_name" {
  value = azurerm_windows_virtual_machine_scale_set.vmss.name
}

output "vmss_instances" {
  value = azurerm_windows_virtual_machine_scale_set.vmss.instance_ids
}

output "subnet_associations" {
  value = {
    for subnet_key, subnet in azurerm_subnet.subnets : subnet_key => azurerm_subnet_network_security_group_association.nsg-association[subnet_key].id
  }
}

output "route_table_ids" {
  value = {
    spoke1_udr = azurerm_route_table.spoke1-udr.id
    spoke2_udr = azurerm_route_table.spoke2-udr.id
  }
}
