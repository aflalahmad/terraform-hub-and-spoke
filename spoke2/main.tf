resource "azurerm_resource_group" "rg" {
    name = var.rg.resource_group
    location = var.rg.location
}

resource "azurerm_virtual_network" "vnet" {
  name = var.vnet_name
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  address_space = ["10.0.0.0/24"]
}

resource "azurerm_subnet" "subnets" {

    for_each = var.subnets

    name = each.value.name
    address_prefixes = [each.value.address_prefixes]
    resource_group_name = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    depends_on = [ azurerm_virtual_network.vnet ]
}


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

resource "azurerm_subnet_network_security_group_association" "nsg-association" {
      for_each = var.subnets

      subnet_id = azurerm_subnet.subnets[each.key].id
      network_security_group_id = azurerm_network_security_group.nsg[each.key].id
      depends_on = [ azurerm_network_security_group.nsg,azurerm_subnet.subnets ]
}

resource "azurerm_windows_virtual_machine_scale_set" "vmss" {
  name                 = var.vmss_name
  resource_group_name  = azurerm_resource_group.rg.name
  location             = azurerm_resource_group.rg.location
  sku                  = var.sku
  instances            = var.instance
  admin_password       = var.admin_password
  admin_username       = var.admin_username
  computer_name_prefix = "vm-"

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter-Server-Core"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
  dynamic "network_interface" {
    for_each = azurerm_subnet.subnets

    content {
      name    = "example-${network_interface.key}"
      primary = network_interface.key == "subnet1"  

      ip_configuration {
        name      = "internal"
        primary   = network_interface.key == "subnet1"  
        subnet_id = network_interface.value.id
      }
    }
  }
}
#Daily backup for VM
# Recovery Services Vault
resource "azurerm_recovery_services_vault" "rsv" {
  name                = var.rsv_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"
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


# Backup Protection for VM Scale Set
/*
resource "azurerm_backup_protected_vm" "backup_protected" {
  count               = var.instance
  resource_group_name = azurerm_resource_group.rg.name
  recovery_vault_name = azurerm_recovery_services_vault.rsv.name
  source_vm_id        = azurerm_windows_virtual_machine_scale_set.vmss.virtual_machine_id[count.index]
  backup_policy_id    = azurerm_backup_policy_vm.backup_policy.id
  depends_on = [ azurerm_windows_virtual_machine_scale_set.vmss,azurerm_backup_policy_vm.backup_policy ]
}
*/

#Service deployments should be limited to specific Azure regions via Azure Policy. 
resource "azurerm_policy_definition" "limit_deployment_regions" {
  name         = "limiteddeployment-regions"
  display_name = "Limit Azure Resource Deployments to Specific Regions"
  description  = "Ensures that resources are deployed only in specific Azure regions."
  mode = "Indexed"
  policy_type = "Custom"

  policy_rule = jsonencode({
    "if": {
      "not": {
        "field": "location",
        "in": [
          "East US",
          "West Europe",
          "Southeast Asia",
          "West US"
        ]
      }
    },
    "then": {
      "effect": "deny"
    }
  })
}
#All Azure Policies should be scoped to the Resource Group level. 
resource "azurerm_resource_group_policy_assignment" "example" {
  name                 = "example"
  resource_group_id    = azurerm_resource_group.rg.id
  policy_definition_id = azurerm_policy_definition.limit_deployment_regions.id

  parameters = <<PARAMS
    {
      "tagName": {
        "value": "Business Unit"
      },
      "tagValue": {
        "value": "BU"
      }
    }
PARAMS
}