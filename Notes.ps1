#perform the inventory and create the excel spreadsheet

.\Get-SqlServerInventoryToClixml.ps1 -ComputerName BIR-DQS-01,BIR-SAS-01,BIR-SQL-01,BIR-SQL-02,BIR-SQL-03,BIR-WEB-01,BIR-WEB-02,CFG-SQL-01,RDS-BIR-01,SQL-COH-01,SQL-COP-01,SQL-COR-01,SQL-CSR-01,SQL-CTL-11,SQL-CTL-12,SQL-FIN-01,SQL-G4S-01,SQL-GEN-02,SQL-GEN-11,SQL-GEN-12,SQL-HRS-01,SQL-KIN-01,SQL-LND-01,SQL-MGT-01,SQL-MGT-02,SQL-MGT-03,SQL-MGT-04,SQL-MGT-001,SQL-MGT-501,SQL-PAV-01,SQL-QPS-01,SQL-RST-11,SQL-RST-12,SQL-SCU-01,SQL-SWD-01,SQL-TCO-01,SQL-THQ-01,UAT-BIR-DQS-01,UAT-BIR-SAS-01,UAT-BIR-SQL-01,UAT-BIR-SQL-02,UAT-BIR-SQL-03,UAT-BIR-WEB-01,UAT-BIR-WEB-02,UAT-RDS-BIR-01,UAT-SQL-COP-01,UAT-SQL-GEN-11,UAT-SQL-GEN-12,UAT-SQL-HRS-01,UAT-SQL-PAV-01,UAT-SQL-RST-11,UAT-SQL-RST-12,UAT-SQL-THQ-01

.\Get-SqlServerInventoryToClixml.ps1 -ComputerName BIR-SQL-01,BIR-SQL-02,BIR-SQL-03,SQL-COH-01,SQL-COP-01,SQL-COR-01,SQL-CSR-01,SQL-FIN-01,SQL-G4S-01,SQL-GEN-02,SQL-GEN-11,SQL-GEN-12,SQL-GEN-13,,SQL-GEN-14,SQL-HRS-001,SQL-HRS-002,SQL-MGT-001,SQL-MGT-002,SQL-MGT-501,SQL-MGT-502,SQL-PAV-01,SQL-QPS-01,SQL-RST-11,SQL-RST-12,SQL-RST-13,SQL-RST-14,SQL-SCU-01,SQL-SWD-01,SQL-TCO-01 

.\Get-SqlServerInventoryToClixml.ps1 -ComputerName DEV-BIR-DQS-01,DEV-BIR-SAS-01,DEV-BIR-SQL-01,DEV-BIR-SQL-02,DEV-BIR-WEB-01,DEV-RDS-BIR-01,DEV-SQL-GEN-01,DEV-SQL-GEN-11,DEV-SQL-GEN-12,DEV-SQL-RST-11,DEV-SQL-RST-12

.\Convert-SqlServerInventoryClixmlToExcel.ps1 -FromPath "C:\Dell Downloads\SQL Server Inventory - 2017-04-11-09-38.xml.gz"

# find a word in a file within folders
Get-ChildItem -recurse | Select-String -pattern "dummy" | group path | select name


#look at two AD groups and compare the users
diff (Get-ADGroupMember "GG-FIN-Application-Users") (Get-ADGroupMember "GG-UAT-FIN-Application-Users") -Property 'SamAccountName' -IncludeEqual

diff (Get-ADGroupMember "GG-FIN-Application-Users") (Get-ADGroupMember "GG-FIN-BIFUsers") -Property 'SamAccountName' -IncludeEqual

#AD - find computers like SQL in name
Get-ADComputer -filter {(enabled -eq "false") -and (Name -like "*SQL*")}

Get-ADComputer -filter {(enabled -eq "true") -and (Name -like "*SQL*")} | Select-Object Name| Sort-Object Name > SQL_Servers_Report.txt

