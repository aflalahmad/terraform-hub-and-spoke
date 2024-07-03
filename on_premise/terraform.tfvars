rg = {
    resource_group = "onprem_RG"
    location = "Centralindia"
}
vnet_name = "onpremVNet"
address_space = "10.20.0.0/16"
subnet_details = {
 GatewaySubnet = {
    subnet_name = "GatewaySubnet"
    address_prefixes = "10.20.1.0/24"
  }
}
public_ip_name = "onprem_vnetgatway_publicip"
onprem_local_network_gateway_name = "onprem-to-hub"