#Set-ExecutionPolicy RemoteSigned -Force #if the powershell execution script IS disabled USE 
param ([string] $instance, [string] $collation, $AGTSVCPASSWORD,$SQLSVCPASSWORD, $saPassword, $sourceDir )
 
 
$instance="MSSQLSERVER"
$SQLSVCACCOUNT="DEV\XXXXX1" # DEV\...sql db engine service account
$AGTSVCACCOUNT="DEV\XXXXX" #DEV\...sql agent service account
$RSSVCACCOUNT="DEV\XXXXX" #DEV\...reporting service account
$collation="SQL_Latin1_General_CP1_CI_AS"
$SQLSVCPASSWORD="XXXXX!" #sql db service account password
$AGTSVCPASSWORD="XXXXX!" #sql agent service account password
$RSSVCPASSWORD="XXXXX" #reporting service account password
$saPassword="XXXXX" #should have capitals,numbers,6-8 characters etc
 
#this location is where the setup.exe is. 
$sourceDir="G:\"
 
 
function prepareConfigFile ([String]$instance, [String]$collation,[String]$SQLSVCACCOUNT,[String]$AGTSVCACCOUNT,[String]$RSSVCACCOUNT   ) {
$config = "
;SQL Server 2016 Configuration File
[OPTIONS]
ACTION=""Install""
FEATURES=SQLENGINE,RS
X86=""False""
INSTANCENAME=""$instance""
INSTANCEID=""$instance""
INSTALLSHAREDDIR=""C:\Program Files\Microsoft SQL Server""
INSTALLSHAREDWOWDIR=""C:\Program Files (x86)\Microsoft SQL Server""
INSTANCEDIR=""E:\DataArea""
SQLUSERDBDIR=""E:\DataArea""
SQLUSERDBLOGDIR=""F:\LogArea""
SQLTEMPDBDIR=""I:\DataArea""
SQLTEMPDBLOGDIR=""J:\LogArea""
SQLBACKUPDIR=""H:\MSSQL\BACKUP""
FILESTREAMLEVEL=""0""
TCPENABLED=""1""
NPENABLED=""1""
SQLCOLLATION=""$collation""
SQLSVCACCOUNT=""$SQLSVCACCOUNT""
SQLSVCSTARTUPTYPE=""Automatic""
AGTSVCACCOUNT=""$AGTSVCACCOUNT""
AGTSVCSTARTUPTYPE=""Automatic""
BROWSERSVCSTARTUPTYPE=""Disabled""
SQLSYSADMINACCOUNTS=""DEV\GG-SQL-Administrators""
SECURITYMODE=""SQL""
SQMREPORTING=""FALSE""
IACCEPTSQLSERVERLICENSETERMS=""TRUE""
RSINSTALLMODE=""FilesOnlyMode""
SQLTELSVCACCT=""NT Service\SQLTELEMETRY""
SQLTELSVCSTARTUPTYPE=""Automatic""
COMMFABRICPORT=""0""
COMMFABRICNETWORKLEVEL=""0""
COMMFABRICENCRYPTION=""0""
MATRIXCMBRICKCOMMPORT=""0""
SQLSVCINSTANTFILEINIT=""True""
SQLTEMPDBFILECOUNT=""2""
SQLTEMPDBFILESIZE=""8""
SQLTEMPDBFILEGROWTH=""64""
SQLTEMPDBLOGFILESIZE=""8""
SQLTEMPDBLOGFILEGROWTH=""64""
RSSVCACCOUNT=""$RSSVCACCOUNT""
RSSVCSTARTUPTYPE=""Automatic""
"
$config
}
 
 
#####################
# Creating Ini File #
#####################
 
 
#where to store the confi file
$configFile = "D:\ConfigurationFile.INI"
 
prepareConfigFile $instance $collation $SQLSVCACCOUNT $AGTSVCACCOUNT $RSSVCACCOUNT | Out-File $configFile
 
 
#######################################
# Starting SQL Base Installation #
#######################################
 
set-location $sourceDir
 
"Starting SQL Base Installation..."
$installCmd = ".\setup.exe /qs /SQLSVCPASSWORD=""$SQLSVCPASSWORD"" /UpdateEnabled=FALSE /AGTSVCPASSWORD=""$AGTSVCPASSWORD"" /RSSVCPASSWORD=""$RSSVCPASSWORD"" /SAPWD=""$saPassword"" /ConfigurationFile=""$configFile"""
 
Invoke-Expression $installCmd

#######################################
# Run post install setup #
#######################################

$localcomputername = get-content env:computername
Set-Location D:\ServerSetup

sqlcmd -S $localcomputername -d master -i 1_configure_database_mail.sql -o 1_configure_database_mail.sql.txt
sqlcmd -S $localcomputername -d master -i 2_configure_sql_server_alerts.sql -o 2_configure_sql_server_alerts.sql.txt
sqlcmd -S $localcomputername -d master -i 3_configure_backup_compression.sql -o 3_configure_backup_compression.sql.txt
sqlcmd -S $localcomputername -d master -i 4_configure_sql_server_backups.sql -o 4_configure_sql_server_backups.sql.txt