
data "azurerm_client_config" "current" {}
data "azuread_client_config" "current" {}

#create a resource group
resource "azurerm_resource_group" "rg" {
    name = var.rg.resource_group
    location = var.rg.location
}

#virtual network
resource "azurerm_virtual_network" "onprem_vnets" {

    name  = var.vnet_name
    address_space = [var.address_space]
    resource_group_name =azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
    
   
    depends_on = [ azurerm_resource_group.rg ]
}

#subnet
resource "azurerm_subnet" "subnets" {

   for_each = var.subnet_details
    name = each.value.subnet_name
    address_prefixes = [each.value.address_prefixes]
    resource_group_name = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.onprem_vnets.name
  
    depends_on = [ azurerm_virtual_network.onprem_vnets]
  
}

#public ip
resource "azurerm_public_ip" "onprem_vnetgateway_pip" {
   name = var.public_ip_name
   resource_group_name = azurerm_resource_group.rg.name
   location = azurerm_resource_group.rg.location
   allocation_method = "Static"
   sku = "Standard"
   
}

#virtual network gateway
resource "azurerm_virtual_network_gateway" "onprem_vnetgateway" {
    name = "onprem-vnet-gateway"
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
    type = "Vpn"
    vpn_type = "RouteBased"
    sku = "VpnGw1"
    

    ip_configuration {
    
      name = "vnetgatewayconfiguration"
      public_ip_address_id = azurerm_public_ip.onprem_vnetgateway_pip.id
      private_ip_address_allocation = "Dynamic"
      subnet_id = azurerm_subnet.subnets["GatewaySubnet"].id
    }
    depends_on = [ azurerm_subnet.subnets ]
  
}

data "azurerm_public_ip" "hub_publicip" {
  name = "gateway-public-ip"
  resource_group_name = "HubRG"
}

data "azurerm_virtual_network" "hub_vnet" {
  name = "HubVNet"
  resource_group_name = "HubRG"
}

#local network gateway
resource "azurerm_local_network_gateway" "onprem_local_network_gateway" {
    name = var.onprem_local_network_gateway_name
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    gateway_address = data.azurerm_public_ip.hub_publicip.ip_address
    address_space = [data.azurerm_virtual_network.hub_vnet.address_space[0]]
    depends_on = [ azurerm_public_ip.onprem_vnetgateway_pip,azurerm_virtual_network_gateway.onprem_vnetgateway,
     data.azurerm_public_ip.hub_publicip,data.azurerm_virtual_network.hub_vnet]
}

#gateway connection
resource "azurerm_virtual_network_gateway_connection" "onprem_vpn_connection" {
    for_each = var.subnet_details
     name = "onprem-vpn-connection"
     location = azurerm_resource_group.rg.location
     resource_group_name = azurerm_resource_group.rg.name
     virtual_network_gateway_id = azurerm_virtual_network_gateway.onprem_vnetgateway[each.key].id
     local_network_gateway_id = azurerm_local_network_gateway.onprem_local_network_gateway.id
     type = "IPsec"
     connection_protocol = "IKEv2"
     shared_key = "YourSharedKey"

     depends_on = [ azurerm_virtual_network_gateway.onprem_vnetgateway,azurerm_local_network_gateway.onprem_local_network_gateway ]
}


# Key Vault
resource "azurerm_key_vault" "kv" {
  name                = var.keyvault_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
  
  network_acls {
    bypass = "AzureServices"
    default_action = "Allow"
  }

  access_policy {
    tenant_id = "3060b492-90b8-4040-80ae-612072ce9037"
    object_id = data.azuread_client_config.current.object_id
    
    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Backup",
      "Recover",
      "Purge"
    ]

    certificate_permissions = [
      "Get",
      "List",
      "Create",
      "Delete",
      "Update",
      "Import",
      "ManageContacts",
      "ManageIssuers",
      "Purge",
      "Recover"
    ]

    key_permissions = [
      "Get",
      "List",
      "Create",
      "Update",
      "Import",
      "Delete"
    ]
  }
}

# Key Vault Certificate
resource "azurerm_key_vault_certificate" "example" {
  name         = "generated-cert"
  key_vault_id = azurerm_key_vault.kv.id

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }

    lifetime_action {
      action {
        action_type = "AutoRenew"
      }

      trigger {
        days_before_expiry = 30
      }
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    x509_certificate_properties {
      extended_key_usage = ["1.3.6.1.5.5.7.3.1"]

      key_usage = [
        "cRLSign",
        "dataEncipherment",
        "digitalSignature",
        "keyAgreement",
        "keyCertSign",
        "keyEncipherment",
      ]

      subject_alternative_names {
        dns_names = ["internal.contoso.com", "domain.hello.world"]
      }

      subject            = "CN=hello-world"
      validity_in_months = 12
    }
  }
}

# Key Vault Secrets
resource "azurerm_key_vault_secret" "vm_admin_username" {
  name         = "aflalahusername"
  value        = var.admin_username
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "vm_admin_password" {
  name         = "aflalahpassword"
  value        = var.admin_password
  key_vault_id = azurerm_key_vault.kv.id
}

#Network interface card
resource "azurerm_network_interface" "nic" {
    for_each = var.vms

    name = each.value.nic_name
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
    ip_configuration {
      name = "internal"
      subnet_id = azurerm_subnet.subnets["vm_subnet"].id
      private_ip_address_allocation = "Dynamic"
    }
  
}

#virtual machines
resource "azurerm_virtual_machine" "vm" {

    for_each = var.vms

    name = each.value.vm_name
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
    network_interface_ids = [azurerm_network_interface.nic[each.key].id]
    vm_size = each.value.vm_size
     
     storage_image_reference {
       publisher = "MicrosoftWindowsServer"
       offer = "WindowsServer"
       sku = "2019-DataCenter"
       version = "latest"
     }
      storage_os_disk {
    name              = "myOsDisk-${each.key}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
    
  os_profile {
    computer_name  = each.value.host_name
    admin_username = azurerm_key_vault_secret.vm_admin_username.value
    admin_password = azurerm_key_vault_secret.vm_admin_password.value
  }

   os_profile_windows_config {
    provision_vm_agent = true
  }

   storage_data_disk {
    name              = each.value.disk_name
    lun               = 0
    caching           = "ReadWrite"
    create_option     = "Empty"
    disk_size_gb      = each.value.data_disk_size_gb
    managed_disk_type = "Standard_LRS"
  }
  
}

#create a route table
resource "azurerm_route_table" "spoke1-udr" {

  name = "onprem-udr-to-spoke"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  route {
    name = "route-to-firewall"
    address_prefix = "10.30.0.0/16"
    next_hop_type = "VirtualNetworkGateway"
  
  }
  
}

# Associate the route table with their subnet
resource "azurerm_subnet_route_table_association" "routetable--ass" {
   subnet_id                 = azurerm_subnet.subnets["vm_subnet"].id
   route_table_id = azurerm_route_table.spoke1-udr.id
   depends_on = [ azurerm_subnet.subnets , azurerm_route_table.spoke1-udr ]
}
