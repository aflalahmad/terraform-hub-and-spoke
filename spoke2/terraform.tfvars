rg = {
    resource_group = "spoke2RG"
    location = "Westus"
}

vnet_name = "spoke2VNet"

subnets = {
     "spoke2subnet1" = {
        name = "spoke2subnet1",
        vnet = "spoke2VNet"
        address_prefixes = "10.0.0.0/25"
     
     },
     "App-Gw" = {
      name = "App-Gw"
      vnet = "spoke2VNet"
      address_prefixes = "10.0.0.128/25"
     }
}

vmss_name = "myvmss"
admin_username = "scalesetuser"
admin_password = "P@assword12345"
sku = "Standard_F2"
instance = 2
rsv_name = "spoke2rescoveryservicevault"
backuppolicy_name = "spoke2backuppolicy"

