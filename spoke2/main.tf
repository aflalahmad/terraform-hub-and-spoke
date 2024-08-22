#create resource group
resource "azurerm_resource_group" "rg" {
    name = var.rg.resource_group
    location = var.rg.location
}
#virtual network
resource "azurerm_virtual_network" "vnet" {
  name = var.vnet_name
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  address_space = ["10.0.0.0/24"]
}
#subnets
resource "azurerm_subnet" "subnets" {

    for_each = var.subnets

    name = each.key
    address_prefixes = [each.value.address_prefixes]
    resource_group_name = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    depends_on = [ azurerm_virtual_network.vnet ]
}

#Network security group
resource "azurerm_network_security_group" "nsg" {
     for_each = var.subnets

     name = each.key
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

      subnet_id = azurerm_subnet.subnets["spoke2subnet1"].id
      network_security_group_id = azurerm_network_security_group.nsg["spoke2subnet1"].id
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


#Managed user identity
resource "azurerm_user_assigned_identity" "uami" {
  name                = "appgw-uami"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

#key  vault access policy
resource "azurerm_key_vault_access_policy" "appgw_policy" {
  key_vault_id = data.azurerm_key_vault.kv.id
  tenant_id    = "3060b492-90b8-4040-80ae-612072ce9037"
  object_id    = azurerm_user_assigned_identity.uami.principal_id

  certificate_permissions = ["Get", "List"]
  secret_permissions      = ["Get", "List"]
  key_permissions         = ["Get", "List"]
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

 identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.uami.id]
  }

  gateway_ip_configuration {
    name      = "appgw-ip-config"
    subnet_id = azurerm_subnet.subnets["AppGw"].id
  }

  frontend_ip_configuration {
    name                 = "appgw-frontend-ip"
    public_ip_address_id = azurerm_public_ip.public_ip.id
  }

  frontend_port {
    name = "frontend-port"
    port = 443
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
    protocol                       = "Https"
    ssl_certificate_name = "generated-cert"
  }

  ssl_certificate {
    name = "generated-cert"
    # data = data.azurerm_key_vault_certificate.example.certificate_data
    # password = data.azurerm_key_vault_certificate.example.secret_id
     key_vault_secret_id = data.azurerm_key_vault_certificate.example.secret_id
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
    name = "Aflalkeyvault7700"
    resource_group_name = "onprem_RG"
}
data "azurerm_key_vault_secret" "vm_admin_username" {
     name = "aflalahusername"
     key_vault_id = data.azurerm_key_vault.kv.id
}
data "azurerm_key_vault_secret" "vm_admin_password" {
     name = "aflalahpassword"
     key_vault_id = data.azurerm_key_vault.kv.id
}


# key vault certificate using data block
data "azurerm_key_vault_certificate" "example" {
  name = "generated-cert"
  key_vault_id = data.azurerm_key_vault.kv.id
}

#Virtual machine scale set
resource "azurerm_windows_virtual_machine_scale_set" "vmss" {
  name                = var.vmss_name
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  sku = var.sku
  instances = var.instance
  admin_username = data.azurerm_key_vault_secret.vm_admin_username.value
  admin_password = data.azurerm_key_vault_secret.vm_admin_password.value
  network_interface {
    name = "myvmssname"
    primary = true
    ip_configuration {
      name = "internal"
      subnet_id = azurerm_subnet.subnets["spoke2subnet1"].id
      application_gateway_backend_address_pool_ids = local.application_gateway_backend_address_pool_ids
    }
  }
  os_disk {
    caching = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}

#using data block for Hub vnet
data "azurerm_virtual_network" "Hub_VNet" {
  name = "HubVNet"
  resource_group_name = "HubRG"
}
#spoke2 to hub peerings
resource "azurerm_virtual_network_peering" "spoke2_to_hub" {

    name                     = "spoke2-to-hub-peering"  
    virtual_network_name     = azurerm_virtual_network.vnet.name
    remote_virtual_network_id = data.azurerm_virtual_network.Hub_VNet.id

      allow_virtual_network_access = true
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
  use_remote_gateways       = false


    resource_group_name = azurerm_resource_group.rg.name

    depends_on = [
        azurerm_virtual_network.vnet,
        data.azurerm_virtual_network.Hub_VNet
    ]
}

resource "azurerm_virtual_network_peering" "hub_to_spoke2" {

    name                     = "hub-to-spoke2-peering" 
    virtual_network_name     = data.azurerm_virtual_network.Hub_VNet.name
    remote_virtual_network_id = azurerm_virtual_network.vnet.id

 allow_virtual_network_access = true
  allow_forwarded_traffic   = true
  allow_gateway_transit     = true
  use_remote_gateways       = false

    resource_group_name = data.azurerm_virtual_network.Hub_VNet.resource_group_name

    depends_on = [
        azurerm_virtual_network.vnet,
        data.azurerm_virtual_network.Hub_VNet

    ]
}


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

