<!-- BEGIN_TF_DOCS -->
# Spoke2 Resource Group 🏠
This Resource Group includes virtual networks (VNets) with subnets and network security groups (NSGs) and a Virtual Machine Scale Set (VMSS). The configuration is designed to be dynamic, allowing for scalable and customizable deployments.

## Prerequisites ⚙️
### Before running this Terraform configuration, ensure you have the following prerequisites:

- Terraform installed on your local machine. 🛠️
- Azure CLI installed and authenticated. 🔑
- Proper access permissions to create resources in the Azure subscription. ✅
## Configuration Details 📝
1. Create Resource Group 🗂️

- First, create a resource group where all resources will be deployed.
2 .Create Virtual Network 🌐

- Next, create a virtual network.
3. Create Subnets 🔲

- Create multiple subnets within the virtual network.
4. Create Network Security Groups 🔒

- Define Network Security Groups (NSGs) to manage inbound and outbound traffic rules for each subnet.
5. Associate NSGs with Subnets 🔗

- Link each subnet with its corresponding NSG to enforce the traffic rules defined.
6. Create Public IP for Application Gateway 🌍

- Set up a public IP address for the Application Gateway, ensuring it has a static allocation method and is of the Standard SKU.
7. Create Application Gateway 🛡️

- Deploy an Application Gateway in its dedicated subnet, configuring it with the necessary settings such as IP configurations, front-end ports, back-end address pools, HTTP settings, listeners, and routing rules.
8. Retrieve Secrets from Key Vault 🔑

- Access the Azure Key Vault to retrieve the VM admin username and password, ensuring secure credential management.
9. Create Virtual Machine Scale Set 🖥️

- Deploy a Virtual Machine Scale Set (VMSS) with the desired configuration, including instance count, admin credentials, source image, and network interface settings.
10. Set Up Daily Backup for VMs 💾

- Configure a Recovery Services Vault and define a backup policy with daily backups, retention settings, and protection for VM scale sets.
11. Apply Azure Policy for Regional Deployment 🌍

- Create and assign an Azure Policy to limit service deployments to specific regions, ensuring compliance with organizational policies.
12. Apply Azure Policy at Resource Group Level 📜

- Scope all Azure Policies to the Resource Group level for better management and control.
13. Create Route Table for Communication Between Spokes 🛣️

- Set up a route table to manage traffic between spokes through the firewall, ensuring secure and efficient communication within the network architecture.

# Diagram

