
data "azurerm_client_config" "current" {}
data "azuread_client_config" "current" {}


resource "azurerm_resource_group" "rg" {
    name = var.rg.resource_group
    location = var.rg.location
}

#virtual Network
resource "azurerm_virtual_network" "vnets" {
    for_each = var.vnets

    name  = each.key
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
#Availability set for Virtual machine
resource "azurerm_availability_set" "availability_set" {
  name                = "my-availability-set"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  platform_fault_domain_count = 3
  platform_update_domain_count = 5
}

#virtual machines
resource "azurerm_virtual_machine" "vm" {

    for_each = var.vms

    name = each.value.vm_name
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
    network_interface_ids = [azurerm_network_interface.nic[each.key].id]
    vm_size = each.value.vm_size
     
     availability_set_id = azurerm_availability_set.availability_set.id
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
    admin_username = azurerm_key_vault_secret.vm_admin_username[each.key].value
    admin_password = azurerm_key_vault_secret.vm_admin_password[each.key].value
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

#Recovery service vault for backup

resource "azurerm_recovery_services_vault" "rsv" {

  name = var.rsv_name
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  sku = "Standard"
  
}

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
/*
resource "azurerm_storage_share" "fileshare" {

  name = "myfilshare"
  storage_account_name = azurerm_storage_account.stgacc.name
  quota = 100
  

}
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

#key vault for storing username and password
resource "azurerm_key_vault" "kv" {

  name = var.keyvault_name
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  tenant_id = data.azurerm_client_config.current.tenant_id
  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azuread_client_config.current.object_id

    secret_permissions = [ "Get","Set", ]
  }
  
}

resource "azurerm_key_vault_secret" "vm_admin_username" {

  for_each = var.vms

  name = "${each.value.vm_name}-adminn-username1"
  value = each.value.admin_username
  key_vault_id = azurerm_key_vault.kv.id
  
}

resource "azurerm_key_vault_secret" "vm_admin_password" {

  for_each = var.vms

  name = "${each.value.vm_name}-adminn-npassword2"
  value = each.value.admin_password
  key_vault_id = azurerm_key_vault.kv.id
  
}

#route table for communicate between spoke1 n=and spoke2 through firewall
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

 #Create a Log Analytics Workspace

 resource "azurerm_log_analytics_workspace" "log_analytics" {
  name                = var.log_analytics_workspace_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

#Enable NSG Flow Logs

resource "azurerm_network_watcher" "network_watcher" {
  name                = "example-network-watcher"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_watcher_flow_log" "nsg_flow_log" {
  for_each              = azurerm_network_security_group.nsg
  name = "nsg-flow-log-${each.key}"
  network_watcher_name  = azurerm_network_watcher.network_watcher.name
  resource_group_name   = azurerm_resource_group.rg.name
  network_security_group_id = each.value.id
  storage_account_id    = azurerm_storage_account.stgacc.id
  enabled = true

  retention_policy {
    enabled = true
    days    = 30
  }

  traffic_analytics {
    enabled               = true
    workspace_id          = azurerm_log_analytics_workspace.log_analytics.id
    workspace_region      = azurerm_log_analytics_workspace.log_analytics.location
    workspace_resource_id = azurerm_log_analytics_workspace.log_analytics.id
  }
}

#Enable VNet Flow Logs
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
}

#: Enable Diagnostics Logs via Azure Policy
resource "azurerm_policy_definition" "diagnostics_policy" {
  name         = "enable-diagnostics-logs"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Enable Diagnostics Logs"
  description  = "Ensure diagnostics logs are enabled for all resources"

  policy_rule = <<POLICY_RULE
{
  "if": {
    "not": {
      "field": "Microsoft.Insights/diagnosticSettings/logs[*].enabled",
      "equals": "true"
    }
  },
  "then": {
    "effect": "deployIfNotExists",
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

resource "null_resource" "assign_policy" {
  provisioner "local-exec" {
    command = <<EOT
      az policy assignment create --name "assign-diagnostics-policy" --scope "${azurerm_resource_group.rg.id}" --policy "${azurerm_policy_definition.diagnostics_policy.id}" --params '{"workspaceId":"${azurerm_log_analytics_workspace.log_analytics.id}","storageAccountId":"${azurerm_storage_account.stgacc.id}"}'
    EOT
  }
  depends_on = [
    azurerm_policy_definition.diagnostics_policy,
    azurerm_log_analytics_workspace.log_analytics,
    azurerm_storage_account.stgacc
  ]
}
