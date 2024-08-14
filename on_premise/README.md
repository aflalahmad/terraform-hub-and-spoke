<!-- BEGIN_TF_DOCS -->
# Onpremise resource group

This resource groups including virtual networks (VNets) with subnets and network security groups (NSGs) adn virtual network gateway,vpn connection and virtual network integration etc.. The configuration is designed to be dynamic, allowing for scalable and customizable deployments.
## Prerequisites

Before running this Terraform configuration, ensure you have the following prerequisites:
- Terraform installed on your local machine.
- Azure CLI installed and authenticated.
- Proper access permissions to create resources in the Azure subscription.

## Configuration details
## Integration with On-Premises Network
- Create the Resource Group

 Set up a resource group for the on-premises integration to house all related resources.
- Create the Virtual Network

 Define a virtual network for the on-premises environment, specifying the address space and other configurations.
- Create Subnets

Segment the virtual network into smaller subnets, each with its own address prefix.
- Create Public IP

Allocate a public IP address for the on-premises VPN gateway.
- Create a Virtual Network Gateway

Establish a virtual network gateway for the on-premises environment to enable site-to-site VPN connections between on-premises and Azure.
- Create a Local Network Gateway

Set up a local network gateway in Azure to represent the on-premises VPN device.
Specify the public IP address of the on-premises VPN device and the address space used in the on-premises network.
- Create a VPN Connection

Establish a VPN connection between the Azure virtual network gateway and the on-premises local network gateway.
Configure the connection type (IPsec) and the shared key for authentication.

- Create Network Interface Card (NIC)

Create a network interface card for each virtual machine in the on-premises network.
- Create Virtual Machines

Deploy virtual machines in the on-premises network with appropriate configurations.
- Set Up Route Table for Traffic Routing

Create a route table to manage traffic routing between the on-premises network and the hub.
Define routes to direct traffic through the VPN gateway.
- Associate Route Table with Subnets

Associate the route table with the subnets to enforce the routing rules and ensure proper traffic flow between on-premises and Azure.

# Diagram
![onprem](Images/onprem.png)

###### Apply the Terraform configurations :
Deploy the resources using Terraform,
```
terraform init
```
```
terraform plan "--var-file=variables.tfvars"
```
```
terraform apply "--var-file=variables.tfvars"
```

