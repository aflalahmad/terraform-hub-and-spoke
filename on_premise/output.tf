output "resource_group_id" {
  description = "The ID of the Azure resource group."
  value = azurerm_resource_group.rg.id
}

output "virtual_network_id" {
  description = "The ID of the on-premises virtual network."
  value = azurerm_virtual_network.onprem_vnets.id
}

output "subnet_ids" {
  description = "Map of subnet names to their IDs in the on-premises virtual network."
  value = {
    for subnet_name, subnet in azurerm_subnet.subnets  :
    subnet_name => subnet.id
  }
}

output "public_ip_id" {
  description = "The ID of the public IP address associated with the on-premises virtual network gateway."
  value = azurerm_public_ip.onprem_vnetgateway_pip.id
}

output "virtual_network_gateway_ids" {
  description = "Map of subnet names to their IDs for on-premises virtual network gateways."
  value = azurerm_virtual_network_gateway.onprem_vnetgateway.id
}

output "local_network_gateway_id" {
  description = "The ID of the local network gateway for on-premises connections."
  value = azurerm_local_network_gateway.onprem_local_network_gateway.id
}

output "vpn_connection_ids" {
  description = "Map of subnet names to their IDs for VPN connections to on-premises network."
  value = {
    for subnet_name, connection in azurerm_virtual_network_gateway_connection.onprem_vpn_connection :
    subnet_name => connection.id
  }
}
