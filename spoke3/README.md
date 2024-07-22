<!-- BEGIN_TF_DOCS -->
# Spoke3 Resource Group

This Resource Group  including App service and app service plan. The configuration is designed to be dynamic, allowing for scalable and customizable deployments.

```hcl
resource "azurerm_resource_group" "rg" {
    name = var.rg.resource_group
    location = var.rg.location
}

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

resource "azurerm_app_service" "app_service" {
  name =var.appservice_name
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  app_service_plan_id = azurerm_app_service_plan.appservice_plan.id

  
}

resource "azurerm_virtual_network" "spoke3vnet" {

  name = var.vnet_name
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  address_space = "10.100.0.0/16"
  
}

resource "azurerm_subnet" "subnets" {
  
  name = "spoke3-subnet"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.spoke3vnet.name
  address_prefixes = "10.100.1.0/24"
}

#intergrate to hub
resource "azurerm_app_service_virtual_network_swift_connection" "vnet_integration" {
  app_service_id = azurerm_app_service.app_service.id
  subnet_id = azurerm_subnet.subnets.id
  depends_on = [ azurerm_app_service.app_service,azurerm_subnet.subnets]
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

- [azurerm_app_service.app_service](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/app_service) (resource)
- [azurerm_app_service_plan.appservice_plan](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/app_service_plan) (resource)
- [azurerm_app_service_virtual_network_swift_connection.vnet_integration](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/app_service_virtual_network_swift_connection) (resource)
- [azurerm_resource_group.rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_subnet.subnets](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) (resource)
- [azurerm_virtual_network.spoke3vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) (resource)

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

### <a name="input_vnet_name"></a> [vnet\_name](#input\_vnet\_name)

Description: Name of the virtual network.

Type: `string`

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

## Contributing

We welcome contributions to improve this Terraform module.
<!-- END_TF_DOCS -->