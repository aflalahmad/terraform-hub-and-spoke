resource "azurerm_resource_group" "rg" {
    name = var.rg.resource_group
    location = var.rg.location
}

#virtual network

resource "azurerm_virtual_network" "hubvnets" {

    name  = var.vnet_name
    address_space = [var.address_space]
    resource_group_name =azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
    
   
    depends_on = [ azurerm_resource_group.rg ]
}
#subnet for all
resource "azurerm_subnet" "subnet" {
    for_each = var.subnet_details
    name = each.value.subnet_name
    address_prefixes = [each.value.address_prefixes]
    resource_group_name = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.hubvnets.name
  
    depends_on = [ azurerm_virtual_network.hubvnets]
   
  dynamic "delegation" {
    for_each = each.value.delegations
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_delegation
        actions = delegation.value.actions
      }
    }
  }
}
  

#publiips for all
resource "azurerm_public_ip" "publi_ips" {
  for_each = var.publicip_names
  name                = each.value.name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"  
  sku                 = "Standard"

  tags = {
    environment = "Example"
  }
}

#bastion host

resource "azurerm_bastion_host" "example" {
  name                = var.bastionhost_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name = "ipconfig"
    public_ip_address_id = azurerm_public_ip.publi_ips["bastion-pip"].id
    subnet_id = azurerm_subnet.subnet["AzureBastionSubnet"].id 
  }
 depends_on = [ azurerm_subnet.subnet["AzureBastionSubnet"] ]
}

#virtual network gateway

resource "azurerm_virtual_network_gateway" "vnetgateway" {

    name = "vnet-gateway"
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
    type = "Vpn"
    vpn_type = "RouteBased"
    sku = "VpnGw1"

    ip_configuration {
      name = "vnetgatewayconfiguration"
      public_ip_address_id = azurerm_public_ip.publi_ips["gateway-public-ip"].id
      private_ip_address_allocation = "Dynamic"
      subnet_id = azurerm_subnet.subnet["GatewaySubnet"].id 
    }
    depends_on = [ azurerm_subnet.subnet["GatewaySubnet"] ]
  
}


#firewall
resource "azurerm_firewall" "firewall" {

  name                = "hubFirewall"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku_name = "AZFW_VNet"
  sku_tier = "Standard" 


  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.subnet["AzureFirewallSubnet"].id
    public_ip_address_id = azurerm_public_ip.publi_ips["firewall-pip"].id
  }
   firewall_policy_id = azurerm_firewall_policy.application-policy.id
   depends_on = [azurerm_subnet.subnet["AzureFirewallSubnet"]]
}

#firewall policy
resource "azurerm_firewall_policy" "policy" {
  name                = "firewall-policy"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  base_policy_id      = null
  
}

resource "azurerm_firewall_policy_rule_collection_group" "icmp_rule" {

  name = "firewall-network-rule"
  firewall_policy_id = azurerm_firewall_policy.policy.id
  priority = 100
 network_rule_collection {
    name     = "AllowICMP_Rules"
    priority = 100
     action       = "Deny"

    rule {
      name         = "AllowICMP"
      protocols = "ICMP"
      destination_ports = "80"
      source_addresses = "10.20.0.0/16"  
      destination_addresses = "10.30.0.0/16"
    }
  }
}



data "azurerm_virtual_network" "spoke1vnet" {
  name = "spoke1VNet"
  resource_group_name = "spoke1RG"
  

}


#spoke1 peerings

