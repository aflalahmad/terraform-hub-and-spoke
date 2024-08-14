<!-- BEGIN_TF_DOCS -->
# Spoke3 Resource Group

This Resource Group  including App service and app service plan. The configuration is designed to be dynamic, allowing for scalable and customizable deployments.
## Prerequisites

Before running this Terraform configuration, ensure you have the following prerequisites:
- Terraform installed on your local machine.
- Azure CLI installed and authenticated.
- Proper access permissions to create resources in the Azure subscription.

## Configuration details
1. Resource Group
- Start by creating a resource group where all your resources will be deployed.

2. App Service Plan
- Create an App Service Plan in the resource group. Specify the pricing tier and size as per your requirements.

3. App Service
- Create an App Service within the App Service Plan. Define the app service name and associate it with the previously created plan.

4. Virtual Network
- Create a Virtual Network in the resource group. Define the address space for the network.

5. Subnet
- Create a Subnet within the Virtual Network. Define the address prefix for the subnet.

6. Integrate App Service with Virtual Network
- Integrate the App Service into the Virtual Network by connecting it to the Subnet.

7. Optional: Configure Recovery Services Vault for Backup
= Configure a Recovery Services Vault and define a backup policy for virtual machines. This step is optional but recommended for data protection.

# Diagram

![spoke3](Images/spoke3.png)

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
#create resource group
resource "azurerm_resource_group" "rg" {
    name = var.rg.resource_group
    location = var.rg.location
}

#app service plan
resource "azurerm_app_service_plan" "appservice_plan" {
    
    name = var.appserviceplan_name
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    sku {
      tier = "Basic"
      size = "B1"
    }
    kind = "Windows"
}

#app service
resource "azurerm_app_service" "app_service" {
  name =var.appservice_name
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  app_service_plan_id = azurerm_app_service_plan.appservice_plan.id

  
}

#virtual network
resource "azurerm_virtual_network" "spoke3vnet" {
   for_each = var.vnet_details
  name = each.value.vnet_name
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  address_space = [each.value.address_space]
  depends_on = [ azurerm_resource_group.rg ]
  
}

#subnet
resource "azurerm_subnet" "subnets" {
  

  for_each = var.subnet_details
  name = each.key
  address_prefixes = [each.value.address_prefix]
  virtual_network_name = azurerm_virtual_network.spoke3vnet.name
  resource_group_name = azurerm_resource_group.rg.name
 dynamic "delegation" {
    for_each = each.key == "appservice" ? [1] : []
    content{
        name = "appservice_delegation"
        service_delegation {
        name = "Microsoft.Web/serverFarms"
        actions = [
        "Microsoft.Network/virtualNetworks/subnets/action"
      ]
    }
    }
    
  }
  depends_on = [ azurerm_virtual_network.spoke3vnet ]
}
 

#intergrate to hub
resource "azurerm_app_service_virtual_network_swift_connection" "vnet_integration" {
  app_service_id = azurerm_app_service.app_service.id
  subnet_id = azurerm_subnet.subnets["webapp"].id
  depends_on = [ azurerm_app_service.app_service,azurerm_subnet.subnets]
}

#using data block for Hub vnet
data "azurerm_virtual_network" "Hub_VNet" {
  name = "HubVNet"
  resource_group_name = "HubRG"
}


resource "azurerm_virtual_network_peering" "spoke3_to_hub" {
    for_each = var.vnet_peerings

    name                     = "spoke3-to-hub-peering-${each.key}"  
    virtual_network_name     = azurerm_virtual_network.spoke3vnet.name
    remote_virtual_network_id = data.azurerm_virtual_network.Hub_VNet.id

    allow_forwarded_traffic    = each.value.allow_forwarded_traffic
    allow_gateway_transit      = each.value.allow_gateway_transit
    allow_virtual_network_access = each.value.allow_virtual_network_access

    resource_group_name = azurerm_resource_group.rg.name

    depends_on = [
        azurerm_virtual_network.spoke3vnet,
        data.azurerm_virtual_network.Hub_VNet
    ]
}

resource "azurerm_virtual_network_peering" "hub_to_spoke3" {
    for_each = var.vnet_peerings

    name                     = "hub-to-spoke3-peering-${each.key}" 
    virtual_network_name     = data.azurerm_virtual_network.Hub_VNet.name
    remote_virtual_network_id =azurerm_virtual_network.spoke3vnet.id

    allow_forwarded_traffic    = each.value.allow_forwarded_traffic
    allow_gateway_transit      = each.value.allow_gateway_transit
    allow_virtual_network_access = each.value.allow_virtual_network_access

    resource_group_name = azurerm_resource_group.rg.name

    depends_on = [
        azurerm_virtual_network.spoke3vnet,
        data.azurerm_virtual_network.Hub_VNet

    ]
}



/*
#Recovery service vault for backup

resource "azurerm_recovery_services_vault" "rsv" {

  name = "rsv"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  sku = "Standard"
  
}

resource "azurerm_backup_policy_vm" "backup_policy" {
  name                = "backup-policy"
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

- [azurerm_app_service.app_service](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/app_service) (resource)
- [azurerm_app_service_plan.appservice_plan](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/app_service_plan) (resource)
- [azurerm_app_service_virtual_network_swift_connection.vnet_integration](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/app_service_virtual_network_swift_connection) (resource)
- [azurerm_resource_group.rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_subnet.subnets](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) (resource)
- [azurerm_virtual_network.spoke3vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) (resource)
- [azurerm_virtual_network_peering.hub_to_spoke3](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_peering) (resource)
- [azurerm_virtual_network_peering.spoke3_to_hub](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_peering) (resource)
- [azurerm_virtual_network.Hub_VNet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_network) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_appservice_name"></a> [appservice\_name](#input\_appservice\_name)

Description: Name of the App Service.

Type: `string`

### <a name="input_appserviceplan_name"></a> [appserviceplan\_name](#input\_appserviceplan\_name)

Description: Name of the App Service Plan.

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

### <a name="input_vnet_details"></a> [vnet\_details](#input\_vnet\_details)

Description: The details of the VNET

Type:

```hcl
map(object({
    vnet_name = string
    address_space = string
  }))
```

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

### <a name="output_app_service_default_hostname"></a> [app\_service\_default\_hostname](#output\_app\_service\_default\_hostname)

Description: The default hostname of the Azure App Service.

### <a name="output_app_service_id"></a> [app\_service\_id](#output\_app\_service\_id)

Description: The ID of the Azure App Service.

### <a name="output_app_service_identity"></a> [app\_service\_identity](#output\_app\_service\_identity)

Description: The managed service identity of the Azure App Service.

### <a name="output_app_service_inbound_ips"></a> [app\_service\_inbound\_ips](#output\_app\_service\_inbound\_ips)

Description: The inbound IP addresses of the Azure App Service.

### <a name="output_app_service_outbound_ips"></a> [app\_service\_outbound\_ips](#output\_app\_service\_outbound\_ips)

Description: The outbound IP addresses of the Azure App Service.

### <a name="output_app_service_plan_id"></a> [app\_service\_plan\_id](#output\_app\_service\_plan\_id)

Description: The ID of the Azure App Service Plan.

### <a name="output_app_service_site_credential"></a> [app\_service\_site\_credential](#output\_app\_service\_site\_credential)

Description: The site credentials of the Azure App Service.

### <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name)

Description: The name of the Azure resource group.

## Modules

No modules.

# Contributing

We welcome contributions to improve this Terraform module.
<!-- END_TF_DOCS -->