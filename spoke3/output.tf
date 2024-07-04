output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "app_service_plan_id" {
  value = azurerm_app_service_plan.appservice_plan.id
}

output "app_service_id" {
  value = azurerm_app_service.app_service.id
}

output "app_service_default_hostname" {
  value = azurerm_app_service.app_service.default_site_hostname
}

output "app_service_outbound_ips" {
  value = azurerm_app_service.app_service.outbound_ip_addresses
}

output "app_service_inbound_ips" {
  value = azurerm_app_service.app_service.inbound_ip_addresses
}

output "app_service_site_credential" {
  value = azurerm_app_service.app_service.site_credential
}

output "app_service_identity" {
  value = azurerm_app_service.app_service.identity
}
