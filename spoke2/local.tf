locals {
    rules_csv = csvdecode(file(var.rules_file))
      application_gateway_backend_address_pool_ids = [for pool in azurerm_application_gateway.appGW.backend_address_pool : pool.id]

 
}