-properties cn,lastlogondate | where {$_.lastlogondate -eq $null}

Get-ADComputer -filter {(enabled -eq "true") -and (Name -like "*SQL*")} -properties cn,lastlogondate | where {$_.lastlogondate -eq $null}


$d = [DateTime]::Today.AddDays(-100)
Get-ADComputer -filter {(enabled -eq "true") -and (lastlogondate -le $d)} -properties cn,lastlogondate


Get-ADComputer -filter {(enabled -eq "true") -and (Name -like "*SQL*") -and (lastlogondate -le $d)} -properties cn,lastlogondate

#Pinging machines to see if they are availaible
Test-Connection -count 1 -computer (Get-Content SQL_Servers_Restart.txt) > SQL_Servers_Ping.txt 
Test-Connection -count 1 -computer (Get-Content AMS1.txt) | Select Address, IPV4Address | Export-Csv -Path SQL_Servers_Report_Ping_Status.csv -NoTypeInformation

#get status of a service
Get-Service -ComputerName $strComputer -Name SQLBrowser | Select Name, MachineName, Status

Get-WMIObject Win32_Service -ComputerName BIR-SQL-01| Where-Object{$_.Name -eq 'SQLSERVERAGENT'} | 

$compArray = get-content D:\scripts\SQL_Servers.txt
foreach($strComputer in $compArray)
{
Get-WMIObject Win32_Service -ComputerName $strComputer | Where-Object{$_.Name -eq 'TSM Client Acceptor'} |format-table SystemName,StartName, Caption
}

MSSQLSERVER

Get-WMIObject Win32_Service -ComputerName BIR-SQL-01| Where-Object{$_.Name -eq 'MSSQLSERVER'} |format-table SystemName,StartName, Caption
Get-WMIObject Win32_Service -ComputerName BIR-SQL-01| Where-Object{$_.Name -eq 'SQLSERVERAGENT'} |format-table SystemName,StartName, Caption

$compArray = get-content D:\FilesPowershell\SQL_Servers.txt

foreach($strComputer in $compArray){Get-Service -ComputerName $strComputer -Name SQLBrowser | Select Name, MachineName, Status,StartMode}

foreach($strComputer in $compArray){Get-WmiObject -Class Win32_Service -ComputerName $strComputer -Filter  "Name='SQLSERVERAGENT'" | select $strComputer,displayname, startname, state}

foreach($strComputer in $compArray){Get-Service -ComputerName $strComputer -Name "GxClMgrS(Instance001)" | Select Name, MachineName, Status,StartMode}

foreach($strComputer in $compArray){Set-Service -ComputerName $strComputer -Name SQLBrowser -StartupType Manual}

DEV-BIR-SQL-02
Set-Service -ComputerName UAT-BIR-SQL-02 -Name SQLBrowser -StartupType Automatic

foreach($strComputer in $compArray){(get-service -ComputerName $compArray -Name SQLBrowser).Stop()}

foreach($strComputer in $compArray){Get-Service -Name SQLBrowser -ComputerName $compArray | Stop-service}

foreach($strComputer in $compArray){Get-Service -ComputerName $strComputer -Name SQLSERVERAGENT | Select Name | Select }


foreach($strComputer in $compArray){Get-WMIObject -Class Win32_Service -Filter  "Name='SQLSERVERAGENT'" | Select-Object StartName -ComputerName $compArray}

Get-Service -Name SQLBrowser -ComputerName BIR-SQL-02| Start-service
Get-Service -Name SQLBrowser -ComputerName UAT-BIR-SQL-02| Start-service

Get-WMIObject Win32_Service -ComputerName $strComputer | Where-Object{$_.Name -eq 'SQL Server Browser'} |format-table SystemName,StartName, Caption
}

# Unistall a program from a set of machines

$compArray = get-content d:\scripts\SQL_Servers_TSM.txt

$ListServices = '&"C:\Program Files\Tivoli\TSM\baclient\dsmcutil.exe" list'

