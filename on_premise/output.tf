output "resource_group_id" {
  value = azurerm_resource_group.rg.id
}

output "virtual_network_id" {
  value = azurerm_virtual_network.onprem_vnets.id
}

output "subnet_ids" {
  value = {
    for subnet_name, subnet in azurerm_subnet.onprem_vnetgateway_subnet :
    subnet_name => subnet.id
  }
}

output "public_ip_id" {
  value = azurerm_public_ip.onprem_vnetgateway_pip.id
}

output "virtual_network_gateway_ids" {
  value = {
    for subnet_name, gateway in azurerm_virtual_network_gateway.onprem_vnetgateway :
    subnet_name => gateway.id
  }
}

output "local_network_gateway_id" {
  value = azurerm_local_network_gateway.onprem_local_network_gateway.id
}

output "vpn_connection_ids" {
  value = {
    for subnet_name, connection in azurerm_virtual_network_gateway_connection.onprem_vpn_connection :
    subnet_name => connection.id
  }
}
