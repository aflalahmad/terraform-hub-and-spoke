# Spoke2 Resource Group

This Resource Group  including virtual networks (VNets) with subnets and network security groups (NSGs) and virtual machine scale set. The configuration is designed to be dynamic, allowing for scalable and customizable deployments.

## Prerequisites

Before running this Terraform configuration, ensure you have the following prerequisites:
- Terraform installed on your local machine.
- Azure CLI installed and authenticated.
- Proper access permissions to create resources in the Azure subscription.


## Configuration details
1. Create Resource Group
- First, create a resource group where all resources will be deployed.

1. Create Virtual Network
- Next, create a virtual network.

1. Create Subnets
- Create multiple subnets within the virtual network.

1. Create Network Security Groups
- Define Network Security Groups (NSGs) to manage inbound and outbound traffic rules for each subnet.

1. Associate NSGs with Subnets
- Link each subnet with its corresponding NSG to enforce the traffic rules defined.

1. Create Public IP for Application Gateway
- Set up a public IP address for the Application Gateway, ensuring it has a static allocation method and is of the Standard SKU.

1. Create Application Gateway
- Deploy an Application Gateway in its dedicated subnet, configuring it with the necessary settings such as IP configurations, front-end ports, back-end address pools, HTTP settings, listeners, and routing rules.

1. Retrieve Secrets from Key Vault
- Access the Azure Key Vault to retrieve the VM admin username and password, ensuring secure credential management.

1. Create Virtual Machine Scale Set
- Deploy a Virtual Machine Scale Set (VMSS) with the desired configuration, including instance count, admin credentials, source image, and network interface settings.

1.   Set Up Daily Backup for VMs
- Configure a Recovery Services Vault and define a backup policy with daily backups, retention settings, and protection for VM scale sets.

1.   Apply Azure Policy for Regional Deployment
- Create and assign an Azure Policy to limit service deployments to specific regions, ensuring compliance with organizational policies.

1.   Apply Azure Policy at Resource Group Level
- Scope all Azure Policies to the Resource Group level for better management and control.

1.   Create Route Table for Communication Between Spokes
- Set up a route table to manage traffic between spokes through the firewall, ensuring secure and efficient communication within the network architecture.


# Diagram

![Spoke2](Images/spoke2.png)

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