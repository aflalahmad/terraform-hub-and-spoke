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