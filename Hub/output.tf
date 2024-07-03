output "rg" {
  value = azurerm_resource_group.rg
}
output "subnet" {
  value = azurerm_subnet.subnet
}
output "hubvnets" {
  value = azurerm_virtual_network.hubvnets
}
output "vnetgateway" {
  value = azurerm_virtual_network_gateway.vnetgateway
}