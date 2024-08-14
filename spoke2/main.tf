#create resource group
resource "azurerm_resource_group" "rg" {
    name = var.rg.resource_group
    location = var.rg.location
}
#virtual network
resource "azurerm_virtual_network" "vnet" {
  name = "spoke2_vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  address_space = ["10.0.0.0/24"]
}
#subnets
resource "azurerm_subnet" "subnets" {

    for_each = var.subnets

    name = each.value.name
    address_prefixes = [each.value.address_prefixes]
    resource_group_name = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    depends_on = [ azurerm_virtual_network.vnet ]
}

#Network security group
resource "azurerm_network_security_group" "nsg" {
     for_each = var.subnets

     name = each.value.name
     resource_group_name = azurerm_resource_group.rg.name
     location = azurerm_resource_group.rg.location

     dynamic "security_rule" {
        for_each = { for rule in local.rules_csv : rule.name => rule }
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
     }
}
#nsg association
resource "azurerm_subnet_network_security_group_association" "nsg-association" {
      for_each = var.subnets

      subnet_id = azurerm_subnet.subnets[each.key].id
      network_security_group_id = azurerm_network_security_group.nsg[each.key].id
      depends_on = [ azurerm_network_security_group.nsg,azurerm_subnet.subnets ]
}

# Create the Public IP for Application Gateway
resource "azurerm_public_ip" "public_ip" {
  name                = "AppGateway-pip"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Create the Application for their dedicated subnet
resource "azurerm_application_gateway" "appGW" {
  name                = "App-Gateway"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "appgw-ip-config"
    subnet_id = azurerm_subnet.subnets["AppGw-subnet"].id
  }

  frontend_ip_configuration {
    name                 = "appgw-frontend-ip"
    public_ip_address_id = azurerm_public_ip.public_ip.id
  }

  frontend_port {
    name = "frontend-port"
    port = 80
  }

  backend_address_pool {
    name = "appgw-backend-pool"
  }

  backend_http_settings {
    name                  = "appgw-backend-http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 20
  }

  http_listener {
    name                           = "appgw-http-listener"
    frontend_ip_configuration_name = "appgw-frontend-ip"
    frontend_port_name             = "frontend-port"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "appgw-routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "appgw-http-listener"
    backend_address_pool_name  = "appgw-backend-pool"
    backend_http_settings_name = "appgw-backend-http-settings"
  }
    depends_on = [azurerm_resource_group.rg ,azurerm_subnet.subnets ,azurerm_public_ip.public_ip]
 }

#key vault for secret username and password
data "azurerm_key_vault" "kv" {
    name = "Aflalkeyvault7788"
    resource_group_name = "spoke1RG"
}
data "azurerm_key_vault_secret" "vm_admin_username" {
     name = "aflal_username"
     key_vault_id = data.azurerm_key_vault.kv.id
}
data "azurerm_key_vault_secret" "vm_admin_password" {
     name = "aflal_password"
     key_vault_id = data.azurerm_key_vault.kv.id
}


#Virtual machine scale set
resource "azurerm_windows_virtual_machine_scale_set" "vmss" {
  name                 = var.vmss_name
  resource_group_name  = azurerm_resource_group.rg.name
  location             = azurerm_resource_group.rg.location
  sku                  = var.sku
  instances            = var.instance
  admin_password       = data.azurerm_key_vault_secret.vm_admin_password.value
  admin_username       = data.azurerm_key_vault_secret.vm_admin_username.value
  computer_name_prefix = "vm-"

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter-Server-Core"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
  dynamic "network_interface" {
    for_each = azurerm_subnet.subnets

    content {
      name    = "example-${network_interface.key}"
      primary = network_interface.key == "subnet1"  

      ip_configuration {
        name      = "internal"
        primary   = network_interface.key == "subnet1"  
        subnet_id = network_interface.value.id
      }
    }
  }
}


