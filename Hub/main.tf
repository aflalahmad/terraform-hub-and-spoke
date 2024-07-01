resource "azurerm_resource_group" "rg" {
    name = var.rg.resource_group
    location = var.rg.location
}

resource "azurerm_virtual_network" "hubvnets" {

    name  = var.vnet_name
    address_space = [var.address_space]
    resource_group_name =azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
    
   
    depends_on = [ azurerm_resource_group.rg ]
}

resource "azurerm_subnet" "subnet" {

    name = var.subnet_name
    address_prefixes = [var.address_prefixes]
    resource_group_name = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.hubvnets.name
    depends_on = [ azurerm_virtual_network.hubvnets]
  
}



resource "azurerm_subnet" "Gatewaysubnet" {

    name = "GatewaySubnet"
    address_prefixes = ["10.0.2.0/27"]
    resource_group_name = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnets.name
    depends_on = [ azurerm_virtual_network.vnets ]
  
}

resource "azurerm_public_ip" "gatewaypublicip" {

    name = "gateway-public-ip"
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
    allocation_method = "Static"
    sku = "Standard" 
  
}

resource "azurerm_virtual_network_gateway" "vnetgateway" {

    name = "vnet-gateway"
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
    type = "Vpn"
    vpn_type = "RouteBased"
    sku = "VpnGw1"

    ip_configuration {
      name = "vnetgatewayconfiguration"
      public_ip_address_id = azurerm_public_ip.gatewaypublicip.id
      private_ip_address_allocation = "Dynamic"
      subnet_id = azurerm_subnet.Gatewaysubnet.id
    }
    depends_on = [ azurerm_subnet.Gatewaysubnet ]
  
}

resource "azurerm_subnet" "firewall_subnet" {
  name                 = "AzureFirewallSubnet"
  address_prefixes     = ["10.0.3.0/26"]
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnets.name

  depends_on = [azurerm_virtual_network.vnets]
}

resource "azurerm_public_ip" "firewall_pip" {
  name                = "firewall-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

resource "azurerm_firewall" "firewall" {
  name                = "hubFirewall"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku_name = "AZFW_VNet"
  sku_tier = "Standard" 


  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.firewall_subnet.id
    public_ip_address_id = azurerm_public_ip.firewall_pip.id
  }

  depends_on = [azurerm_subnet.firewall_subnet]
}


data "azurerm_virtual_network" "spoke1vnet" {
  name = "spoke1VNet"
  resource_group_name = "spoke1RG"
  
}
resource "azurerm_virtual_network_peering" "spoke1_to_hub" {
    for_each = var.vnet_peerings

    name                     = "spoke-to-hub-peering-${each.key}"  
    virtual_network_name     = data.azurerm_virtual_network.spoke1vnet.name
    remote_virtual_network_id = azurerm_virtual_network.hubvnets.id

    allow_forwarded_traffic    = each.value.allow_forwarded_traffic
    allow_gateway_transit      = each.value.allow_gateway_transit
    allow_virtual_network_access = each.value.allow_virtual_network_access

    resource_group_name = data.azurerm_virtual_network.spoke1vnet.resource_group_name

    depends_on = [
        data.azurerm_virtual_network.spoke1vnet,
        azurerm_virtual_network.hubvnets
    ]
}

resource "azurerm_virtual_network_peering" "hub_to_spoke1" {
    for_each = var.vnet_peerings

    name                     = "hub-to-spoke1-peering-${each.key}" 
    virtual_network_name     = azurerm_virtual_network.hubvnets.name
    remote_virtual_network_id = data.azurerm_virtual_network.spoke1vnet.id

    allow_forwarded_traffic    = each.value.allow_forwarded_traffic
    allow_gateway_transit      = each.value.allow_gateway_transit
    allow_virtual_network_access = each.value.allow_virtual_network_access

    resource_group_name = azurerm_resource_group.rg.name

    depends_on = [
        data.azurerm_virtual_network.spoke1vnet,
        azurerm_virtual_network.hubvnets

    ]
}
