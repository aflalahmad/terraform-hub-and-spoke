<!-- BEGIN_TF_DOCS -->
# Backend Resource Group 🏗️

## Overview 🌐

This Terraform configuration script is used to create an Azure Resource Group and set up a Storage Account with a container to store Terraform state files.

## Prerequisites ⚙️
Before running this Terraform configuration, ensure you have the following prerequisites:

- Terraform installed on your local machine. 🛠️
- Azure CLI installed and authenticated. 🔑
- Proper access permissions to create resources in the Azure subscription. ✅
## Configuration Details 📝
### 1. Resource Group 🗂️
- 🛠️ Create Resource Group:
The configuration starts by creating a Resource Group in Azure, which will contain all other resources.

###  2. Storage Account 💾
- 🛠️ Create Storage Account:
Next, a Storage Account is created within the Resource Group. This account is configured with the Standard performance tier and locally redundant storage (LRS).

### 3. Storage Container 📦
- 🛠️ Create Storage Container:
A private container is created within the Storage Account to store Terraform state files securely.

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


#storage account
resource "azurerm_storage_account" "stgacc" {
    
  name = var.stgacc_name
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  account_tier = "Standard"
  account_replication_type = "LRS"
  
  tags = {
    environment = "production"
  }
}

# Create the Storage Account Container to store the state files
resource "azurerm_storage_container" "project_state" {
  name = var.container_name
  storage_account_name = azurerm_storage_account.stgacc.name
  container_access_type = "private"
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

- [azurerm_resource_group.rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_storage_account.stgacc](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) (resource)
- [azurerm_storage_container.project_state](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_container) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_container_name"></a> [container\_name](#input\_container\_name)

Description: The name of the Storage Account Container used to store state files.

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

### <a name="input_stgacc_name"></a> [stgacc\_name](#input\_stgacc\_name)

Description: The name of the Azure Storage Account. Must be unique within Azure.

Type: `string`

## Optional Inputs

No optional inputs.

## Outputs

The following outputs are exported:

### <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name)

Description: The name of the Resource Group

### <a name="output_storage_account_name"></a> [storage\_account\_name](#output\_storage\_account\_name)

Description: The name of the Storage Account

### <a name="output_storage_account_primary_blob_endpoint"></a> [storage\_account\_primary\_blob\_endpoint](#output\_storage\_account\_primary\_blob\_endpoint)

Description: The primary blob endpoint of the Storage Account

### <a name="output_storage_container_name"></a> [storage\_container\_name](#output\_storage\_container\_name)

Description: The name of the Storage Container

## Modules

No modules.

# Contributing

We welcome contributions to improve this Terraform module.
<!-- END_TF_DOCS -->