#using data block for Hub vnet
data "azurerm_virtual_network" "Hub_VNet" {
  name = "HubVNet"
  resource_group_name = "HubRG"
}
#spoke2 to hub peerings
resource "azurerm_virtual_network_peering" "spoke2_to_hub" {
    for_each = var.vnet_peerings

    name                     = "spoke2-to-hub-peering-${each.key}"  
    virtual_network_name     = azurerm_virtual_network.vnet.name
    remote_virtual_network_id = data.azurerm_virtual_network.Hub_VNet.id

    allow_forwarded_traffic    = each.value.allow_forwarded_traffic
    allow_gateway_transit      = each.value.allow_gateway_transit
    allow_virtual_network_access = each.value.allow_virtual_network_access

    resource_group_name = azurerm_resource_group.rg.name

    depends_on = [
        azurerm_virtual_network.vnet,
        data.azurerm_virtual_network.Hub_VNet
    ]
}

resource "azurerm_virtual_network_peering" "hub_to_spoke2" {
    for_each = var.vnet_peerings

    name                     = "hub-to-spoke2-peering-${each.key}" 
    virtual_network_name     = data.azurerm_virtual_network.Hub_VNet.name
    remote_virtual_network_id = azurerm_virtual_network.vnet.id

    allow_forwarded_traffic    = each.value.allow_forwarded_traffic
    allow_gateway_transit      = each.value.allow_gateway_transit
    allow_virtual_network_access = each.value.allow_virtual_network_access

    resource_group_name = azurerm_resource_group.rg.name

    depends_on = [
        azurerm_virtual_network.vnet,
        data.azurerm_virtual_network.Hub_VNet

    ]
}

/*
#Daily backup for VM
# Recovery Services Vault
resource "azurerm_recovery_services_vault" "rsv" {
  name                = var.rsv_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"
}

resource "azurerm_backup_policy_vm" "backup_policy" {
  name                = var.backuppolicy_name
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


# Backup Protection for VM Scale Set
/*
resource "azurerm_backup_protected_vm" "backup_protected" {
  count               = var.instance
  resource_group_name = azurerm_resource_group.rg.name
  recovery_vault_name = azurerm_recovery_services_vault.rsv.name
  source_vm_id        = azurerm_windows_virtual_machine_scale_set.vmss.virtual_machine_id[count.index]
  backup_policy_id    = azurerm_backup_policy_vm.backup_policy.id
  depends_on = [ azurerm_windows_virtual_machine_scale_set.vmss,azurerm_backup_policy_vm.backup_policy ]
}


#Service deployments should be limited to specific Azure regions via Azure Policy. 
resource "azurerm_policy_definition" "limit_deployment_regions" {
  name         = "limiteddeployment-regions"
  display_name = "Limit Azure Resource Deployments to Specific Regions"
  description  = "Ensures that resources are deployed only in specific Azure regions."
  mode = "Indexed"
  policy_type = "Custom"

  policy_rule = jsonencode({
    "if": {
      "not": {
        "field": "location",
        "in": [
          "East US",
          "West Europe",
          "Southeast Asia",
          "West US"
        ]
      }
    },
    "then": {
      "effect": "deny"
    }
  })
}
#All Azure Policies should be scoped to the Resource Group level. 
resource "azurerm_resource_group_policy_assignment" "example" {
  name                 = "example"
  resource_group_id    = azurerm_resource_group.rg.id
  policy_definition_id = azurerm_policy_definition.limit_deployment_regions.id

}

*/
#route table for communicate between spoke2 t0 spoke1 through firewall
/*
resource "azurerm_route_table" "spoke2-udr" {

  name = "spoke2-udr-to-firewall"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  route {
    name = "route-to-firewall"
    address_prefix = "10.30.1.0/24"
    next_hop_type = "VirtualAppliance"
    next_hop_in_ip_address = "10.10.3.4"
  }
  
}

resource "azurerm_subnet_route_table_association" "spoke1udr_subnet_association" {
    for_each = var.subnets

    subnet_id = azurerm_subnet.subnets[each.key].id
    route_table_id = azurerm_route_table.spoke2-udr.id
}
*/