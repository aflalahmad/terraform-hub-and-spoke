<!-- BEGIN_TF_DOCS -->
# Spoke1 Resource Group 🏢
This Resource Group includes virtual networks (VNets) with subnets, network security groups (NSGs), and additional resources. The configuration is designed to be dynamic, allowing for scalable and customizable deployments.

## Prerequisites ⚙️
### Before running this Terraform configuration, ensure you have the following prerequisites:

- Terraform installed on your local machine. 🛠️
- Azure CLI installed and authenticated. 🔑
- Proper access permissions to create resources in the Azure subscription. ✅
## Configuration Details 📝
### Data Sources 🔍
1. data "azurerm\_client\_config" "current"
- Retrieves the Azure credentials for the current subscription.

2. data "azuread\_client\_config" "current"
- Retrieves the Azure AD credentials for the current subscription.

### Resource Group 🗂️
3. resource "azurerm\_resource\_group" "rg"
- Creates an Azure Resource Group to organize and manage Azure resources.
Virtual Network 🌐
4. resource "azurerm\_virtual\_network" "vnets"
- Defines a Virtual Network (VNet) with specified address space and location, using the previously created Resource Group.
Subnets 🧩
5. resource "azurerm\_subnet" "subnets"
- Creates Subnets within the VNet, specifying address prefixes and associating them with the VNet.
Network Security Group (NSG) 🔒
6. resource "azurerm\_network\_security\_group" "nsg"
- Defines a Network Security Group (NSG) with security rules. Rules are dynamically created based on local variables.
NSG Association 🔗
7. resource "azurerm\_subnet\_network\_security\_group\_association" "nsg-association"
- Associates the NSG with the created subnets to enforce the security rules.
Network Interface Card (NIC) 💻
8. resource "azurerm\_network\_interface" "nic"
- Creates Network Interface Cards (NICs) for virtual machines, attaching them to the specified subnets.
Virtual Machines (VMs) 🖥️
9. resource "azurerm\_virtual\_machine" "vm"
- Deploys Virtual Machines using the defined NICs, with specified configurations for size, storage, and OS profile.
Recovery Services Vault 🛡️
10. resource "azurerm\_recovery\_services\_vault" "rsv"
- Creates a Recovery Services Vault for backing up VMs.

11. resource "azurerm\_backup\_policy\_vm" "backup\_policy"
- Defines a backup policy for the VMs with schedules and retention rules.

12. resource "azurerm\_backup\_protected\_vm" "backup\_protected"
- Associates VMs with the backup policy to enable backup.

### Key Vault 🔑
13. resource "azurerm\_key\_vault" "kv"
- Creates an Azure Key Vault for storing secrets such as VM admin usernames and passwords.

14. resource "azurerm\_key\_vault\_secret" "vm\_admin\_username"
- Stores VM admin usernames in the Key Vault.

15. resource "azurerm\_key\_vault\_secret" "vm\_admin\_password"
- Stores VM admin passwords in the Key Vault.

### Storage Account 📦
16. resource "azurerm\_storage\_account" "stgacc"
- Creates an Azure Storage Account for storing data.
Optional Resources 🛠️
17. resource "azurerm\_storage\_share" "fileshare"
- Defines a file share within the Storage Account.

18. resource "azurerm\_virtual\_machine\_extension" "file-share-mount"
- Uses a custom script to mount the file share on VMs.

19. resource "azurerm\_route\_table" "spoke1-udr"
- Defines a route table for traffic routing between spokes through a firewall.

20. resource "azurerm\_subnet\_route\_table\_association" "spoke1udr\_subnet\_association"
- Associates the route table with subnets.

21. resource "azurerm\_log\_analytics\_workspace" "log\_analytics"
- Creates a Log Analytics Workspace for monitoring and analytics.

22. resource "azurerm\_network\_watcher" "network\_watcher"
- Ensures a Network Watcher exists for network monitoring.

23. resource "azurerm\_network\_watcher\_flow\_log" "nsg\_flow\_log"
- Enables NSG flow logs for network traffic analysis.

24. resource "azurerm\_monitor\_diagnostic\_setting" "vnet\_diagnostics"
- Configures diagnostic settings for VNets to send logs to Log Analytics.

