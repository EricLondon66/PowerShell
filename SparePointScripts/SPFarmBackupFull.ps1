Add-PSSnapin "Microsoft.SharePoint.PowerShell"

Set-ExecutionPolicy -ExecutionPolicy "Unrestricted" -Force

Backup-SPFarm -BackupMethod Full -Directory \\BIR-WEB-01\Backup -Force