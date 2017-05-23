# Location of spbrtoc.xml
$spbrtoc = "E:\Backup\spbrtoc.xml" 

# Days of backup that will be remaining after backup cleanup.
$days = 90 

# Import the Sharepoint backup report xml file
[xml]$sp = gc $spbrtoc 

# Find the old backups in spbrtoc.xml
$old = $sp.SPBackupRestoreHistory.SPHistoryObject | Where-Object { [datetime]$_.SPStartTime -lt (get-date).adddays(-$days) }

write-host $old.Count
if ($old -eq $Null) { write-host "No reports of backups older than $days days found in spbrtoc.xml.`nspbrtoc.xml isn't changed and no files are removed.`n" ; break} 

# Delete the old backups from the Sharepoint backup report xml file
$old | % { $sp.SPBackupRestoreHistory.RemoveChild($_) } 

# Delete the physical folders in which the old backups were located
$old | % { Remove-Item $_.SPBackupDirectory -Recurse } 

# Save the new Sharepoint backup report xml file
$sp.Save($spbrtoc)
Write-host "Backup(s) entries older than $days days are removed from spbrtoc.xml and harddisc."