![spoke2](https://github.com/user-attachments/assets/7c5b8a3b-7913-412e-a0c2-828c07a1449a)

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
#create resource group
resource "azurerm_resource_group" "rg" {
    name = var.rg.resource_group
    location = var.rg.location
}
#virtual network
resource "azurerm_virtual_network" "vnet" {
  name = var.vnet_name
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  address_space = ["10.0.0.0/24"]
}
#subnets
resource "azurerm_subnet" "subnets" {

    for_each = var.subnets

    name = each.key
    address_prefixes = [each.value.address_prefixes]
    resource_group_name = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    depends_on = [ azurerm_virtual_network.vnet ]
}

#Network security group
resource "azurerm_network_security_group" "nsg" {
     for_each = var.subnets

     name = each.key
     resource_group_name = azurerm_resource_group.rg.name
     location = azurerm_resource_group.rg.location

     dynamic "security_rule" {
        for_each = { for rule in local.rules_csv : rule.name => rule }
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
     }
}
#nsg association
resource "azurerm_subnet_network_security_group_association" "nsg-association" {

      subnet_id = azurerm_subnet.subnets["spoke2subnet1"].id
      network_security_group_id = azurerm_network_security_group.nsg["spoke2subnet1"].id
      depends_on = [ azurerm_network_security_group.nsg,azurerm_subnet.subnets ]
}

# Create the Public IP for Application Gateway
resource "azurerm_public_ip" "public_ip" {
  name                = "AppGateway-pip"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Create the Application for their dedicated subnet
resource "azurerm_application_gateway" "appGW" {
  name                = "App-Gateway"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "appgw-ip-config"
    subnet_id = azurerm_subnet.subnets["AppGw"].id
  }

  frontend_ip_configuration {
    name                 = "appgw-frontend-ip"
    public_ip_address_id = azurerm_public_ip.public_ip.id
  }

  frontend_port {
    name = "frontend-port"
    port = 80
  }

  backend_address_pool {
    name = "appgw-backend-pool"
    
  }

  backend_http_settings {
    name                  = "appgw-backend-http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 20
  }

  http_listener {
    name                           = "appgw-http-listener"
    frontend_ip_configuration_name = "appgw-frontend-ip"
    frontend_port_name             = "frontend-port"
    protocol                       = "Http"
    ssl_certificate_name = "app-listener"
  }

  identity {
    type = "UserAssigned"
    identity_ids = [ data.azurerm_user_assigned_identity.base.id ]
  }

  ssl_certificate {
    name = "app-listener"
    key_vault_secret_id = data.azurerm_key_vault_certificate.example.secret_id
  }

  request_routing_rule {
    name                       = "appgw-routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "appgw-http-listener"
    backend_address_pool_name  = "appgw-backend-pool"
    backend_http_settings_name = "appgw-backend-http-settings"
  }
    depends_on = [azurerm_resource_group.rg ,azurerm_subnet.subnets ,azurerm_public_ip.public_ip]
 }

#key vault for secret username and password
data "azurerm_key_vault" "kv" {
    name = "Aflalkeyvault7788"
    resource_group_name = "onprem_RG"
}
data "azurerm_key_vault_secret" "vm_admin_username" {
     name = "aflalahusername"
     key_vault_id = data.azurerm_key_vault.kv.id
}
data "azurerm_key_vault_secret" "vm_admin_password" {
     name = "aflalahpassword"
     key_vault_id = data.azurerm_key_vault.kv.id
}

#user identity using data block
data "azurerm_user_assigned_identity" "base" {
  name = "mi-appgw-keyvault"
  resource_group_name = "onprem_RG"
}

# key vault certificate using data block
data "azurerm_key_vault_certificate" "example" {
  name = "generated-cert"
  key_vault_id = data.azurerm_key_vault.kv.id
}

#Virtual machine scale set
resource "azurerm_windows_virtual_machine_scale_set" "vmss" {
  name                = var.vmss_name
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  sku = var.sku
  instances = var.instance
  admin_username = data.azurerm_key_vault_secret.vm_admin_username.value
  admin_password = data.azurerm_key_vault_secret.vm_admin_password.value
  network_interface {
    name = "myvmssname"
    primary = true
    ip_configuration {
      name = "internal"
      subnet_id = azurerm_subnet.subnets["spoke2subnet1"].id
      application_gateway_backend_address_pool_ids = local.application_gateway_backend_address_pool_ids
    }
  }
  os_disk {
    caching = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}

#using data block for Hub vnet
data "azurerm_virtual_network" "Hub_VNet" {
  name = "HubVNet"
  resource_group_name = "HubRG"
}
#spoke2 to hub peerings
resource "azurerm_virtual_network_peering" "spoke2_to_hub" {

    name                     = "spoke2-to-hub-peering"  
    virtual_network_name     = azurerm_virtual_network.vnet.name
    remote_virtual_network_id = data.azurerm_virtual_network.Hub_VNet.id

      allow_virtual_network_access = true
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
  use_remote_gateways       = false


    resource_group_name = azurerm_resource_group.rg.name

    depends_on = [
        azurerm_virtual_network.vnet,
        data.azurerm_virtual_network.Hub_VNet
    ]
}

resource "azurerm_virtual_network_peering" "hub_to_spoke2" {

    name                     = "hub-to-spoke2-peering" 
    virtual_network_name     = data.azurerm_virtual_network.Hub_VNet.name
    remote_virtual_network_id = azurerm_virtual_network.vnet.id

 allow_virtual_network_access = true
  allow_forwarded_traffic   = true
  allow_gateway_transit     = true
  use_remote_gateways       = false

    resource_group_name = data.azurerm_virtual_network.Hub_VNet.resource_group_name

    depends_on = [
        azurerm_virtual_network.vnet,
        data.azurerm_virtual_network.Hub_VNet

    ]
}


#Daily backup for VM
# Recovery Services Vault
resource "azurerm_recovery_services_vault" "rsv" {
  name                = var.rsv_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"
}

resource "azurerm_backup_policy_vm" "backup_policy" {
  name                = var.backuppolicy_name
  resource_group_name = azurerm_resource_group.rg.name
  recovery_vault_name = azurerm_recovery_services_vault.rsv.name

  backup {
    frequency = "Daily"
    time      = "12:00"
  }

  retention_daily {
    count = 30
  }

  retention_weekly {
    count   = 5
    weekdays = ["Monday"]
  }

  retention_monthly {
    count   = 12
    weekdays = ["Monday"]
    weeks    = ["First"]
  }

  retention_yearly {
    count   = 1
    weekdays = ["Monday"]
    months   = ["January"]
    weeks    = ["First"]
  }
}


# Backup Protection for VM Scale Set
/*
resource "azurerm_backup_protected_vm" "backup_protected" {
  count               = var.instance
  resource_group_name = azurerm_resource_group.rg.name
  recovery_vault_name = azurerm_recovery_services_vault.rsv.name
  source_vm_id        = azurerm_windows_virtual_machine_scale_set.vmss.virtual_machine_id[count.index]
  backup_policy_id    = azurerm_backup_policy_vm.backup_policy.id
  depends_on = [ azurerm_windows_virtual_machine_scale_set.vmss,azurerm_backup_policy_vm.backup_policy ]
}


#Service deployments should be limited to specific Azure regions via Azure Policy. 
resource "azurerm_policy_definition" "limit_deployment_regions" {
  name         = "limiteddeployment-regions"
  display_name = "Limit Azure Resource Deployments to Specific Regions"
  description  = "Ensures that resources are deployed only in specific Azure regions."
  mode = "Indexed"
  policy_type = "Custom"

  policy_rule = jsonencode({
    "if": {
      "not": {
        "field": "location",
        "in": [
          "East US",
          "West Europe",
          "Southeast Asia",
          "West US"
        ]
      }
    },
    "then": {
      "effect": "deny"
    }
  })
}
#All Azure Policies should be scoped to the Resource Group level. 
resource "azurerm_resource_group_policy_assignment" "example" {
  name                 = "example"
  resource_group_id    = azurerm_resource_group.rg.id
  policy_definition_id = azurerm_policy_definition.limit_deployment_regions.id

}

*/
#route table for communicate between spoke2 t0 spoke1 through firewall
/*
resource "azurerm_route_table" "spoke2-udr" {

  name = "spoke2-udr-to-firewall"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  route {
    name = "route-to-firewall"
    address_prefix = "10.30.1.0/24"
    next_hop_type = "VirtualAppliance"
    next_hop_in_ip_address = "10.10.3.4"
  }
  
}

resource "azurerm_subnet_route_table_association" "spoke1udr_subnet_association" {
    for_each = var.subnets

    subnet_id = azurerm_subnet.subnets[each.key].id
    route_table_id = azurerm_route_table.spoke2-udr.id
}
*/
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

- [azurerm_application_gateway.appGW](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_gateway) (resource)
- [azurerm_backup_policy_vm.backup_policy](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/backup_policy_vm) (resource)
- [azurerm_network_security_group.nsg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) (resource)
- [azurerm_public_ip.public_ip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) (resource)
- [azurerm_recovery_services_vault.rsv](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/recovery_services_vault) (resource)
- [azurerm_resource_group.rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_subnet.subnets](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) (resource)
- [azurerm_subnet_network_security_group_association.nsg-association](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) (resource)
- [azurerm_virtual_network.vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) (resource)
- [azurerm_virtual_network_peering.hub_to_spoke2](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_peering) (resource)
- [azurerm_virtual_network_peering.spoke2_to_hub](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_peering) (resource)
- [azurerm_windows_virtual_machine_scale_set.vmss](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/windows_virtual_machine_scale_set) (resource)
- [azurerm_key_vault.kv](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault) (data source)
- [azurerm_key_vault_certificate.example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault_certificate) (data source)
- [azurerm_key_vault_secret.vm_admin_password](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault_secret) (data source)
- [azurerm_key_vault_secret.vm_admin_username](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault_secret) (data source)
- [azurerm_user_assigned_identity.base](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/user_assigned_identity) (data source)
- [azurerm_virtual_network.Hub_VNet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_network) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_backuppolicy_name"></a> [backuppolicy\_name](#input\_backuppolicy\_name)

Description: Name of the backup policy.

Type: `string`

### <a name="input_instance"></a> [instance](#input\_instance)

Description: Instance count.

Type: `number`

### <a name="input_rg"></a> [rg](#input\_rg)

Description: Specifies the resource group details.

Type:

```hcl
object({
    resource_group = string
    location       = string
  })
```

### <a name="input_rsv_name"></a> [rsv\_name](#input\_rsv\_name)

Description: Name of the Reserved Instance.

Type: `string`

### <a name="input_sku"></a> [sku](#input\_sku)

Description: SKU of the product.

Type: `string`

### <a name="input_subnets"></a> [subnets](#input\_subnets)

Description: Map of subnet configurations.

Type:

```hcl
map(object({
    name             = string
    vnet             = string
    address_prefixes = string
  }))
```

### <a name="input_vmss_name"></a> [vmss\_name](#input\_vmss\_name)

Description: Name of the Virtual Machine Scale Set (VMSS).

Type: `string`

### <a name="input_vnet_name"></a> [vnet\_name](#input\_vnet\_name)

Description: Name of the virtual network.

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_nsg_count"></a> [nsg\_count](#input\_nsg\_count)

Description: Number of NSGs to deploy.

Type: `string`

Default: `"2"`

### <a name="input_rules_file"></a> [rules\_file](#input\_rules\_file)

Description: Name of the CSV file containing rules.

Type: `string`

Default: `"rules-20.csv"`

## Outputs

The following outputs are exported:

### <a name="output_nsg_ids"></a> [nsg\_ids](#output\_nsg\_ids)

Description: Map of network security group names to their IDs.

### <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name)

Description: The name of the Azure resource group.

### <a name="output_subnet_ids"></a> [subnet\_ids](#output\_subnet\_ids)

Description: Map of subnet names to their IDs.

### <a name="output_virtual_network_name"></a> [virtual\_network\_name](#output\_virtual\_network\_name)

Description: The name of the Azure virtual network.

### <a name="output_vmss_name"></a> [vmss\_name](#output\_vmss\_name)

Description: The name of the Azure virtual machine scale set.

## Modules

No modules.

## Contributing

We welcome contributions to improve this Terraform module.
<!-- END_TF_DOCS -->