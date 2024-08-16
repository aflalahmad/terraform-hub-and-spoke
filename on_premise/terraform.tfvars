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
  },
  vm_subnet = {
    subnet_name = "vm_subnet"
    address_prefixes = "10.20.2.0/24"
  }
}
public_ip_name = "onprem_vnetgatway_publicip"
onprem_local_network_gateway_name = "onprem-to-hub"
keyvault_name = "Aflalkeyvault7788"


vms = {
    vm1 = {
        vm_name = "onpremVM1"
        nic_name = "mynic1"
        host_name = "myhostname1"
        disk_name = "mydatadisk1"
        vm_size = "Standard_DS1_v2"
        admin_username = "azureuser"
        admin_password = "P@ssword123456"
        data_disk_size_gb = 10
        subnet = "vm-subnet"
        
    }
}