foreach($strComputer in $compArray){Invoke-Command -ComputerName $strComputer {Invoke-Expression '&"C:\Program Files\Tivoli\TSM\baclient\dsmcutil.exe" list'}}

foreach($strComputer in $compArray){Invoke-Command -ComputerName $strComputer {Invoke-Expression '&"C:\Program Files\Tivoli\TSM\baclient\dsmcutil.exe" remove /name:"TSM Remote Client Agent"'}}
foreach($strComputer in $compArray){Invoke-Command -ComputerName $strComputer {Invoke-Expression '&"C:\Program Files\Tivoli\TSM\baclient\dsmcutil.exe" remove /name:"TSM Client Acceptor"'}}
foreach($strComputer in $compArray){Invoke-Command -ComputerName $strComputer {Invoke-Expression '&"C:\Program Files\Tivoli\TSM\baclient\dsmcutil.exe" remove /name:"TSM Client Scheduler"'}}

$codeblock = {
Write "Start"
$uninstall64 = gci "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" | foreach { gp $_.PSPath } | ? { $_ -match "IBM Tivoli Storage Manager Client" } | select UninstallString
$uninstall64 = $uninstall64.UninstallString -Replace "msiexec.exe","" -Replace "/I","" -Replace "/X",""
$uninstall64 = $uninstall64.Trim()
Write "Uninstalling..."
start-process "msiexec.exe" -arg "/X $uninstall64 /qb" -Wait
}

foreach($strComputer in $compArray){Invoke-Command -ComputerName $strComputer -ScriptBlock $codeblock}

foreach($strComputer in $compArray){Invoke-Command -ComputerName $strComputer {Remove-Item "C:\Program Files\Tivoli\TSM" -Recurse -Force}}

Invoke-Command -ComputerName UAT-SQL-RST-12 {Invoke-Expression '&"C:\Program Files\Tivoli\TSM\baclient\dsmcutil.exe" list'}

Invoke-Command -ComputerName UAT-SQL-RST-12 {Invoke-Expression '&"C:\Program Files\Tivoli\TSM\baclient\dsmcutil.exe" remove /name:"TSM Remote Client Agent"'}
Invoke-Command -ComputerName UAT-SQL-RST-12 {Invoke-Expression '&"C:\Program Files\Tivoli\TSM\baclient\dsmcutil.exe" remove /name:"TSM Client Acceptor"'}
Invoke-Command -ComputerName UAT-SQL-RST-12 {Invoke-Expression '&"C:\Program Files\Tivoli\TSM\baclient\dsmcutil.exe" remove /name:"TSM Client Scheduler"'}

Invoke-Command -ComputerName UAT-SQL-RST-12 {Remove-Item "C:\Program Files\Tivoli\TSM" -Recurse -Force}

$uninstall64 = gci "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" | foreach { gp $_.PSPath } | ? { $_ -match "IBM Tivoli Storage Manager Client" } | select UninstallString

if ($uninstall64) {
$uninstall64 = $uninstall64.UninstallString -Replace "msiexec.exe","" -Replace "/I","" -Replace "/X",""
$uninstall64 = $uninstall64.Trim()
Write "Uninstalling..."
start-process "msiexec.exe" -arg "/X $uninstall64 /qb" -Wait}


$service = Get-WmiObject -Class Win32_Service -Filter "Name='RabbitMQ'"
$service.delete()



Copy-SqlDatabase -Source SQL-PAV-01 -Destination SQL-RST-11 -Database PAPERVISIONDM -BackupRestore -NetworkShare \\SQL-CTL-11\Migration$

Copy-SqlLogin -Source sql-pav-01 -Destination SQL-RST-12 -Logins PVISION

Set-DbaDatabaseState -SqlInstance SQL-PAV-01 -Database PAPERVISIONDM -Offline

#Remove-DbaDatabase -SqlInstance SQL-CTL-11 -Databases PAPERVISIONDM

