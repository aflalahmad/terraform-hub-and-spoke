rg = {
    resource_group = "HubRG"
    location = "Centralindia"
}
vnet_name = "HubVNet"
address_space = "10.10.0.0/16"
bastionhost_name = "mybastionhost"
publicip_names = {
  "bastion-pip"     = {
      name = "bastion-pip"
    },
    "gateway-public-ip" = {
      name = "gateway-public-ip"
    },
    "firewall-pip"    = {
      name = "firewall-pip"
    }
}
subnet_details = {
 AzureFirewallSubnet = {
    subnet_name = "AzureFirewallSubnet"
    address_prefixes = "10.10.3.0/24"
    
  },
 GatewaySubnet = {
    subnet_name = "GatewaySubnet"
    address_prefixes = "10.10.4.0/27"
  },
  hub_integration= {
    subnet_name = "hub_integration"
    address_prefixes = "10.10.2.0/24"
  },
  AzureBastionSubnet = {
    subnet_name = "AzureBastionSubnet"
    address_prefixes = "10.10.5.0/24"
  } 
}

vnet_peerings = {
  "spoke1" = {
    allow_forwarded_traffic      = true,
    allow_gateway_transit        = false,
    allow_virtual_network_access = true
  }
}

hub_local_network_gateway_name = "hub-to-onprem"