resource "azurerm_resource_group" "rg" {
    name = var.rg.resource_group
    location = var.rg.location
}

resource "azurerm_virtual_network" "onprem_vnets" {

    name  = var.vnet_name
    address_space = [var.address_space]
    resource_group_name =azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
    
   
    depends_on = [ azurerm_resource_group.rg ]
}

resource "azurerm_subnet" "onprem_vnetgateway_subnet" {
    for_each = var.subnet_details

    name = each.value.subnet_name
    address_prefixes = [each.value.address_prefixes]
    resource_group_name = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.onprem_vnets.name

}

resource "azurerm_subnet" "subnets" {

  name = "vm-subnet"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.onprem_vnets.name
  address_prefixes = "10.20.2.0/24"
  
}

resource "azurerm_public_ip" "onprem_vnetgateway_pip" {
   name = var.public_ip_name
   resource_group_name = azurerm_resource_group.rg.name
   location = azurerm_resource_group.rg.location
   allocation_method = "Static"
   sku = "Standard"
   
}

resource "azurerm_virtual_network_gateway" "onprem_vnetgateway" {
    for_each = var.subnet_details
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
      subnet_id = azurerm_subnet.onprem_vnetgateway_subnet[each.key].id
    }
    depends_on = [ azurerm_subnet.onprem_vnetgateway_subnet ]
  
}

data "azurerm_public_ip" "hub_publicip" {
  name = "gateway-public-ip"
  resource_group_name = "HubRG"
}

data "azurerm_virtual_network" "hub_vnet" {
  name = "HubVNet"
  resource_group_name = "HubRG"
}

resource "azurerm_local_network_gateway" "onprem_local_network_gateway" {
    name = var.onprem_local_network_gateway_name
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    gateway_address = data.azurerm_public_ip.hub_publicip.ip_address
    address_space = [data.azurerm_virtual_network.hub_vnet.address_space[0]]
    depends_on = [ azurerm_public_ip.onprem_vnetgateway_pip,azurerm_virtual_network_gateway.onprem_vnetgateway,
     data.azurerm_public_ip.hub_publicip,data.azurerm_virtual_network.hub_vnet]
}

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



data "azurerm_key_vault" "kv" {
    name = "mykeyvault09088"
    resource_group_name = "spoke1RG"
}
data "azurerm_key_vault_secret" "vm_admin_username" {
     name = "adminn-username1"
     key_vault_id = data.azurerm_key_vault.kv.id
}
data "azurerm_key_vault_secret" "vm_admin_password" {
     name = "adminn-npassword2"
     key_vault_id = data.azurerm_key_vault.kv.id
}


#Network interface card
resource "azurerm_network_interface" "nic" {
    for_each = var.vms

    name = each.value.nic_name
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
    ip_configuration {
      name = "internal"
      subnet_id = azurerm_subnet.subnets[each.value.subnet].id
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
    admin_username = data.azurerm_key_vault_secret.vm_admin_username[each.key].value
    admin_password = data.azurerm_key_vault_secret.vm_admin_password[each.key].value
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

resource "azurerm_route_table" "spoke1-udr" {

  name = "onprem-udr-to-spoke"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  route {
    name = "route-to-firewall"
    address_prefix = "10.30.0.0/16"
    next_hop_type = "VirtualAppliance"
    next_hop_in_ip_address = "10.10.3.4"
  
  }
  
}

