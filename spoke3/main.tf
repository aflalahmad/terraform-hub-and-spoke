resource "azurerm_resource_group" "rg" {
    name = var.rg.resource_group
    location = var.rg.location
}

resource "azurerm_app_service_plan" "appservice_plan" {
    
    name = var.appserviceplan_name
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    sku {
      tier = "Basic"
      size = "B1"
    }
    kind = "Windows"
}

resource "azurerm_app_service" "app_service" {
  name =var.appservice_name
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  app_service_plan_id = azurerm_app_service_plan.appservice_plan.id

  
}

resource "azurerm_virtual_network" "spoke3vnet" {

  name = var.vnet_name
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  address_space = "10.100.0.0/16"
  
}

resource "azurerm_subnet" "subnets" {
  
  name = "spoke3-subnet"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.spoke3vnet.name
  address_prefixes = "10.100.1.0/24"
}

#intergrate to hub
resource "azurerm_app_service_virtual_network_swift_connection" "vnet_integration" {
  app_service_id = azurerm_app_service.app_service.id
  subnet_id = azurerm_subnet.subnets.id
  depends_on = [ azurerm_app_service.app_service,azurerm_subnet.subnets]
}

/*
#Recovery service vault for backup

resource "azurerm_recovery_services_vault" "rsv" {

  name = "rsv"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  sku = "Standard"
  
}

resource "azurerm_backup_policy_vm" "backup_policy" {
  name                = "backup-policy"
  resource_group_name = azurerm_resource_group.rg.name
  recovery_vault_name = azurerm_recovery_services_vault.rsv.name

  backup {
    frequency = "Daily"
    time      = "12:00"
  }

  retention_daily {
    count = 30
  }

  retention_weekly {
    count   = 5
    weekdays = ["Monday"]
  }

  retention_monthly {
    count   = 12
    weekdays = ["Monday"]
    weeks    = ["First"]
  }

  retention_yearly {
    count   = 1
    weekdays = ["Monday"]
    months   = ["January"]
    weeks    = ["First"]
  }
}

resource "azurerm_backup_protected_vm" "backup_protected" {
    for_each = azurerm_virtual_machine.vm
    resource_group_name = azurerm_resource_group.rg.name
    recovery_vault_name = azurerm_recovery_services_vault.rsv.name
    source_vm_id = each.value.id
    backup_policy_id = azurerm_backup_policy_vm.backup_policy.id
}

*/