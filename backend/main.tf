#create resource group
resource "azurerm_resource_group" "rg" {
    name = var.rg.resource_group
    location = var.rg.location
}


#storage account
resource "azurerm_storage_account" "stgacc" {
    
  name = var.stgacc_name
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  account_tier = "Standard"
  account_replication_type = "LRS"
  
  tags = {
    environment = "production"
  }
}

# Create the Storage Account Container to store the state files
resource "azurerm_storage_container" "project_state" {
  name = var.container_name
  storage_account_name = azurerm_storage_account.stgacc.name
  container_access_type = "private"
}
