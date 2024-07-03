<!-- BEGIN_TF_DOCS -->
# Spoke1 Resource Group

This Resource Group  including virtual networks (VNets) with subnets and network security groups (NSGs). The configuration is designed to be dynamic, allowing for scalable and customizable deployments.

```hcl

data "azurerm_client_config" "current" {}
data "azuread_client_config" "current" {}


resource "azurerm_resource_group" "rg" {
    name = var.rg.resource_group
    location = var.rg.location
}

#virtual Network
resource "azurerm_virtual_network" "vnets" {
    for_each = var.vnets

    name  = each.key
    address_space = [each.value.address_space]
    resource_group_name =azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
    
   
    depends_on = [ azurerm_resource_group.rg ]
}
#subnets

resource "azurerm_subnet" "subnets" {

    for_each = var.subnets

    name = each.value.name
    address_prefixes = [each.value.address_prefixes]
    resource_group_name = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnets[each.value.vnet].name
    depends_on = [ azurerm_virtual_network.vnets ]
  
}
#network security group
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

#NSG Asoocistion

resource "azurerm_subnet_network_security_group_association" "nsg-association" {
      for_each = var.subnets

      subnet_id = azurerm_subnet.subnets[each.key].id
      network_security_group_id = azurerm_network_security_group.nsg[each.key].id
      depends_on = [ azurerm_network_security_group.nsg,azurerm_subnet.subnets ]
}

#Network interface card
resource "azurerm_network_interface" "nic" {
    for_each = var.vms

    name = each.value.nic_name
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
    ip_configuration {
      name = "internal"
      subnet_id = azurerm_subnet.subnets[each.value.subnet].id
      private_ip_address_allocation = "Dynamic"
    }
  
}
#Availability set for Virtual machine
resource "azurerm_availability_set" "availability_set" {
  name                = "my-availability-set"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  platform_fault_domain_count = 3
  platform_update_domain_count = 5
}

#virtual machines
resource "azurerm_virtual_machine" "vm" {

    for_each = var.vms

    name = each.value.vm_name
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
    network_interface_ids = [azurerm_network_interface.nic[each.key].id]
    vm_size = each.value.vm_size
     
     availability_set_id = azurerm_availability_set.availability_set.id
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
    admin_username = azurerm_key_vault_secret.vm_admin_username[each.key].value
    admin_password = azurerm_key_vault_secret.vm_admin_password[each.key].value
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
depends_on = [ azurerm_recovery_services_vault.rsv,azurerm_backup_policy_vm.backup_policy ]
  
}

#Recovery service vault for backup

resource "azurerm_recovery_services_vault" "rsv" {

  name = var.rsv_name
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  sku = "Standard"
  
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

resource "azurerm_backup_protected_vm" "backup_protected" {
    for_each = azurerm_virtual_machine.vm
    resource_group_name = azurerm_resource_group.rg.name
    recovery_vault_name = azurerm_recovery_services_vault.rsv.name
    source_vm_id = each.value.id
    backup_policy_id = azurerm_backup_policy_vm.backup_policy.id
}

/*
resource "azurerm_storage_account" "stgacc" {
    
  name = "msystorageaccount"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  account_tier = "Standard"
  account_replication_type = "LRS"
  
  tags = {
    environment = "production"
  }
}

resource "azurerm_storage_share" "fileshare" {

  name = "myfilshare"
  storage_account_name = azurerm_storage_account.stgacc.name
  quota = 100
  

}
resource "azurerm_virtual_machine_extension" "file-share-mount" {
  for_each = var.vms
  name = "myfilesharemount-${each.key}"
  virtual_machine_id = azurerm_virtual_machine.vm[each.key].id
  publisher = "Microsoft.Compute"
  type = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = jsonencode({
    "commandToExecute" = "powershell.exe -ExecutionPolicy Unrestricted -File ${path.module}/mount-fileshare.ps1 -storageAccountName ${azurerm_storage_account.stgacc.name} -storageAccountKey ${azurerm_storage_account.stgacc.primary_access_key} -fileShareName ${azurerm_storage_share.fileshare.name} -mountPoint 'Z:'"
  })

  protected_settings = jsonencode({
    "storageAccountName" = azurerm_storage_account.stgacc.name
    "storageAccountKey"  = azurerm_storage_account.stgacc.primary_access_key
  })

  depends_on = [azurerm_virtual_machine.vm]
}

*/

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

    secret_permissions = [ "Get","Set", ]
  }
  
}

resource "azurerm_key_vault_secret" "vm_admin_username" {

  for_each = var.vms

  name = "${each.value.vm_name}-adminnusername"
  value = each.value.admin_username
  key_vault_id = azurerm_key_vault.kv.id
  
}

resource "azurerm_key_vault_secret" "vm_admin_password" {

  for_each = var.vms

  name = "${each.value.vm_name}-adminnnpassword"
  value = each.value.admin_password
  key_vault_id = azurerm_key_vault.kv.id
  
}

#route table for communicate between spoke1 n=and spoke2 through firewall
resource "azurerm_route_table" "spoke1-udr" {

  name = "spoke1-udr-to-firewall"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  route {
    name = "route-to-firewall"
    address_prefix = "10.0.0.0/25"
    next_hop_type = "VirtualAppliance"
    next_hop_in_ip_address = "10.10.3.4"
  }
  
}

resource "azurerm_subnet_route_table_association" "spoke1udr_subnet_association" {
    for_each = var.subnets

    subnet_id = azurerm_subnet.subnets[each.key].id
    route_table_id = azurerm_route_table.spoke1-udr.id
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

- [azurerm_availability_set.availability_set](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/availability_set) (resource)
- [azurerm_backup_policy_vm.backup_policy](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/backup_policy_vm) (resource)
- [azurerm_backup_protected_vm.backup_protected](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/backup_protected_vm) (resource)
- [azurerm_key_vault.kv](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault) (resource)
- [azurerm_key_vault_secret.vm_admin_password](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) (resource)
- [azurerm_key_vault_secret.vm_admin_username](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) (resource)
- [azurerm_network_interface.nic](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) (resource)
- [azurerm_network_security_group.nsg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) (resource)
- [azurerm_recovery_services_vault.rsv](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/recovery_services_vault) (resource)
- [azurerm_resource_group.rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_route_table.spoke1-udr](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route_table) (resource)
- [azurerm_subnet.subnets](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) (resource)
- [azurerm_subnet_network_security_group_association.nsg-association](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) (resource)
- [azurerm_subnet_route_table_association.spoke1udr_subnet_association](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_route_table_association) (resource)
- [azurerm_virtual_machine.vm](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine) (resource)
- [azurerm_virtual_network.vnets](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) (resource)
- [azuread_client_config.current](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/client_config) (data source)
- [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_backuppolicy_name"></a> [backuppolicy\_name](#input\_backuppolicy\_name)

Description: n/a

Type: `string`

### <a name="input_keyvault_name"></a> [keyvault\_name](#input\_keyvault\_name)

Description: n/a

Type: `string`

### <a name="input_rg"></a> [rg](#input\_rg)

Description: n/a

Type:

```hcl
object({
      resource_group =string
      location  = string
    })