#sqlcmd -S SQL-CTL-11 -d master -Q "DROP LOGIN [PVISION]"

sqlcmd -S SQL-PAV-01 -d master -Q "ALTER LOGIN [PVISION] DISABLE;"

#Test-DbaOptimizeForAdHoc -SqlServer sql-rst-11






$compArray = get-content D:\FilesPowershell\SQL_Servers_PROD.txt

foreach($strComputer in $compArray){Test-DbaPowerPlan -ComputerName $strComputer}

Set-DbaPowerPlan -ComputerName SQL-GEN-13



#Invoke-Expression (Invoke-WebRequest -UseBasicParsing https://dbatools.io/in)
#import-module dbatools

#Copy-SqlLogin -Source sqlserver -Destination sqlcluster -Logins netnerds, realcajun, 'base\ctrlb'

copy-sqllogin -Source DEV-CFG-SQL-01 -Destination DEV-CFG-SQL-002 -Logins 'DEV\DEV-CFG-APP-01$','DEV\DEV-CFG-PSS-01$','DEV\DEV-CFG-SRV-01$',
'DEV\DEV-CFG-SRV-02$','DEV\GG-CFG-Administrators','DEV\SRV-CFG-REP','DEV-CFG-SQL-01\ConfigMgr_DViewAccess'


#\\Dev-sql-gen-11\migration$ 

Copy-SqlDatabase -Source DEV-CFG-SQL-01 -Destination DEV-CFG-SQL-002 -Database CM_QP1 -BackupRestore -NetworkShare \\Dev-sql-gen-11\migration$ 


$oldprops = Get-DbaSpConfigure -SqlServer DEV-CFG-SQL-01
$newprops = Get-DbaSpConfigure -SqlServer DEV-CFG-SQL-002
 
$propcompare = foreach ($prop in $oldprops) 
    {
    [pscustomobject]@{
        Config = $prop.DisplayName
        'SQL Server 2014' = $prop.RunningValue
        'SQL Server 2016' = ($newprops | Where ConfigName -eq $prop.ConfigName).RunningValue
    }
}

# One a new server is installed, this will configure the mail, alerts etc

Set-Location D:\ServerSetup

sqlcmd -S DEV-CFG-SQL-002 -d master -i 1_configure_database_mail.sql -o 1_configure_database_mail.sql.txt
sqlcmd -S DEV-CFG-SQL-002 -d master -i 2_configure_sql_server_alerts.sql -o 2_configure_sql_server_alerts.sql.txt
sqlcmd -S DEV-CFG-SQL-002 -d master -i 3_configure_backup_compression.sql -o 3_configure_backup_compression.sql.txt
sqlcmd -S DEV-CFG-SQL-002 -d master -i 4_configure_sql_server_backups.sql -o 4_configure_sql_server_backups.sql.txt

# import compoters and restart the servers

$compArray = get-content D:\FilesPowershell\SQL_Servers_Restart.txt
foreach($strComputer in $compArray){Restart-Computer -ComputerName $strComputer -Force}

# Use this to ping the servers indefinately to see if they are UP or DOWN

$names = get-content D:\FilesPowershell\SQL_Servers_Restart.txt
$strQuit = "Not yet"
do
{
foreach ($name in $names){
  if (Test-Connection -ComputerName $name -Count 1 -ErrorAction SilentlyContinue){
    Write-Host "$name is up" -ForegroundColor Green
  }
  else{
    Write-Host "$name is down" -ForegroundColor Red
  }
}
} # End of 'Do'
Until ($strQuit -eq "N")
"`n Ready to do more stuff..."

# log the logins on a database
# Setup task manager to run the following line: powershell –File "D:\FilesPowershell\WatchSqlDbLogin.ps1"

import-module dbatools
Watch-SqlDbLogin -SqlServer SQL-CTL-11 -Database DatabaseLogins -Table DbLogins -ServersFromFile D:\FilesTXT\SQL_Servers_MGT.txt
