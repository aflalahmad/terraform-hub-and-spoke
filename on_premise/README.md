<!-- BEGIN_TF_DOCS -->
# On-Premises Resource Group 🏢
This resource group includes virtual networks (VNets) with subnets, network security groups (NSGs), a virtual network gateway, VPN connection, and virtual network integration. The configuration is designed to be dynamic, allowing for scalable and customizable deployments.

## Prerequisites ⚙️
### Before running this Terraform configuration, ensure you have the following prerequisites:

- Terraform installed on your local machine. 🛠️
- Azure CLI installed and authenticated. 🔑
- Proper access permissions to create resources in the Azure subscription. ✅
## Configuration Details 📝
### Integration with On-Premises Network 🔗
1. Create the Resource Group 🗂️
- Set up a resource group for the on-premises integration to house all related resources.

2. Create the Virtual Network 🌐
- Define a virtual network for the on-premises environment, specifying the address space and other configurations.

3. Create Subnets 🧩
- Segment the virtual network into smaller subnets, each with its own address prefix.

4. Create Public IP 🌍
- Allocate a public IP address for the on-premises VPN gateway.

5. Create a Virtual Network Gateway 🔗
- Establish a virtual network gateway for the on-premises environment to enable site-to-site VPN connections between on-premises and Azure.

6. Create a Local Network Gateway 🌐
- Set up a local network gateway in Azure to represent the on-premises VPN device. Specify the public IP address of the on-premises VPN device and the address space used in the on-premises network.

7. Create a VPN Connection 🔗
- Establish a VPN connection between the Azure virtual network gateway and the on-premises local network gateway. Configure the connection type (IPsec) and the shared key for authentication.

8. Create Network Interface Card (NIC) 💻
- Create a network interface card for each virtual machine in the on-premises network.

9. Create Virtual Machines 🖥️
- Deploy virtual machines in the on-premises network with appropriate configurations.

10. Set Up Route Table for Traffic Routing 🗺️
- Create a route table to manage traffic routing between the on-premises network and the hub. Define routes to direct traffic through the VPN gateway.

11. Associate Route Table with Subnets 🔗
- Associate the route table with the subnets to enforce the routing rules and ensure proper traffic flow between on-premises and Azure.

# Diagram
![onprem](https://github.com/user-attachments/assets/d2a40c04-a1cc-4094-a087-37d2fc3fc19a)

### Apply the Terraform configurations :
Deploy the resources using Terraform,
- Initialize Terraform 🔄:
```
terraform init
```
- Plan the Deployment 📝:

```
terraform plan
```
- Apply the Configuration ✅:
```
terraform apply
```

```hcl

data "azurerm_client_config" "current" {}
data "azuread_client_config" "current" {}

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
      subnet_id = azurerm_subnet.subnets["GatewaySubnet"].id
    }
    depends_on = [ azurerm_subnet.subnets ]
  
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
# Managed Identity
resource "azurerm_user_assigned_identity" "base" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  name                = "mi-appgw-keyvault"
}

# Key Vault
resource "azurerm_key_vault" "kv" {
  name                = var.keyvault_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
  
  network_acls {
    bypass = "AzureServices"
    default_action = "Allow"
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_user_assigned_identity.base.principal_id
    
    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Backup",
      "Recover",
      "Purge"
    ]

    certificate_permissions = [
      "Get",
      "List",
      "Create",
      "Delete",
      "Update",
      "Import",
      "ManageContacts",
      "ManageIssuers",
      "Purge",
      "Recover"
    ]

    key_permissions = [
      "Get",
      "List",
      "Create",
      "Update",
      "Import",
      "Delete"
    ]
  }
}

# Key Vault Certificate
resource "azurerm_key_vault_certificate" "example" {
  name         = "generated-cert"
  key_vault_id = azurerm_key_vault.kv.id

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }

    lifetime_action {
      action {
        action_type = "AutoRenew"
      }

      trigger {
        days_before_expiry = 30
      }
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    x509_certificate_properties {
      extended_key_usage = ["1.3.6.1.5.5.7.3.1"]

      key_usage = [
        "cRLSign",
        "dataEncipherment",
        "digitalSignature",
        "keyAgreement",
        "keyCertSign",
        "keyEncipherment",
      ]

      subject_alternative_names {
        dns_names = ["internal.contoso.com", "domain.hello.world"]
      }

      subject            = "CN=hello-world"
      validity_in_months = 12
    }
  }
}

# Key Vault Secrets
resource "azurerm_key_vault_secret" "vm_admin_username" {
  name         = "aflalahusername"
  value        = var.admin_username
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "vm_admin_password" {
  name         = "aflalahpassword"
  value        = var.admin_password
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

- <a name="provider_azuread"></a> [azuread](#provider\_azuread)

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (~> 3.1.0)

## Resources

The following resources are used by this module:

- [azurerm_key_vault.kv](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault) (resource)
- [azurerm_key_vault_certificate.example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_certificate) (resource)
- [azurerm_key_vault_secret.vm_admin_password](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) (resource)
- [azurerm_key_vault_secret.vm_admin_username](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) (resource)
- [azurerm_local_network_gateway.onprem_local_network_gateway](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/local_network_gateway) (resource)
- [azurerm_network_interface.nic](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) (resource)
- [azurerm_public_ip.onprem_vnetgateway_pip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) (resource)
- [azurerm_resource_group.rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_route_table.spoke1-udr](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route_table) (resource)
- [azurerm_subnet.subnets](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) (resource)
- [azurerm_subnet_route_table_association.routetable--ass](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_route_table_association) (resource)
- [azurerm_user_assigned_identity.base](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) (resource)
- [azurerm_virtual_machine.vm](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine) (resource)
- [azurerm_virtual_network.onprem_vnets](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) (resource)
- [azurerm_virtual_network_gateway.onprem_vnetgateway](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_gateway) (resource)
- [azurerm_virtual_network_gateway_connection.onprem_vpn_connection](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_gateway_connection) (resource)
- [azuread_client_config.current](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/client_config) (data source)
- [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)
- [azurerm_public_ip.hub_publicip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/public_ip) (data source)
- [azurerm_virtual_network.hub_vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_network) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_address_space"></a> [address\_space](#input\_address\_space)

Description: Address space for the virtual network.

Type: `string`

### <a name="input_admin_password"></a> [admin\_password](#input\_admin\_password)

Description: n/a

Type: `string`

### <a name="input_admin_username"></a> [admin\_username](#input\_admin\_username)

Description: n/a

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
    data_disk_size_gb = number
    subnet           = string
  }))
```

### <a name="input_vnet_name"></a> [vnet\_name](#input\_vnet\_name)

Description: Name of the virtual network.

Type: `string`

## Optional Inputs

No optional inputs.

## Outputs

The following outputs are exported:

### <a name="output_resource_group_id"></a> [resource\_group\_id](#output\_resource\_group\_id)

Description: The ID of the Azure resource group.

### <a name="output_subnet_ids"></a> [subnet\_ids](#output\_subnet\_ids)

Description: Map of subnet names to their IDs in the on-premises virtual network.

### <a name="output_virtual_network_id"></a> [virtual\_network\_id](#output\_virtual\_network\_id)

Description: The ID of the on-premises virtual network.

## Modules

No modules.

#Contributing
We welcome contributions to improve this Terraform module.
<!-- END_TF_DOCS -->