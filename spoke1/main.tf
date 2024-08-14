
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
 


/*
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

#fileshare extension
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

