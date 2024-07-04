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
- [azurerm_resource_group.rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)

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

## Optional Inputs

No optional inputs.

## Outputs

The following outputs are exported:

### <a name="output_app_service_default_hostname"></a> [app\_service\_default\_hostname](#output\_app\_service\_default\_hostname)

Description: n/a

### <a name="output_app_service_id"></a> [app\_service\_id](#output\_app\_service\_id)

Description: n/a

### <a name="output_app_service_identity"></a> [app\_service\_identity](#output\_app\_service\_identity)

Description: n/a

### <a name="output_app_service_inbound_ips"></a> [app\_service\_inbound\_ips](#output\_app\_service\_inbound\_ips)

Description: n/a

### <a name="output_app_service_outbound_ips"></a> [app\_service\_outbound\_ips](#output\_app\_service\_outbound\_ips)

Description: n/a

### <a name="output_app_service_plan_id"></a> [app\_service\_plan\_id](#output\_app\_service\_plan\_id)

Description: n/a

### <a name="output_app_service_site_credential"></a> [app\_service\_site\_credential](#output\_app\_service\_site\_credential)

Description: n/a

### <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name)

Description: n/a

## Modules

No modules.

## Contributing

We welcome contributions to improve this Terraform module.
<!-- END_TF_DOCS -->