25. resource "azurerm\_policy\_definition" "diagnostics\_policy"
- Defines a custom Azure Policy to ensure diagnostics logs are enabled for resources.

26. resource "azurerm\_policy\_assignment" "assign\_policy"
- Assigns the diagnostics policy to a resource group.

# Diagram

![spoke1](Images/spoke1.png)

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

data "azurerm_client_config" "current" {}
data "azuread_client_config" "current" {}

#resouce group
resource "azurerm_resource_group" "rg" {
    name = var.rg.resource_group
    location = var.rg.location
}

#virtual Network
resource "azurerm_virtual_network" "vnets" {
    for_each = var.vnets

    name  = each.value.vnet_name
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

#virtual machines
resource "azurerm_virtual_machine" "vm" {

    for_each = var.vms

    name = each.value.vm_name
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
    network_interface_ids = [azurerm_network_interface.nic[each.key].id]
    vm_size = each.value.vm_size
     

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
    admin_username = data.azurerm_key_vault_secret.vm_admin_username.value
    admin_password = data.azurerm_key_vault_secret.vm_admin_password.value
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

#key vault for secret username and password
data "azurerm_key_vault" "kv" {
    name = "Aflalkeyvault7788"
    resource_group_name = "spoke1RG"
}
data "azurerm_key_vault_secret" "vm_admin_username" {
     name = "aflal_username"
     key_vault_id = data.azurerm_key_vault.kv.id
}
data "azurerm_key_vault_secret" "vm_admin_password" {
     name = "aflal_password"
     key_vault_id = data.azurerm_key_vault.kv.id
}
 
#using data block for Hub vnet
data "azurerm_virtual_network" "Hub_VNet" {
  name = "HubVNet"
  resource_group_name = "HubRG"
}
#spoke1 to hub peerings

resource "azurerm_virtual_network_peering" "spoke1_to_hub" {
    for_each = var.vnet_peerings

    name                     = "spoke1-to-hub-peering-${each.key}"  
    virtual_network_name     = azurerm_virtual_network.vnets.name
    remote_virtual_network_id = data.azurerm_virtual_network.Hub_VNet.id

    allow_forwarded_traffic    = each.value.allow_forwarded_traffic
    allow_gateway_transit      = each.value.allow_gateway_transit
    allow_virtual_network_access = each.value.allow_virtual_network_access

    resource_group_name = azurerm_resource_group.rg.name

    depends_on = [
        azurerm_virtual_network.vnets,
        data.azurerm_virtual_network.Hub_VNet
    ]
}

resource "azurerm_virtual_network_peering" "hub_to_spoke1" {
    for_each = var.vnet_peerings

    name                     = "hub-to-spoke1-peering-${each.key}" 
    virtual_network_name     = data.azurerm_virtual_network.Hub_VNet.name
    remote_virtual_network_id = azurerm_virtual_network.vnets.id

    allow_forwarded_traffic    = each.value.allow_forwarded_traffic
    allow_gateway_transit      = each.value.allow_gateway_transit
    allow_virtual_network_access = each.value.allow_virtual_network_access

    resource_group_name = azurerm_resource_group.rg.name

    depends_on = [
        azurerm_virtual_network.vnets,
        data.azurerm_virtual_network.Hub_VNet

    ]
}


#Recovery service vault for backup
resource "azurerm_recovery_services_vault" "rsv" {

  name = var.rsv_name
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  sku = "Standard"
  
}

#backup policy
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
 



#storage account for file share
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

#file share
resource "azurerm_storage_share" "fileshare" {

  name = "myfilshare"
  storage_account_name = azurerm_storage_account.stgacc.name
  quota = 100
  

}

# Create the mount-fileshare.ps1 PowerShell script
resource "local_file" "mount_fileshare_script" {
  filename = "${path.module}/mount-fileshare.ps1" # Path to save the script

  content = <<-EOF
  \$storageAccountName = "${azurerm_storage_account.stgacc.name}"
  \$shareName = "${azurerm_storage_share.fileshare.name}"
  \$storageAccountKey = "${azurerm_storage_account.stgacc.primary_access_key}"

  # Mount point for the file share
  \$mountPoint = "Z:"

  # Create the credential object
  \$user = "\$storageAccountName"
  \$pass = ConvertTo-SecureString -String "\$storageAccountKey" -AsPlainText -Force
  \$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList \$user, \$pass

  # Mount the file share
  New-PSDrive -Name \$mountPoint.Substring(0, 1) -PSProvider FileSystem -Root "\\\\\$storageAccountName.file.core.windows.net\\\$shareName" -Credential \$credential -Persist

  # Ensure the drive is mounted at startup
  \$script = "New-PSDrive -Name \$(\$mountPoint.Substring(0, 1)) -PSProvider FileSystem -Root '\\\\\$storageAccountName.file.core.windows.net\\\$shareName' -Credential (New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList \$user, \$pass) -Persist"
  \$scriptBlock = [scriptblock]::Create(\$script)
  Set-Content -Path C:\\mount-fileshare.ps1 -Value \$scriptBlock
  EOF
}



/*
# create private dns zone
resource "azurerm_private_dns_zone" "ptivate-dns-zone" {
  name = "privatelink.azurewebsites.net"
  resource_group_name = azurerm_resource_group.rg.name 
}
#hub vnet using data
data "azurerm_virtual_network" "hub_vnets" {
  name = "HubVNet"
  resource_group_name = "HubRG"
}
# attach virtual network link
resource "azurerm_private_dns_zone_virtual_network_link" "vnet-link-hub" {
   name = "vnetlink-hub"
   virtual_network_id = data.azurerm_virtual_network.hub_vnets.id
   private_dns_zone_name = azurerm_private_dns_zone.ptivate-dns-zone.name
   resource_group_name = azurerm_resource_group.rg.name
   depends_on = [ azurerm_private_dns_zone.ptivate-dns-zone ]
}
#create private endpoint
resource "azurerm_private_endpoint" "private_endpoint" {
  name = "private-endpoint-spoke1"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id = azurerm_subnet.subnets["spokesubnet1"].id
  private_service_connection {
    name = "privateserviceconnection"
    private_connection_resource_id = azurerm_storage_account.stgacc.id
    is_manual_connection = false
    subresource_names = ["file"]
  }
  depends_on = [ azurerm_subnet.subnets ]
}
#create dns record
resource "azurerm_private_dns_a_record" "dns_record" {
  name = "file1"
  zone_name = azurerm_private_dns_zone.pr_dns_zone.name
  resource_group_name = azurerm_private_dns_zone.pr_dns_zone.resource_group_name
  ttl = 300
  records = [ azurerm_private_endpoint.private_endpoint.private_service_connection[0].private_ip_address ]
  depends_on = [ azurerm_private_dns_zone.private_dns_zone , azurerm_private_endpoint.private_endpoint  ]
}

*/

/*
#route table for communicate between spoke1 and spoke2 through firewall
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

*/

/*
# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "log_analytics" {
  name                = var.log_analytics_workspace_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Ensure a Network Watcher exists in the region
resource "azurerm_network_watcher" "network_watcher" {
  name                = "networkWatcher_${var.rg.location}"
  location            = var.rg.location
  resource_group_name = "NetworkWatcherRG"
}

# Enable NSG Flow Logs
resource "azurerm_network_watcher_flow_log" "nsg_flow_log" {
  for_each                  = azurerm_network_security_group.nsg
  name                      = "nsg-flow-log-${each.key}"
  network_watcher_name      = azurerm_network_watcher.network_watcher.name
  resource_group_name       = azurerm_resource_group.rg.name
  network_security_group_id = each.value.id
  storage_account_id        = azurerm_storage_account.stgacc.id
  enabled                   = true

  retention_policy {
    enabled = true
    days    = 30
  }
 traffic_analytics {
    enabled               = true
    workspace_id          = azurerm_log_analytics_workspace.log_analytics.workspace_id
    workspace_region      = azurerm_log_analytics_workspace.log_analytics.location
    workspace_resource_id = azurerm_log_analytics_workspace.log_analytics.id
  }
}

# Enable VNet Flow Logs
resource "azurerm_monitor_diagnostic_setting" "vnet_diagnostics" {
  for_each            = azurerm_virtual_network.vnets
  name                = "vnet-diagnostics-${each.key}"
  target_resource_id  = each.value.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics.id

  log {
    category = "NetworkSecurityGroupEvent"
    enabled  = true
    retention_policy {
      enabled = true
      days    = 30
    }
  }

  log {
    category = "NetworkSecurityGroupRuleCounter"
    enabled  = true
    retention_policy {
      enabled = true
      days    = 30
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = true
    retention_policy {
      enabled = true
      days    = 30
    }
  }

  // Exclude unsupported category here
  dynamic "log" {
    for_each = [ "AuditEvent", "Alert", "Recommendation", "Policy" ]  # Update this list as per your needs
    content {
      category = log.value
      enabled  = true
      retention_policy {
        enabled = true
        days    = 30
      }
    }
  }
}


# Enable Diagnostics Logs via Azure Policy
resource "azurerm_policy_definition" "diagnostics_policy" {
  name         = "mypolicy"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Enable Diagnostics Logs"
  description  = "Ensure diagnostics logs are enabled for all resources"

  policy_rule = <<POLICY_RULE
{
  "if": {
    "field": "type",
    "in": [
      "Microsoft.Compute/virtualMachines",
      "Microsoft.Network/networkSecurityGroups",
      "Microsoft.Network/virtualNetworks"
    ]
  },
  "then": {
    "effect": "DeployIfNotExists",
    "details": {
      "type": "Microsoft.Insights/diagnosticSettings",
      "existenceCondition": {
        "field": "Microsoft.Insights/diagnosticSettings/logs[*].enabled",
        "equals": "true"
      },
      "roleDefinitionIds": [
        "/providers/Microsoft.Authorization/roleDefinitions/..."
      ],
      "deployment": {
        "properties": {
          "mode": "incremental",
          "template": {
            "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
            "contentVersion": "1.0.0.0",
            "resources": [
              {
                "type": "Microsoft.Insights/diagnosticSettings",
                "apiVersion": "2017-05-01-preview",
                "name": "[concat(parameters('resourceName'), '-diagnostics')]",
                "properties": {
                  "storageAccountId": "[parameters('storageAccountId')]",
                  "workspaceId": "[parameters('workspaceId')]",
                  "logs": [
                    {
                      "category": "AuditEvent",
                      "enabled": true,
                      "retentionPolicy": {
                        "enabled": true,
                        "days": 30
                      }
                    },
                    {
                      "category": "Alert",
                      "enabled": true,
                      "retentionPolicy": {
                        "enabled": true,
                        "days": 30
                      }
                    },
                    {
                      "category": "Recommendation",
                      "enabled": true,
                      "retentionPolicy": {
                        "enabled": true,
                        "days": 30
                      }
                    },
                    {
                      "category": "Policy",
                      "enabled": true,
                      "retentionPolicy": {
                        "enabled": true,
                        "days": 30
                      }
                    }
                  ]
                }
              }
            ]
          }
        }
      },
      "parameters": {
        "resourceName": {
          "type": "string",
          "metadata": {
            "description": "The name of the resource to enable diagnostics."
          }
        },
        "storageAccountId": {
          "type": "string",
          "metadata": {
            "description": "The ID of the storage account for diagnostic logs."
          }
        },
        "workspaceId": {
          "type": "string",
          "metadata": {
            "description": "The ID of the Log Analytics workspace."
          }
        }
      }
    }
  }
}
POLICY_RULE
}
resource "azurerm_policy_assignment" "assign_policy" {
  name                 = "assign-diagnostics-policy"
  scope                = azurerm_resource_group.rg.id
  policy_definition_id = azurerm_policy_definition.diagnostics_policy.id
  display_name         = "Assign Diagnostics Policy"
  description          = "Ensure diagnostics logs are enabled for all resources"
  
  parameters = jsonencode({
    resourceName     = null
    storageAccountId = azurerm_storage_account.stgacc.id
    workspaceId      = azurerm_log_analytics_workspace.log_analytics.id
  })

  depends_on = [
    azurerm_policy_definition.diagnostics_policy,
    azurerm_log_analytics_workspace.log_analytics,
    azurerm_storage_account.stgacc
  ]
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

- <a name="provider_azuread"></a> [azuread](#provider\_azuread)

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (~> 3.1.0)

- <a name="provider_local"></a> [local](#provider\_local)

## Resources

The following resources are used by this module:

- [azurerm_backup_policy_vm.backup_policy](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/backup_policy_vm) (resource)
- [azurerm_backup_protected_vm.backup_protected](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/backup_protected_vm) (resource)
- [azurerm_network_interface.nic](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) (resource)
- [azurerm_network_security_group.nsg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) (resource)
- [azurerm_recovery_services_vault.rsv](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/recovery_services_vault) (resource)
- [azurerm_resource_group.rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_storage_account.stgacc](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) (resource)
- [azurerm_storage_share.fileshare](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_share) (resource)
- [azurerm_subnet.subnets](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) (resource)
- [azurerm_subnet_network_security_group_association.nsg-association](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) (resource)
- [azurerm_virtual_machine.vm](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine) (resource)
- [azurerm_virtual_network.vnets](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) (resource)
- [azurerm_virtual_network_peering.hub_to_spoke1](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_peering) (resource)
- [azurerm_virtual_network_peering.spoke1_to_hub](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_peering) (resource)
- [local_file.mount_fileshare_script](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) (resource)
- [azuread_client_config.current](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/client_config) (data source)
- [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)
- [azurerm_key_vault.kv](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault) (data source)
- [azurerm_key_vault_secret.vm_admin_password](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault_secret) (data source)
- [azurerm_key_vault_secret.vm_admin_username](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault_secret) (data source)
- [azurerm_virtual_network.Hub_VNet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_network) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_backuppolicy_name"></a> [backuppolicy\_name](#input\_backuppolicy\_name)

Description: Name of the backup policy.

Type: `string`

### <a name="input_log_analytics_workspace_name"></a> [log\_analytics\_workspace\_name](#input\_log\_analytics\_workspace\_name)

Description: Name of the Log Analytics workspace.

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

### <a name="input_rsv_name"></a> [rsv\_name](#input\_rsv\_name)

Description: Name of the Reserved Instance.

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

### <a name="input_vm1"></a> [vm1](#input\_vm1)

Description: n/a

Type: `string`

### <a name="input_vms"></a> [vms](#input\_vms)

Description: Map of virtual machine configurations.

Type:

```hcl
map(object({
    vm_name          = string
    nic_name         = string
    host_name        = string
    disk_name        = string
    vm_size          = string
    admin_username   = string
    admin_password   = string
    data_disk_size_gb = number
    subnet           = string
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

### <a name="input_vnets"></a> [vnets](#input\_vnets)

Description: Map of virtual network details.

Type:

```hcl
map(object({
    vnet_name = strings
    address_space = string
  }))
```

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

### <a name="output_backup_policy_id"></a> [backup\_policy\_id](#output\_backup\_policy\_id)

Description: The ID of the backup policy.

### <a name="output_key_vault_id"></a> [key\_vault\_id](#output\_key\_vault\_id)

Description: The ID of the Azure Key Vault.

### <a name="output_network_interface_ids"></a> [network\_interface\_ids](#output\_network\_interface\_ids)

Description: Map of network interface names to their IDs.

### <a name="output_network_security_group_ids"></a> [network\_security\_group\_ids](#output\_network\_security\_group\_ids)

Description: Map of network security group names to their IDs.

### <a name="output_recovery_services_vault_id"></a> [recovery\_services\_vault\_id](#output\_recovery\_services\_vault\_id)

Description: The ID of the Azure Recovery Services Vault.

### <a name="output_resource_group_id"></a> [resource\_group\_id](#output\_resource\_group\_id)

Description: The ID of the Azure resource group.

### <a name="output_storage_account_id"></a> [storage\_account\_id](#output\_storage\_account\_id)

Description: The ID of the Azure Storage Account.

### <a name="output_subnet_ids"></a> [subnet\_ids](#output\_subnet\_ids)

Description: Map of subnet names to their IDs.

### <a name="output_virtual_machine_ids"></a> [virtual\_machine\_ids](#output\_virtual\_machine\_ids)

Description: Map of virtual machine names to their IDs.

### <a name="output_virtual_network_ids"></a> [virtual\_network\_ids](#output\_virtual\_network\_ids)

Description: Map of virtual network names to their IDs.

## Modules

No modules.

## Contributing

We welcome contributions to improve this Terraform module.
<!-- END_TF_DOCS -->