```hcl
#create a resource group
resource "azurerm_resource_group" "rg" {
    name = var.rg.resource_group
    location = var.rg.location
}

#virtual network
resource "azurerm_virtual_network" "onprem_vnets" {

    name  = var.vnet_name
    address_space = [var.address_space]
    resource_group_name =azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
    
   
    depends_on = [ azurerm_resource_group.rg ]
}

#subnet
resource "azurerm_subnet" "subnets" {

   for_each = var.subnet_details
    name = each.value.subnet_name
    address_prefixes = [each.value.address_prefixes]
    resource_group_name = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.onprem_vnets.name
  
    depends_on = [ azurerm_virtual_network.onprem_vnets]
  
}

#public ip
resource "azurerm_public_ip" "onprem_vnetgateway_pip" {
   name = var.public_ip_name
   resource_group_name = azurerm_resource_group.rg.name
   location = azurerm_resource_group.rg.location
   allocation_method = "Static"
   sku = "Standard"
   
}

#virtual network gateway
resource "azurerm_virtual_network_gateway" "onprem_vnetgateway" {
    for_each = var.subnet_details
    name = "onprem-vnet-gateway"
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
    type = "Vpn"
    vpn_type = "RouteBased"
    sku = "VpnGw1"
    

    ip_configuration {
    
      name = "vnetgatewayconfiguration"
      public_ip_address_id = azurerm_public_ip.onprem_vnetgateway_pip.id
      private_ip_address_allocation = "Dynamic"
      subnet_id = azurerm_subnet.onprem_vnetgateway_subnet[each.key].id
    }
    depends_on = [ azurerm_subnet.onprem_vnetgateway_subnet ]
  
}

data "azurerm_public_ip" "hub_publicip" {
  name = "gateway-public-ip"
  resource_group_name = "HubRG"
}

data "azurerm_virtual_network" "hub_vnet" {
  name = "HubVNet"
  resource_group_name = "HubRG"
}

#local network gateway
resource "azurerm_local_network_gateway" "onprem_local_network_gateway" {
    name = var.onprem_local_network_gateway_name
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    gateway_address = data.azurerm_public_ip.hub_publicip.ip_address
    address_space = [data.azurerm_virtual_network.hub_vnet.address_space[0]]
    depends_on = [ azurerm_public_ip.onprem_vnetgateway_pip,azurerm_virtual_network_gateway.onprem_vnetgateway,
     data.azurerm_public_ip.hub_publicip,data.azurerm_virtual_network.hub_vnet]
}

#gateway connection
resource "azurerm_virtual_network_gateway_connection" "onprem_vpn_connection" {
    for_each = var.subnet_details
     name = "onprem-vpn-connection"
     location = azurerm_resource_group.rg.location
     resource_group_name = azurerm_resource_group.rg.name
     virtual_network_gateway_id = azurerm_virtual_network_gateway.onprem_vnetgateway[each.key].id
     local_network_gateway_id = azurerm_local_network_gateway.onprem_local_network_gateway.id
     type = "IPsec"
     connection_protocol = "IKEv2"
     shared_key = "YourSharedKey"

     depends_on = [ azurerm_virtual_network_gateway.onprem_vnetgateway,azurerm_local_network_gateway.onprem_local_network_gateway ]
}



#key vault for storing username and password
resource "azurerm_key_vault" "kv" {

  name = var.keyvault_name
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  tenant_id = data.azurerm_client_config.current.tenant_id
  sku_name = "standard"
  

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azuread_client_config.current.object_id
    
    certificate_permissions = [
      "get",
      "list",
      "delete",
      "create",
      "import",
      "update",
      "managecontacts",
      "getissuers",
      "listissuers",
      "setissuers",
      "deleteissuers",
      "manageissuers",
    ]

    secret_permissions = [
    "Backup",
    "Delete",
    "Get",
    "List",
    "Purge",
    "Recover",
    "Restore",
    "Set",
  ]

    key_permissions = [
      "get",
      "list",
      "create",
      "update",
      "delete",
    ]
  }
  
}

#keyvault secret for username
resource "azurerm_key_vault_secret" "vm_admin_username" {

  for_each = var.vms
  name = "aflal_username"
  value = each.value.admin_username
  key_vault_id = azurerm_key_vault.kv.id
  
}

#keyvault secret for password
resource "azurerm_key_vault_secret" "vm_admin_password" {

  for_each = var.vms
  name = "aflal_password"
  value = each.value.admin_password
  key_vault_id = azurerm_key_vault.kv.id
  
}


#Network interface card
resource "azurerm_network_interface" "nic" {
    for_each = var.vms

    name = each.value.nic_name
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
    ip_configuration {
      name = "internal"
      subnet_id = azurerm_subnet.subnets["vm_subnet"].id
      private_ip_address_allocation = "Dynamic"
    }
  
}

#virtual machines
resource "azurerm_virtual_machine" "vm" {

    for_each = var.vms

    name = each.value.vm_name
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
    network_interface_ids = [azurerm_network_interface.nic[each.key].id]
    vm_size = each.value.vm_size
     
     storage_image_reference {
       publisher = "MicrosoftWindowsServer"
       offer = "WindowsServer"
       sku = "2019-DataCenter"
       version = "latest"
     }
      storage_os_disk {
    name              = "myOsDisk-${each.key}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
    
  os_profile {
    computer_name  = each.value.host_name
    admin_username = azurerm_key_vault_secret.vm_admin_username.value
    admin_password = azurerm_key_vault_secret.vm_admin_password.value
  }

   os_profile_windows_config {
    provision_vm_agent = true
  }

   storage_data_disk {
    name              = each.value.disk_name
    lun               = 0
    caching           = "ReadWrite"
    create_option     = "Empty"
    disk_size_gb      = each.value.data_disk_size_gb
    managed_disk_type = "Standard_LRS"
  }
  
}

#create a route table
resource "azurerm_route_table" "spoke1-udr" {

  name = "onprem-udr-to-spoke"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  route {
    name = "route-to-firewall"
    address_prefix = "10.30.0.0/16"
    next_hop_type = "VirtualNetworkGateway"
  
  }
  
}

# Associate the route table with their subnet
resource "azurerm_subnet_route_table_association" "routetable--ass" {
   subnet_id                 = azurerm_subnet.subnets["vm_subnet"].id
   route_table_id = azurerm_route_table.spoke1-udr.id
   depends_on = [ azurerm_subnet.subnets , azurerm_route_table.spoke1-udr ]
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.1.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 3.1.0)

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (~> 3.1.0)

## Resources

The following resources are used by this module:

- [azurerm_key_vault.kv](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault) (resource)
- [azurerm_key_vault_secret.vm_admin_password](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) (resource)
- [azurerm_key_vault_secret.vm_admin_username](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) (resource)
- [azurerm_local_network_gateway.onprem_local_network_gateway](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/local_network_gateway) (resource)
- [azurerm_network_interface.nic](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) (resource)
- [azurerm_public_ip.onprem_vnetgateway_pip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) (resource)
- [azurerm_resource_group.rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_route_table.spoke1-udr](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route_table) (resource)
- [azurerm_subnet.subnets](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) (resource)
- [azurerm_subnet_route_table_association.routetable--ass](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_route_table_association) (resource)
- [azurerm_virtual_machine.vm](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine) (resource)
- [azurerm_virtual_network.onprem_vnets](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) (resource)
- [azurerm_virtual_network_gateway.onprem_vnetgateway](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_gateway) (resource)
- [azurerm_virtual_network_gateway_connection.onprem_vpn_connection](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_gateway_connection) (resource)
- [azurerm_public_ip.hub_publicip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/public_ip) (data source)
- [azurerm_virtual_network.hub_vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_network) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_address_space"></a> [address\_space](#input\_address\_space)

Description: Address space for the virtual network.

Type: `string`

### <a name="input_keyvault_name"></a> [keyvault\_name](#input\_keyvault\_name)

Description: Name of the Azure Key Vault.

Type: `string`

### <a name="input_onprem_local_network_gateway_name"></a> [onprem\_local\_network\_gateway\_name](#input\_onprem\_local\_network\_gateway\_name)

Description: Name of the on-premises local network gateway.

Type: `string`

### <a name="input_public_ip_name"></a> [public\_ip\_name](#input\_public\_ip\_name)

Description: Name of the public IP.

Type: `string`

### <a name="input_rg"></a> [rg](#input\_rg)

Description: Specifies the resource group details.

Type:

```hcl
object({
    resource_group = string
    location       = string
  })
