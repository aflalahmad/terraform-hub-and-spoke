output "resource_group_name" {
  description = "The name of the Resource Group"
  value       = azurerm_resource_group.rg.name
}

output "storage_account_name" {
  description = "The name of the Storage Account"
  value       = azurerm_storage_account.stgacc.name
}

output "storage_container_name" {
  description = "The name of the Storage Container"
  value       = azurerm_storage_container.project_state.name
}

output "storage_account_primary_blob_endpoint" {
  description = "The primary blob endpoint of the Storage Account"
  value       = azurerm_storage_account.stgacc.primary_blob_endpoint
}
