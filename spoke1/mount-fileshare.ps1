param(
  [string]$storageAccountName,
  [string]$storageAccountKey,
  [string]$fileShareName,
  [string]$mountPoint
)

# Install the Azure Files PowerShell module
Install-Module -Name AzFilesHybrid -AllowClobber -Force -Scope CurrentUser

# Import the module
Import-Module AzFilesHybrid

# Set the Azure storage account context
$context = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey

# Create the drive letter if it doesn't exist
New-PSDrive -Name $mountPoint -PSProvider FileSystem -Root "\\$storageAccountName.file.core.windows.net\$fileShareName" -Persist -Credential $context