```

### <a name="input_rsv_name"></a> [rsv\_name](#input\_rsv\_name)

Description: n/a

Type: `string`

### <a name="input_subnets"></a> [subnets](#input\_subnets)

Description: n/a

Type:

```hcl
map(object({
      name = string
      vnet = string
      address_prefixes = string
      
    }))
```

### <a name="input_vms"></a> [vms](#input\_vms)

Description: n/a

Type:

```hcl
map(object({
    vm_name = string
    nic_name = string
    host_name = string
    disk_name = string
    vm_size = string
    admin_username = string
    admin_password = string
    data_disk_size_gb = number
    subnet = string
  }))
```

### <a name="input_vnets"></a> [vnets](#input\_vnets)

Description: The virtual network value must not be empty

Type:

```hcl
map(object({
    address_space  = string
  }))
```

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_nsg_count"></a> [nsg\_count](#input\_nsg\_count)

Description: The count value must be in number

Type: `string`

Default: `2`

### <a name="input_rules_file"></a> [rules\_file](#input\_rules\_file)

Description: The rules files must be saved in .csv file name.

Type: `string`

Default: `"rules-20.csv"`

## Outputs

The following outputs are exported:

### <a name="output_current_object_id"></a> [current\_object\_id](#output\_current\_object\_id)

Description: n/a

### <a name="output_rg"></a> [rg](#output\_rg)

Description: n/a

### <a name="output_subnets"></a> [subnets](#output\_subnets)

Description: n/a

### <a name="output_vnets"></a> [vnets](#output\_vnets)

Description: n/a

## Modules

No modules.

## Contributing

We welcome contributions to improve this Terraform module.
<!-- END_TF_DOCS -->