rg = {
    resource_group = "HubRG"
    location = "Centralindia"
}
vnet_name = "HubVNet"
address_space = "10.10.0.0/16"
subnet_name = "Hubsubnet"
address_prefixes = "10.10.2.0/24"

vnet_peerings = {
  "spoke1" = {
    allow_forwarded_traffic      = true,
    allow_gateway_transit        = false,
    allow_virtual_network_access = true
  }
}
