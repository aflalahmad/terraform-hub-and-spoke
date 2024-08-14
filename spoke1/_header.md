# Spoke1 Resource Group

This Resource Group  including virtual networks (VNets) with subnets and network security groups (NSGs). The configuration is designed to be dynamic, allowing for scalable and customizable deployments.

## Prerequisites

Before running this Terraform configuration, ensure you have the following prerequisites:
- Terraform installed on your local machine.
- Azure CLI installed and authenticated.
- Proper access permissions to create resources in the Azure subscription.
## Configuration details
## Data Sources
1. data "azurerm_client_config" "current" {}

- Retrieves the Azure credentials for the current subscription.
2. data "azuread_client_config" "current" {}

- Retrieves the Azure AD credentials for the current subscription.
## Resource Group
3. resource "azurerm_resource_group" "rg" {}
- Creates an Azure Resource Group to organize and manage Azure resources.
## Virtual Network
4. resource "azurerm_virtual_network" "vnets" {}
- Defines a Virtual Network (VNet) with specified address space and location, using the previously created Resource Group.
## Subnets
5. resource "azurerm_subnet" "subnets" {}
- Creates Subnets within the VNet, specifying address prefixes and associating them with the VNet.
## Network Security Group (NSG)
6. resource "azurerm_network_security_group" "nsg" {}
- Defines a Network Security Group (NSG) with security rules. Rules are dynamically created based on local variables.
## NSG Association
7. resource "azurerm_subnet_network_security_group_association" "nsg-association" {}
- Associates the NSG with the created subnets to enforce the security rules.
## Network Interface Card (NIC)
8. resource "azurerm_network_interface" "nic" {}
- Creates Network Interface Cards (NICs) for virtual machines, attaching them to the specified subnets.
## Virtual Machines (VMs)
9. resource "azurerm_virtual_machine" "vm" {}
- Deploys Virtual Machines using the defined NICs, with specified configurations for size, storage, and OS profile.
## Recovery Services Vault
10. resource "azurerm_recovery_services_vault" "rsv" {}

- Creates a Recovery Services Vault for backing up VMs.
11. resource "azurerm_backup_policy_vm" "backup_policy" {}

- Defines a backup policy for the VMs with schedules and retention rules.
12. resource "azurerm_backup_protected_vm" "backup_protected" {}

- Associates VMs with the backup policy to enable backup.
## Key Vault
13. resource "azurerm_key_vault" "kv" {}

- Creates an Azure Key Vault for storing secrets such as VM admin usernames and passwords.
14. resource "azurerm_key_vault_secret" "vm_admin_username" {}

- Stores VM admin usernames in the Key Vault.
15. resource "azurerm_key_vault_secret" "vm_admin_password" {}

- Stores VM admin passwords in the Key Vault.
## Storage Account
16. resource "azurerm_storage_account" "stgacc" {}
- Creates an Azure Storage Account for storing data.
Optional Resources
17. resource "azurerm_storage_share" "fileshare" {}

  - Defines a file share within the Storage Account.
18. resource "azurerm_virtual_machine_extension" "file-share-mount" {}

-  Uses a custom script to mount the file share on VMs.
19.  resource "azurerm_route_table" "spoke1-udr" {}
 - Defines a route table for traffic routing between spokes through a firewall.
20.  resource "azurerm_subnet_route_table_association" "spoke1udr_subnet_association" {}

- Associates the route table with subnets.
  
21.   resource "azurerm_log_analytics_workspace" "log_analytics" {}

- Creates a Log Analytics Workspace for monitoring and analytics.
22.  resource "azurerm_network_watcher" "network_watcher" {}

-  Ensures a Network Watcher exists for network monitoring.
23.  resource "azurerm_network_watcher_flow_log" "nsg_flow_log" {}

 - Enables NSG flow logs for network traffic analysis.
24.  resource "azurerm_monitor_diagnostic_setting" "vnet_diagnostics" {}

- Configures diagnostic settings for VNets to send logs to Log Analytics.
25.  resource "azurerm_policy_definition" "diagnostics_policy" {}

 - Defines a custom Azure Policy to ensure diagnostics logs are enabled for resources.
26.  resource "azurerm_policy_assignment" "assign_policy" {}

- Assigns the diagnostics policy to a resource group.

# Diagram

![spoke1](Images/spoke1.png)

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