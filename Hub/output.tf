output "resource_group_id" {
  value = azurerm_resource_group.rg.id
}

output "virtual_network_id" {
  value = azurerm_virtual_network.hubvnets.id
}

output "subnet_ids" {
  value = {
    for subnet_name, subnet in azurerm_subnet.subnet :
    subnet_name => subnet.id
  }
}

output "public_ip_ids" {
  value = {
    for publicip_name, publicip in azurerm_public_ip.publi_ips :
    publicip_name => publicip.id
  }
}

output "bastion_host_id" {
  value = azurerm_bastion_host.example.id
}

output "virtual_network_gateway_id" {
  value = azurerm_virtual_network_gateway.vnetgateway.id
}

output "firewall_id" {
  value = azurerm_firewall.firewall.id
}

output "app_service_vnet_integration_id" {
  value = azurerm_app_service_virtual_network_swift_connection.vnet_integration.id
}

output "local_network_gateway_id" {
  value = azurerm_local_network_gateway.hub_local_network_gateway.id
}

output "vpn_connection_id" {
  value = azurerm_virtual_network_gateway_connection.onprem_vpn_connection.id
}
