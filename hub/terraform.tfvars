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
          delegations     = []

  },
 GatewaySubnet = {
    subnet_name = "GatewaySubnet"
    address_prefixes = "10.10.4.0/27"
          delegations     = []

  },
/*  hub_integration= {
    subnet_name = "hub_integration"
    address_prefixes = "10.10.2.0/24"
     delegations     = [{
        name              = "appServiceDelegation"
        service_delegation = "Microsoft.Web/serverFarms"
        actions           = ["Microsoft.Network/virtualNetworks/subnets/action", "Microsoft.Network/virtualNetworks/subnets/join/action"]
      }]
  },*/
  AzureBastionSubnet = {
    subnet_name = "AzureBastionSubnet"
    address_prefixes = "10.10.5.0/24"
     delegations     = []
  } 
}

vnet_peerings = {
  "spoke1" = {
    allow_forwarded_traffic      = true,
    allow_gateway_transit        = false,
    allow_virtual_network_access = true
  }
}

virtual_network_gateway_name = "vnet_gateway"

firewall_name = "hubfirewall"

firewall_policy_name = "firewall-policy"

hub_local_network_gateway_name = "hub-to-onprem"

vnet_gateway_connection = "hub-vpn-connection"