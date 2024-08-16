\$storageAccountName = "msystorageaccount"
\$shareName = "myfilshare"
\$storageAccountKey = "TDWscP7NUM/tBQbi7O833I6EAyn6TFajog7GChEXBnRcOpIYJSFOl/LPCXqWfc+zolD0YuJyS0w8+AStCvSRvw=="

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
