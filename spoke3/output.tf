output "resource_group_name" {
  description = "The name of the Azure resource group."
  value = azurerm_resource_group.rg.name
}

output "app_service_plan_id" {
  description = "The ID of the Azure App Service Plan."
  value = azurerm_app_service_plan.appservice_plan.id
}

output "app_service_id" {
  description = "The ID of the Azure App Service."
  value = azurerm_app_service.app_service.id
}

output "app_service_default_hostname" {
  description = "The default hostname of the Azure App Service."
  value = azurerm_app_service.app_service.default_site_hostname
}

output "app_service_outbound_ips" {
  description = "The outbound IP addresses of the Azure App Service."
  value = azurerm_app_service.app_service.outbound_ip_addresses
}

output "app_service_inbound_ips" {
  description = "The inbound IP addresses of the Azure App Service."
  value = azurerm_app_service.app_service.inbound_ip_addresses
}

output "app_service_site_credential" {
  description = "The site credentials of the Azure App Service."
  value = azurerm_app_service.app_service.site_credential
}

output "app_service_identity" {
  description = "The managed service identity of the Azure App Service."
  value = azurerm_app_service.app_service.identity
}
