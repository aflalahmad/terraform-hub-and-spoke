<!-- BEGIN_TF_DOCS -->
# Spoke2 Resource Group

This Resource Group  including virtual networks (VNets) with subnets and network security groups (NSGs) and virtual machine scale set. The configuration is designed to be dynamic, allowing for scalable and customizable deployments.
# Diagram

![Screenshot 2024-07-23 102202](https://github.com/user-attachments/assets/418e3838-b115-410f-ad80-5fca878ec5ad)

```hcl
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

    name = each.value.name
    address_prefixes = [each.value.address_prefixes]
    resource_group_name = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    depends_on = [ azurerm_virtual_network.vnet ]
}

#Network security group
resource "azurerm_network_security_group" "nsg" {
     for_each = var.subnets

     name = each.value.name
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
      for_each = var.subnets

      subnet_id = azurerm_subnet.subnets[each.key].id
      network_security_group_id = azurerm_network_security_group.nsg[each.key].id
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
    subnet_id = azurerm_subnet.subnets["AppGw-subnet"].id
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

data "azurerm_key_vault" "kv" {
    name = "Aflalkeyvault7766"
    resource_group_name = "spoke1RG"
}
data "azurerm_key_vault_secret" "vm_admin_username" {
     name = "aflal-pusername"
     key_vault_id = data.azurerm_key_vault.kv.id
}
data "azurerm_key_vault_secret" "vm_admin_password" {
     name = "aflal-ppassword"
     key_vault_id = data.azurerm_key_vault.kv.id
}


#Virtual machine scale set
resource "azurerm_windows_virtual_machine_scale_set" "vmss" {
  name                 = var.vmss_name
  resource_group_name  = azurerm_resource_group.rg.name
  location             = azurerm_resource_group.rg.location
  sku                  = var.sku
  instances            = var.instance
  admin_password       = data.azurerm_key_vault_secret.vm_admin_password.value
  admin_username       = data.azurerm_key_vault_secret.vm_admin_username.value
  computer_name_prefix = "vm-"

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter-Server-Core"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
  dynamic "network_interface" {
    for_each = azurerm_subnet.subnets

    content {
      name    = "example-${network_interface.key}"
      primary = network_interface.key == "subnet1"  

      ip_configuration {
        name      = "internal"
        primary   = network_interface.key == "subnet1"  
        subnet_id = network_interface.value.id
      }
    }
  }
}
/*
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
- [azurerm_network_security_group.nsg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) (resource)
- [azurerm_public_ip.public_ip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) (resource)
- [azurerm_resource_group.rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_subnet.subnets](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) (resource)
- [azurerm_subnet_network_security_group_association.nsg-association](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) (resource)
- [azurerm_virtual_network.vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) (resource)
- [azurerm_windows_virtual_machine_scale_set.vmss](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/windows_virtual_machine_scale_set) (resource)
- [azurerm_key_vault.kv](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault) (data source)
- [azurerm_key_vault_secret.vm_admin_password](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault_secret) (data source)
- [azurerm_key_vault_secret.vm_admin_username](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault_secret) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_admin_password"></a> [admin\_password](#input\_admin\_password)

Description: Admin password for virtual machines.

Type: `string`

### <a name="input_admin_username"></a> [admin\_username](#input\_admin\_username)

Description: Admin username for virtual machines.

Type: `string`

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

### <a name="output_route_table_ids"></a> [route\_table\_ids](#output\_route\_table\_ids)

Description: Map of route table names to their IDs.

### <a name="output_subnet_associations"></a> [subnet\_associations](#output\_subnet\_associations)

Description: Map of subnet names to their associated NSG associations.

### <a name="output_subnet_ids"></a> [subnet\_ids](#output\_subnet\_ids)

Description: Map of subnet names to their IDs.

### <a name="output_virtual_network_name"></a> [virtual\_network\_name](#output\_virtual\_network\_name)

Description: The name of the Azure virtual network.

### <a name="output_vmss_instances"></a> [vmss\_instances](#output\_vmss\_instances)

Description: List of instance IDs in the Azure virtual machine scale set.

### <a name="output_vmss_name"></a> [vmss\_name](#output\_vmss\_name)

Description: The name of the Azure virtual machine scale set.

## Modules

No modules.

## Contributing

We welcome contributions to improve this Terraform module.
<!-- END_TF_DOCS -->