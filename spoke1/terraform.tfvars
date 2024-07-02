rg = {
    resource_group = "spoke1RG"
    location = "Eastus"
}
vnets = {
     spoke1VNet= {
        address_space = "10.30.0.0/16"
    }
}

subnets = {
     subnet1 = {
        name = "spokesubnet1",
        vnet = "spoke1VNet"
        address_prefixes = "10.30.1.0/24"
     
     },
     subnet2 = {
        name = "spokesubnet2",
        vnet = "spoke1VNet"
        address_prefixes = "10.30.2.0/24"
        
     }
}

vms = {
    vm1 = {
        vm_name = "spokeVM1"
        nic_name = "mynic1"
        host_name = "myhostname1"
        disk_name = "mydatadisk1"
        vm_size = "Standard_DS1_v2"
        admin_username = "spoke1"
        admin_password = "P@ssword123456"
        data_disk_size_gb = 10
        subnet = "subnet1"
        
    }
    vm2 = {
        vm_name = "spokeVM2"
        nic_name = "mynic2"
        host_name = "myhostname2"
        disk_name = "mydatadisk2"
        vm_size = "Standard_DS1_v2"
        admin_username = "spoke2"
        admin_password = "P@ssword1234567"
        data_disk_size_gb = 10
        subnet = "subnet2"
        
    }
}

keyvault_name = "mykeyvault09088"
rsv_name = "spoke1rescoveryservicevault"
backuppolicy_name = "spoke1backuppolicy"

