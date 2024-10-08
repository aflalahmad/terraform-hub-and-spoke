#create resource group
resource "azurerm_resource_group" "rg" {
  name     = var.rg.resource_group
  location = var.rg.location
}

#app service plan
resource "azurerm_app_service_plan" "appservice_plan" {

  name                = var.appserviceplan_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku {
    tier = "Basic"
    size = "B1"
  }
  kind = "Windows"
}

#app service
resource "azurerm_app_service" "app_service" {
  name                = var.appservice_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  app_service_plan_id = azurerm_app_service_plan.appservice_plan.id


}

#virtual network
resource "azurerm_virtual_network" "spoke3vnet" {
  name                = var.vnet_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = [var.address_space]
  depends_on          = [azurerm_resource_group.rg]

}

#subnet
resource "azurerm_subnet" "subnets" {


  for_each             = var.subnet_details
  name                 = each.key
  address_prefixes     = [each.value.address_prefix]
  virtual_network_name = azurerm_virtual_network.spoke3vnet.name
  resource_group_name  = azurerm_resource_group.rg.name
  dynamic "delegation" {
    for_each = each.key == "appservice" ? [1] : []
    content {
      name = "appservice_delegation"
      service_delegation {
        name = "Microsoft.Web/serverFarms"
        actions = [
          "Microsoft.Network/virtualNetworks/subnets/action"
        ]
      }
    }

  }
  depends_on = [azurerm_virtual_network.spoke3vnet]
}


#intergrate to hub
resource "azurerm_app_service_virtual_network_swift_connection" "vnet_integration" {
  app_service_id = azurerm_app_service.app_service.id
  subnet_id      = azurerm_subnet.subnets["appservice"].id
  depends_on     = [azurerm_app_service.app_service, azurerm_subnet.subnets]
}

#using data block for Hub vnet
data "azurerm_virtual_network" "Hub_VNet" {
  name                = "HubVNet"
  resource_group_name = "HubRG"
}


resource "azurerm_virtual_network_peering" "spoke3_to_hub" {

  name                         = "spoke3-to-hub-peering"
  virtual_network_name         = azurerm_virtual_network.spoke3vnet.name
  remote_virtual_network_id    = data.azurerm_virtual_network.Hub_VNet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false

  resource_group_name = azurerm_resource_group.rg.name

  depends_on = [
    azurerm_virtual_network.spoke3vnet,
    data.azurerm_virtual_network.Hub_VNet
  ]
}

resource "azurerm_virtual_network_peering" "hub_to_spoke3" {


  name                         = "hub-to-spoke3-peering"
  virtual_network_name         = data.azurerm_virtual_network.Hub_VNet.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke3vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false

  resource_group_name = data.azurerm_virtual_network.Hub_VNet.resource_group_name

  depends_on = [
    azurerm_virtual_network.spoke3vnet,
    data.azurerm_virtual_network.Hub_VNet

  ]
}




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

