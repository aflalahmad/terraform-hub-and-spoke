rg = {
    resource_group = "spoke3RG"
    location = "Centralindia"
}
appserviceplan_name = "myserviceplan"
appservice_name = "myappservice7789"
vnet_details {
    spoke3_vnet = {
        vnet_name = "spoke3_vnet"
        address_space = "10.100.0.0/16"
    } 
}

subnet_details = {
    subnet1  = {
        subnet_name = "webapp"
        address_prefixes = "10.100.1.0/24"
    },
    subnet2 = {
        subnet_name = "appservice"
        address_prefixes = "10.100.2.0/24s"
    }
}