resource "azurerm_virtual_network_peering" "spoke1_to_hub" {
    for_each = var.vnet_peerings

    name                     = "spoke1-to-hub-peering-${each.key}"  
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


data "azurerm_virtual_network" "spoke2vnet" {
  name = "spoke2VNet"
  resource_group_name = "spoke2RG"
  
}

#spoke2 to hub peerings

resource "azurerm_virtual_network_peering" "spoke2_to_hub" {
    for_each = var.vnet_peerings

    name                     = "spoke2-to-hub-peering-${each.key}"  
    virtual_network_name     = data.azurerm_virtual_network.spoke2vnet.name
    remote_virtual_network_id = azurerm_virtual_network.hubvnets.id

    allow_forwarded_traffic    = each.value.allow_forwarded_traffic
    allow_gateway_transit      = each.value.allow_gateway_transit
    allow_virtual_network_access = each.value.allow_virtual_network_access

    resource_group_name = data.azurerm_virtual_network.spoke2vnet.resource_group_name

    depends_on = [
        data.azurerm_virtual_network.spoke2vnet,
        azurerm_virtual_network.hubvnets
    ]
}

resource "azurerm_virtual_network_peering" "hub_to_spoke2" {
    for_each = var.vnet_peerings

    name                     = "hub-to-spoke2-peering-${each.key}" 
    virtual_network_name     = azurerm_virtual_network.hubvnets.name
    remote_virtual_network_id = data.azurerm_virtual_network.spoke2vnet.id

    allow_forwarded_traffic    = each.value.allow_forwarded_traffic
    allow_gateway_transit      = each.value.allow_gateway_transit
    allow_virtual_network_access = each.value.allow_virtual_network_access

    resource_group_name = azurerm_resource_group.rg.name

    depends_on = [
        data.azurerm_virtual_network.spoke2vnet,
        azurerm_virtual_network.hubvnets

    ]
}

#spoke3 to hub peering

data "azurerm_virtual_network" "spoke3vnet" {
  name = "spoke3_vnet"
  resource_group_name = "spoke3RG"
  
  
}


resource "azurerm_virtual_network_peering" "spoke2_to_hub" {
    for_each = var.vnet_peerings

    name                     = "spoke3-to-hub-peering-${each.key}"  
    virtual_network_name     = data.azurerm_virtual_network.spoke3vnet.name
    remote_virtual_network_id = azurerm_virtual_network.hubvnets.id

    allow_forwarded_traffic    = each.value.allow_forwarded_traffic
    allow_gateway_transit      = each.value.allow_gateway_transit
    allow_virtual_network_access = each.value.allow_virtual_network_access

    resource_group_name = data.azurerm_virtual_network.spoke3vnet.resource_group_name

    depends_on = [
        data.azurerm_virtual_network.spoke3vnet,
        azurerm_virtual_network.hubvnets
    ]
}

resource "azurerm_virtual_network_peering" "hub_to_spoke2" {
    for_each = var.vnet_peerings

    name                     = "hub-to-spoke3-peering-${each.key}" 
    virtual_network_name     = azurerm_virtual_network.hubvnets.name
    remote_virtual_network_id = data.azurerm_virtual_network.spoke3vnet.id

    allow_forwarded_traffic    = each.value.allow_forwarded_traffic
    allow_gateway_transit      = each.value.allow_gateway_transit
    allow_virtual_network_access = each.value.allow_virtual_network_access

    resource_group_name = azurerm_resource_group.rg.name

    depends_on = [
        data.azurerm_virtual_network.spoke3vnet,
        azurerm_virtual_network.hubvnets

    ]
}



#connect to on premise

 
 data "azurerm_public_ip" "onprem_publicip" {
   name = "onprem_vnetgatway_publicip"
   resource_group_name = "onprem_RG"
 }

data "azurerm_virtual_network" "onprem_vnet" {
  name = "onpremVNet"
  resource_group_name = "onprem_RG"
}



resource "azurerm_local_network_gateway" "hub_local_network_gateway" {
    name = var.hub_local_network_gateway_name
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    gateway_address = data.azurerm_public_ip.onprem_publicip.ip_address
    address_space = [data.azurerm_virtual_network.onprem_vnet.address_space[0]]
    depends_on = [ azurerm_public_ip.publi_ips,azurerm_virtual_network_gateway.vnetgateway,
     data.azurerm_public_ip.onprem_publicip,data.azurerm_virtual_network.onprem_vnet]
}

resource "azurerm_virtual_network_gateway_connection" "onprem_vpn_connection" {
     name = "hub-vpn-connection"
     location = azurerm_resource_group.rg.location
     resource_group_name = azurerm_resource_group.rg.name
     virtual_network_gateway_id = azurerm_virtual_network_gateway.vnetgateway.id
     local_network_gateway_id = azurerm_local_network_gateway.hub_local_network_gateway.id
     type = "IPsec"
     connection_protocol = "IKEv2"
     shared_key = "YourSharedKey"

     depends_on = [ azurerm_virtual_network_gateway.vnetgateway,azurerm_local_network_gateway.hub_local_network_gateway ]
}



























/*
resource "azurerm_monitor_diagnostic_setting" "diagnostic_setting" {
  for_each = {
    "firewall" = azurerm_firewall.firewall.id
    "vnet_gateway" = azurerm_virtual_network_gateway.vnet_gateway.id
  }

  name                         = "${each.key}-diagnostic-setting"
  target_resource_id           = each.value
  log_analytics_workspace_id   = azurerm_log_analytics_workspace.log_analytics_workspace.id

  log {
    category = "AllLogs"
    enabled  = true
    retention_policy {
      enabled = true
      days    = 30
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = true
    retention_policy {
      enabled = true
      days    = 30
    }
  }
}

resource "azurerm_log_analytics_workspace" "log_analytics_workspace" {
  name                = "logAnalyticsWorkspace"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}
*/