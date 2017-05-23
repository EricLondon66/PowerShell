Add-PSSnapin "Microsoft.SharePoint.PowerShell"

Set-ExecutionPolicy -ExecutionPolicy "Unrestricted" -Force

$today = (Get-Date -Format yyyy_MM_dd_hh_mm)

Backup-SPSite -Identity "https://bir.qmul.ac.uk/" -Path "E:\Backup\SC\SCbackup_$today.bak"


#Cleanup Existing Backups
$limit = (Get-Date).AddDays(-90)
$path = "E:\Backup\SC"

# Delete files older than the $limit.
Get-ChildItem -Path $path -Recurse -Force | Where-Object { !$_.PSIsContainer -and $_.CreationTime -lt $limit } | Remove-Item -Force