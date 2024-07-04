output "resource_group_id" {
  description = "The ID of the Azure resource group."
  value = azurerm_resource_group.rg.id
}

output "virtual_network_id" {
  description = "The ID of the virtual network in the hub."
  value = azurerm_virtual_network.hubvnets.id
}

output "subnet_ids" {
  description = "Map of subnet names to their IDs in the virtual network."
  value = {
    for subnet_name, subnet in azurerm_subnet.subnet :
    subnet_name => subnet.id
  }
}

output "public_ip_ids" {
  description = "Map of public IP names to their IDs."
  value = {
    for publicip_name, publicip in azurerm_public_ip.publi_ips :
    publicip_name => publicip.id
  }
}

output "bastion_host_id" {
  description = "The ID of the Azure Bastion host."
  value = azurerm_bastion_host.example.id
}

output "virtual_network_gateway_id" {
  description = "The ID of the virtual network gateway."
  value = azurerm_virtual_network_gateway.vnetgateway.id
}

output "firewall_id" {
  description = "The ID of the Azure Firewall."
  value = azurerm_firewall.firewall.id
}

output "app_service_vnet_integration_id" {
  description = "The ID of the virtual network integration for the App Service."
  value = azurerm_app_service_virtual_network_swift_connection.vnet_integration.id
}

output "local_network_gateway_id" {
  description = "The ID of the local network gateway for on-premises connections."
  value = azurerm_local_network_gateway.hub_local_network_gateway.id
}

output "vpn_connection_id" {
  description = "The ID of the VPN connection to on-premises network."
  value = azurerm_virtual_network_gateway_connection.onprem_vpn_connection.id
}