```

### <a name="input_subnet_details"></a> [subnet\_details](#input\_subnet\_details)

Description: Map of subnet details.

Type:

```hcl
map(object({
    subnet_name      = string
    address_prefixes = string
  }))
```

### <a name="input_vms"></a> [vms](#input\_vms)

Description: Map of virtual machine configurations.

Type:

```hcl
map(object({
    vm_name          = string
    nic_name         = string
    host_name        = string
    disk_name        = string
    vm_size          = string
    admin_username   = string
    admin_password   = string
    data_disk_size_gb = number
    subnet           = string
  }))
```

### <a name="input_vnet_name"></a> [vnet\_name](#input\_vnet\_name)

Description: Name of the virtual network.

Type: `string`

### <a name="input_vnet_peerings"></a> [vnet\_peerings](#input\_vnet\_peerings)

Description: Map of VNet peering settings.

Type:

```hcl
map(object({
    allow_forwarded_traffic      = bool
    allow_gateway_transit        = bool
    allow_virtual_network_access = bool
  }))
```

## Optional Inputs

No optional inputs.

## Outputs

The following outputs are exported:

### <a name="output_local_network_gateway_id"></a> [local\_network\_gateway\_id](#output\_local\_network\_gateway\_id)

Description: The ID of the local network gateway for on-premises connections.

### <a name="output_public_ip_id"></a> [public\_ip\_id](#output\_public\_ip\_id)

Description: The ID of the public IP address associated with the on-premises virtual network gateway.

### <a name="output_resource_group_id"></a> [resource\_group\_id](#output\_resource\_group\_id)

Description: The ID of the Azure resource group.

### <a name="output_subnet_ids"></a> [subnet\_ids](#output\_subnet\_ids)

Description: Map of subnet names to their IDs in the on-premises virtual network.

### <a name="output_virtual_network_gateway_ids"></a> [virtual\_network\_gateway\_ids](#output\_virtual\_network\_gateway\_ids)

Description: Map of subnet names to their IDs for on-premises virtual network gateways.

### <a name="output_virtual_network_id"></a> [virtual\_network\_id](#output\_virtual\_network\_id)

Description: The ID of the on-premises virtual network.

### <a name="output_vpn_connection_ids"></a> [vpn\_connection\_ids](#output\_vpn\_connection\_ids)

Description: Map of subnet names to their IDs for VPN connections to on-premises network.

## Modules

No modules.

#Contributing
We welcome contributions to improve this Terraform module.
<!-- END_TF_DOCS -->