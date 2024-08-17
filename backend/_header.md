# backend resource group

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
terraform plan "--var-file=variables.tfvars"
```
- Apply the Configuration ✅:
```
terraform apply "--var-file=variables.tfvars"
```