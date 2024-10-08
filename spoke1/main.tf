


#resouce group
resource "azurerm_resource_group" "rg" {
  name     = var.rg.resource_group
  location = var.rg.location
}

#virtual Network
resource "azurerm_virtual_network" "vnets" {
  for_each = var.vnets

  name                = each.value.vnet_name
  address_space       = [each.value.address_space]
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location


  depends_on = [azurerm_resource_group.rg]
}
#subnets

resource "azurerm_subnet" "subnets" {

  for_each = var.subnets

  name                 = each.value.name
  address_prefixes     = [each.value.address_prefixes]
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnets[each.value.vnet].name
  depends_on           = [azurerm_virtual_network.vnets]

}
#network security group
resource "azurerm_network_security_group" "nsg" {
  for_each = var.subnets

  name                = each.value.name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

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

  subnet_id                 = azurerm_subnet.subnets[each.key].id
  network_security_group_id = azurerm_network_security_group.nsg[each.key].id
  depends_on                = [azurerm_network_security_group.nsg, azurerm_subnet.subnets]
}

#Network interface card
resource "azurerm_network_interface" "nic" {
  for_each = var.vms

  name                = each.value.nic_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnets[each.value.subnet].id
    private_ip_address_allocation = "Dynamic"
  }

}

#virtual machines
resource "azurerm_virtual_machine" "vm" {

  for_each = var.vms

  name                  = each.value.vm_name
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  network_interface_ids = [azurerm_network_interface.nic[each.key].id]
  vm_size               = each.value.vm_size


  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-DataCenter"
    version   = "latest"
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
  depends_on = [azurerm_recovery_services_vault.rsv, azurerm_backup_policy_vm.backup_policy]

}

#key vault for secret username and password
data "azurerm_key_vault" "kv" {
  name                = "Aflalkeyvault7788"
  resource_group_name = "spoke1RG"
}
data "azurerm_key_vault_secret" "vm_admin_username" {
  name         = "aflal_username"
  key_vault_id = data.azurerm_key_vault.kv.id
}
data "azurerm_key_vault_secret" "vm_admin_password" {
  name         = "aflal_password"
  key_vault_id = data.azurerm_key_vault.kv.id
}

#using data block for Hub vnet
data "azurerm_virtual_network" "Hub_VNet" {
  name                = "HubVNet"
  resource_group_name = "HubRG"
}
#spoke1 to hub peerings

resource "azurerm_virtual_network_peering" "spoke1_to_hub" {

  name                         = "spoke1-to-hub-peering"
  virtual_network_name         = azurerm_virtual_network.vnets.name
  remote_virtual_network_id    = data.azurerm_virtual_network.Hub_VNet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
  resource_group_name          = azurerm_resource_group.rg.name

  depends_on = [
    azurerm_virtual_network.vnets,
    data.azurerm_virtual_network.Hub_VNet
  ]
}

resource "azurerm_virtual_network_peering" "hub_to_spoke1" {

  name                      = "hub-to-spoke1-peering"
  virtual_network_name      = data.azurerm_virtual_network.Hub_VNet.name
  remote_virtual_network_id = azurerm_virtual_network.vnets.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false

  resource_group_name = data.azurerm_virtual_network.Hub_VNet.resource_group_name

  depends_on = [
    azurerm_virtual_network.vnets,
    data.azurerm_virtual_network.Hub_VNet

  ]
}


#Recovery service vault for backup
resource "azurerm_recovery_services_vault" "rsv" {

  name                = var.rsv_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"

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
    count    = 5
    weekdays = ["Monday"]
  }

  retention_monthly {
    count    = 12
    weekdays = ["Monday"]
    weeks    = ["First"]
  }

  retention_yearly {
    count    = 1
    weekdays = ["Monday"]
    months   = ["January"]
    weeks    = ["First"]
  }
}

resource "azurerm_backup_protected_vm" "backup_protected" {
  for_each            = azurerm_virtual_machine.vm
  resource_group_name = azurerm_resource_group.rg.name
  recovery_vault_name = azurerm_recovery_services_vault.rsv.name
  source_vm_id        = each.value.id
  backup_policy_id    = azurerm_backup_policy_vm.backup_policy.id
}




#storage account for file share
resource "azurerm_storage_account" "stgacc" {

  name                     = "msystorageaccount"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "production"
  }
}

#file share
resource "azurerm_storage_share" "fileshare" {

  name                 = "myfilshare"
  storage_account_name = azurerm_storage_account.stgacc.name
  quota                = 100


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

