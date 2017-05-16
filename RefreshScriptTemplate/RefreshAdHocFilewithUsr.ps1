###########################################################################################
#
#   File Name:    AutoDatabaseRefresh.ps1
#
#   Applies to:   SQL Server 2008
#                 SQL Server 2008 R2
#                 SQL Server 2012
#
#   Purpose:      Used to automatically restore a database in another environment.
#
#   Prerequisite: Powershell v2.0 must be installed.
#                 SQL Server components must be installed.
#
#   Parameters:   [string]$sourceInstance - Source SQL Server name (Ex: SERVER\INSTANCE)
#                 [string]$sourceDbName - Source database
#                 [string]$sourcePath - Source share where the file exists
#                 [string]$destinationInstance - Destination SQL Server name (Ex: SERVER\INSTANCE)
#                 [string]$destinationDbName - Database to be refreshed/created on desitination server
#                 [string]$destinationPath - Share to copy backup file to (UNC Path Ex: \\SERVER\backup$)
#
#   Author:       Patrick Keisler
#
#   Version:      1.0.0
#
#   Date:         02/06/2013
#
#   Help:         http://www.patrickkeisler.com/
#
###########################################################################################

#Enable Debug Messages
#$DebugPreference = "Continue"

#Disable Debug Messages
$DebugPreference = "SilentlyContinue"

#Terminate Code on All Errors
$ErrorActionPreference = "Stop"

#Clear screen
CLEAR

#Load Assemblies
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Smo') | out-null
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SmoExtended') | out-null
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.ConnectionInfo') | out-null

function CheckForErrors {
    $errorsReported = $False
    if($Error.Count -ne 0)
    {
  Write-Host
  Write-Host "******************************"
        Write-Host "Errors:" $Error.Count
        Write-Host "******************************"
        foreach($err in $Error)
        {
            $errorsReported  = $True
            if( $err.Exception.InnerException -ne $null)
            {
                Write-Host $err.Exception.InnerException.ToString()
            }
            else
            {
                Write-Host $err.Exception.ToString()
            }
            Write-Host
        }
        throw;
        #[System.Environment]::Exit(1)
    }
}
function GetServer {
    Param([string]$serverInstance)

    $server = New-Object ("Microsoft.SqlServer.Management.Smo.Server")($serverInstance)
    $server.ConnectionContext.ApplicationName = "AutoDatabaseRefresh"
 $server.ConnectionContext.ConnectTimeout = 5
    $server;
}
function GetRestoreFileList {
 Param([string]$serverInstance, [string]$sourcePath)

 Write-Host "Connecting to $serverInstance to find a restore file..."
 $server = GetServer($serverInstance)
 $db = $server.Databases["msdb"]
 $fileList = $db.ExecuteWithResults(
 @"
DECLARE
  @BackupId int
 ,@DatabaseName nvarchar(255);

SET @DatabaseName = '$sourceDbName';
  
-- Get the most recent full backup for this database
SELECT TOP 1
  @DatabaseName AS DatabaseName
 ,m.physical_device_name
 ,RIGHT(m.physical_device_name, CHARINDEX('\',REVERSE(physical_device_name),1) - 1) AS 'FileName'
 ,b.backup_finish_date
 ,b.type AS 'BackupType'
FROM msdb.dbo.backupset b JOIN msdb.dbo.backupmediafamily m
ON b.media_set_id = m.media_set_id
WHERE b.database_name = @DatabaseName
 AND b.type = 'D'
 AND b.is_snapshot = 0
 AND b.is_copy_only = 0
 AND b.backup_finish_date IS NOT NULL
ORDER BY b.database_backup_lsn DESC;
"@
 )

 CheckForErrors
 
 if ($fileList.Tables[0].Rows.Count -ge 1)
 {
  foreach($file in $fileList.Tables[0].Rows)
  {
   $source = $sourcePath + "\" + $file["FileName"]
   Write-Host "Selected file: " $file["physical_device_name"]
   
      Write-Host "Verifying file: $source exists..."
      if((Test-Path -Path $source) -ne $True)
      {
             $errorMessage = "File:" + $source + " does not exists"
             throw $errorMessage
      }
  }

  Write-Host "Source file existence: OK"
  $file["FileName"].ToString();
 }
 else
 {
        $errorMessage = "Source database " + $sourceDbName + " does not have any current full backups."
        throw $errorMessage 
 }
}
function GetExistingPermissions {
    Param([string]$serverInstance, [string]$destinationDbName)

    $server = GetServer($serverInstance)
 $db = $server.Databases["$destinationDbName"]

 if(-not $db)
 {
  Write-Host "Database does not exist on: $serverInstance"
 }
 else
 {
  Write-Host "Saving permissions on $destinationDbName..." -NoNewline
  $commandList = $db.ExecuteWithResults(
  @"
IF OBJECT_ID('tempdb..#Commands') IS NOT NULL
 DROP TABLE #Commands;
CREATE TABLE #Commands(
  RowId int identity(1,1)
 ,Cmd varchar(2000));

INSERT #Commands(Cmd)
SELECT 'USE [$destinationDbName];IF EXISTS (SELECT * FROM sys.database_principals WHERE name = N'+QUOTENAME(d.name,CHAR(39))+') ALTER USER ' + QUOTENAME(d.name) + ' WITH LOGIN = ' + QUOTENAME(s.name) + ';'
FROM [$destinationDbName].sys.database_principals d LEFT OUTER JOIN master.sys.server_principals s
 ON d.sid = s.sid 
WHERE s.name IS NOT NULL
 AND d.type = 'S'
 AND d.name <> 'dbo';

INSERT #Commands(Cmd)
SELECT 'USE [$destinationDbName];IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'+QUOTENAME(d.name,CHAR(39))+') CREATE USER ' + QUOTENAME(d.name) + ' FOR LOGIN ' + QUOTENAME(s.name) + ' WITH DEFAULT_SCHEMA = ' + QUOTENAME(d.default_schema_name) + ';'
FROM [$destinationDbName].sys.database_principals d LEFT OUTER JOIN master.sys.server_principals s
 ON d.sid = s.sid 
WHERE s.name IS NOT NULL
 AND d.type = 'S'
 AND d.name <> 'dbo';

INSERT #Commands(Cmd)
SELECT 'USE [$destinationDbName];IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'+QUOTENAME(d.name,CHAR(39))+') CREATE USER ' + QUOTENAME(d.name) + ' FOR LOGIN ' + QUOTENAME(s.name) + ';'
FROM [$destinationDbName].sys.database_principals d LEFT OUTER JOIN master.sys.server_principals s
 ON d.sid = s.sid 
WHERE s.name IS NOT NULL
 AND d.type IN ('U','G');

INSERT #Commands(Cmd)
SELECT 'USE [$destinationDbName];IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'+QUOTENAME(p.name,CHAR(39))+') CREATE ROLE ' + QUOTENAME(p.name) + ' AUTHORIZATION '+QUOTENAME(o.name)+';'
FROM [$destinationDbName].sys.database_principals p JOIN [$destinationDbName].sys.database_principals o
 ON o.principal_id = p.owning_principal_id
WHERE p.type = 'R' 
 AND p.is_fixed_role = 0 
 AND p.principal_id <> 0;

INSERT #Commands(Cmd)
SELECT 'USE [$destinationDbName];EXEC sp_addrolemember N' + QUOTENAME(d.name,'''') + ', N' + QUOTENAME(m.name,CHAR(39)) + ';'
FROM [$destinationDbName].sys.database_role_members r JOIN [$destinationDbName].sys.database_principals d
 ON r.role_principal_id = d.principal_id JOIN [$destinationDbName].sys.database_principals m
 ON r.member_principal_id = m.principal_id
WHERE m.principal_id > 5;

INSERT #Commands(Cmd)
SELECT 'USE [$destinationDbName];' + dp.state_desc + ' ' + dp.permission_name + ' TO ' + QUOTENAME(d.name) COLLATE Latin1_General_CI_AS + ';'
FROM [$destinationDbName].sys.database_permissions dp JOIN [$destinationDbName].sys.database_principals d
 ON dp.grantee_principal_id = d.principal_id
WHERE dp.major_id = 0 
 AND dp.state <> 'W'
 AND dp.permission_name <> 'CONNECT'
ORDER BY d.name, dp.permission_name ASC, dp.state_desc ASC;

INSERT #Commands(Cmd)
SELECT 'USE [$destinationDbName];GRANT ' + dp.permission_name + ' TO ' + QUOTENAME(d.name) COLLATE Latin1_General_CI_AS + ' WITH GRANT OPTION;'
FROM [$destinationDbName].sys.database_permissions dp JOIN [$destinationDbName].sys.database_principals d
 ON dp.grantee_principal_id = d.principal_id
WHERE dp.major_id = 0 
 AND dp.state = 'W'
 AND dp.permission_name <> 'CONNECT'
ORDER BY d.name, dp.permission_name ASC, dp.state_desc ASC;

SELECT Cmd FROM #Commands
ORDER BY RowId;
"@
  )

 CheckForErrors
 Write-Host "OK"
  
 foreach($Row in $commandList.Tables[0].Rows)
 {
  $Row | select Cmd -ExcludeProperty RowError, RowState, HasErrors, Name, ItemArray,Table | Out-File "\\$destinationInstance\H$\Powershell_Refresh\$destinationDbName.txt"
 }
 
 

 }

 $commandList;
}
function CopyFile {
    Param([string]$sourcePath, [string]$backupFile, [string]$destinationpPath)

    $source = $sourcePath + "\" + $backupFile
    
    try
    {
        Write-Host "Copying file..."
  Write-Debug "Copy $source to $destinationpPath"
  copy-item $source -destination $destinationpPath
    }
    catch
    {
        CheckForErrors
    }

 Write-Host "Copy file: OK"
}
function DeleteFile {
    Param([string]$backupFile)

    try
    {
        Write-Host "Deleting file..."
  Write-Debug "Deleting file: $backupFile"
  remove-item $backupFile
    }
    catch
    {
        CheckForErrors
    }
    
    Write-Host "Delete file: OK"
}
function RestoreDatabase {
    Param([string]$serverInstance, [string]$destinationDbName, [string]$backupDataFile, [string]$actionType)

 Write-Host "Restoring database..."

    $server = GetServer($serverInstance)
 $server.ConnectionContext.StatementTimeout = 0
 $db = $server.Databases["$destinationDbName"]

    #Create the restore object and set properties
    $restore = new-object ('Microsoft.SqlServer.Management.Smo.Restore')
    $restore.Database = $destinationDbName
    $restore.NoRecovery = $false
    $restore.PercentCompleteNotification = 10
    $restore.Devices.AddDevice($backupDataFile, [Microsoft.SqlServer.Management.Smo.DeviceType]::File)

 if(-not $db)
 {
  Write-Debug "$destinationDbName does not exist..."
  
        #Grab the default MDF & LDF file locations.
        $defaultMdf = $server.Settings.DefaultFile
     $defaultLdf = $server.Settings.DefaultLog

        #If the default locations are the same as the master database, 
        #then those values do not get populated and must be pulled from the MasterPath.
        if($defaultMdf.Length -eq 0)
        {
                $defaultMdf = $server.Information.MasterDBPath
     }
     if($defaultLdf.Length -eq 0)
        {
                $defaultLdf = $server.Information.MasterDBLogPath
        }
        
        if(-not $defaultMdf.EndsWith("\"))
        {
            $defaultMdf = $defaultMdf + "\"
        }
        if(-not $defaultLdf.EndsWith("\"))
        {
            $defaultLdf = $defaultLdf + "\"
        }
          
        $restore.ReplaceDatabase = $True

  #Get the database logical file names            
        try
  {
   $logicalNameDT = $restore.ReadFileList($server)
  }
  catch
  {
   CheckForErrors
  }

        $FileType = ""

  Write-Debug "Restoring $destinationDbName to the following physical locations:"

        foreach($Row in $logicalNameDT)
        {
            # Put the file type into a local variable.
            # This will be the variable that we use to find out which file
            # we are working with.
            $FileType = $Row["Type"].ToUpper()

            # If Type = "D", then we are handling the Database File name.
            If($FileType.Equals("D"))
            {
                $dbLogicalName = $Row["LogicalName"]
    
    $targetDbFilePath = $Row["PhysicalName"]
    $position = $targetDbFilePath.LastIndexOf("\") + 1
    $targetDbFilePath = $targetDbFilePath.Substring($position,$targetDbFilePath.Length - $position)
    $targetDbFilePath = $defaultMdf + $targetDbFilePath
    
       if((Test-Path -Path $targetDbFilePath) -eq $true)
    {
     $targetDbFilePath = $targetDbFilePath -replace $dbLogicalName, $destinationDbName
    }

    #Specify new data files (mdf and ndf)
          $relocateDataFile = new-object ('Microsoft.SqlServer.Management.Smo.RelocateFile')
          $relocateDataFile.LogicalFileName = $dbLogicalName            
          $relocateDataFile.PhysicalFileName = $targetDbFilePath
          $restore.RelocateFiles.Add($relocateDataFile) | out-null
  
    Write-Debug $relocateDataFile.PhysicalFileName
            }
            # If Type = "L", then we are handling the Log File name.
            elseif($FileType.Equals("L"))
            {
                $logLogicalName = $Row["LogicalName"]
    
    $targetLogFilePath = $Row["PhysicalName"]
    $position = $targetLogFilePath.LastIndexOf("\") + 1
    $targetLogFilePath = $targetLogFilePath.Substring($position,$targetLogFilePath.Length - $position)
    $targetLogFilePath = $defaultLdf + $targetLogFilePath

       if((Test-Path -Path $targetLogFilePath) -eq $true)
    {
     $tempName = $destinationDbName + "_Log"
     $targetLogFilePath = $targetLogFilePath -replace $logLogicalName, $tempName
    }

    #Specify new log files (ldf)
          $relocateLogFile  = new-object ('Microsoft.SqlServer.Management.Smo.RelocateFile')
          $relocateLogFile.LogicalFileName = $logLogicalName            
          $relocateLogFile.PhysicalFileName = $targetLogFilePath          
          $restore.RelocateFiles.Add($relocateLogFile) | out-null
  
    Write-Debug $relocateLogFile.PhysicalFileName
         }          
        }
 }
 else
 {
  Write-Debug "Overwritting existing database..."
  
  #Set recovery model to simple on destination database before restore
  if($db.RecoveryModel -ne [Microsoft.SqlServer.Management.Smo.RecoveryModel]::Simple)
     {
            Write-Debug "Changing recovery model to SIMPLE"
            $db.RecoveryModel = [Microsoft.SqlServer.Management.Smo.RecoveryModel]::Simple
   try
   {
             $db.Alter()
   }
   catch
   {
    CheckForErrors
   }
     }

  #Set destination database to single user mode to kill any active connections
  $db.UserAccess = "Single"
  try
  {
   $db.Alter([Microsoft.SqlServer.Management.Smo.TerminationClause]"RollbackTransactionsImmediately")
  }
  catch
  {
   CheckForErrors
  }
 }
 
    #Do the restore
 try
 {
     $restore.SqlRestore($server)
 }
 catch
 {
     CheckForErrors
 }
 
 #Reload the restored database object
 $db = $server.Databases["$destinationDbName"]
 
 #Set recovery model to simple on destination database after restore
 if($db.RecoveryModel -ne [Microsoft.SqlServer.Management.Smo.RecoveryModel]::Simple)
    {
        Write-Debug "Changing recovery model to SIMPLE"
        $db.RecoveryModel = [Microsoft.SqlServer.Management.Smo.RecoveryModel]::Simple
  try
  {
         $db.Alter()
  }
  catch
  {
   CheckForErrors
  }
    }
 
    Write-Host $actionType.ToString() "Restore: OK"
}
function RestorePermissions {
    Param([string]$destinationInstance, [string]$destinationDbName, $commandList)

 Write-Host "Restoring existing permissions..."
 $server = GetServer($destinationInstance)
 $db = $server.Databases[$destinationDbName]
 
 foreach($Row in $commandList.Tables[0].Rows)
 {
  #Apply existing permissions back to destination database
  Write-Debug $Row["Cmd"]
  try
  {
   $db.ExecuteNonQuery($Row["Cmd"])
  }
  catch
  {
   CheckForErrors
  }
 }
 
 Write-Host "Existing permissions restored: OK"
}
function PerformValidation {
    Param($sourceInstance, $sourceDbName, $sourcePath, $destinationInstance, $destinationDbName, $destinationPath)
 
 Write-Host "Validating parameters..." -NoNewline
 
 if([String]::IsNullOrEmpty($sourceInstance))
 {
  Write-Host "ERROR"
        $errorMessage = "Source server name is not valid."
        throw $errorMessage
    }
    if([String]::IsNullOrEmpty($sourceDbName))
    {
  Write-Host "ERROR"
        $errorMessage = "Source database name is not valid."
        throw $errorMessage
    }
    if([String]::IsNullOrEmpty($sourcePath))
    {
  Write-Host "ERROR"
        $errorMessage = "Source path is not valid."
        throw $errorMessage
    }
 else
    {
        if(-not $sourcePath.StartsWith("\\"))
        {
   Write-Host "ERROR"
            $errorMessage = "Source path is not valid: " + $sourcePath
            throw $errorMessage
        }
    }
    if([String]::IsNullOrEmpty($destinationInstance))
    {
  Write-Host "ERROR"
        $errorMessage = "Destination server name is not valid."
        throw $errorMessage
    }
    if([String]::IsNullOrEmpty($destinationDbName))
    {
  Write-Host "ERROR"
        $errorMessage = "Destination database name is not valid."
        throw $errorMessage
    }
 if([String]::IsNullOrEmpty($destinationPath))
    {
  Write-Host "ERROR"
        $errorMessage = "Destination path name is not valid."
        throw $errorMessage
    }
 else
    {
        if(-not $destinationPath.StartsWith("\\"))
        {
   Write-Host "ERROR"
            $errorMessage = "Destination path is not valid: " + $destinationPath
            throw $errorMessage
        }
    }
    
 Write-Host "OK"

    Write-Host "Verifying source SQL Server connectivity..." -NoNewline
 $conn = New-Object Microsoft.SqlServer.Management.Common.ServerConnection($sourceInstance)
    $conn.ApplicationName = "AutoDatabaseRefresh"
 $conn.NonPooledConnection = $true
 $conn.ConnectTimeout = 5
 try
 {
  $conn.Connect()
        $conn.Disconnect()
 }
 catch
 {
  CheckForErrors
 }
    Write-Host "OK"
 
 Write-Host "Verifying source database exists..." -NoNewline
 $sourceServer = GetServer($sourceInstance)
    $sourcedb = $sourceServer.Databases[$sourceDbName]
 if(-not $sourcedb)
    {
  Write-Host "ERROR"
        $errorMessage = "Source database does not exist on $sourceInstance"
        throw $errorMessage
    }
    Write-Host "OK"

    Write-Host "Verifying destination SQL Server connectivity..." -NoNewline
 $conn = New-Object Microsoft.SqlServer.Management.Common.ServerConnection($destinationInstance)
    $conn.ApplicationName = "AutoDatabaseRefresh"
 $conn.NonPooledConnection = $true
 $conn.ConnectTimeout = 5
 try
 {
  $conn.Connect()
        $conn.Disconnect()
 }
 catch
 {
  CheckForErrors
 }
 Write-Host "OK"
 
    Write-Host "Verifying source file share exists..." -NoNewline
    if((Test-Path -Path $sourcePath) -ne $True)
    {
  Write-Host "ERROR"
        $errorMessage = "File share:" + $sourcePath + " does not exists"
        throw $errorMessage
    }
    Write-Host "OK"

    Write-Host "Verifying destination file share exists..." -NoNewline
    if((Test-Path -Path $destinationPath) -ne $True)
    {
  Write-Host "ERROR"
        $errorMessage = "File share:" + $destinationPath + " does not exists"
        throw $errorMessage
    }
    Write-Host "OK"
}


function Main{
 
 Param([string]$sourceInstance, [string]$sourceDbName, [string]$sourcePath, [string]$RestoreFileName, [string]$destinationInstance, [string]$destinationDbName)
 
 $Error.Clear()
 $destinationPath=""
 $RestoreDBpath=""
  Write-Host
    Write-Host "============================================================="
    Write-Host " 1a: Creates share and setting network share permisssions"
    Write-Host "============================================================="
#checking if share exists
if ($shareFolder = Get-WmiObject -Class Win32_Share -ComputerName $destinationInstance -Filter "Name='Restore'")
      {
       $shareFolder.delete() 
       Write-Host "share removed "
      }


#checking if folder exists
$UNC=Test-Path -Path "\\$destinationInstance\H$\Powershell_Refresh"

if($UNC -eq $False)
{

$s = $ExecutionContext.InvokeCommand.NewScriptBlock("mkdir H:\Powershell_Refresh")
Invoke-Command -ComputerName $destinationInstance -ScriptBlock $s 

}

$RestoreDBpath="H:\Powershell_Refresh"
    
$serverinfo=(Get-WmiObject -class Win32_OperatingSystem -ComputerName $destinationInstance).Caption 

if($serverinfo -Match  "Microsoft Windows Server 2012*")
{
Write-Host "creating share for win server 2012"

New-SMBShare –Name "Restore" –Path $RestoreDBpath –FullAccess Everyone -CimSession $destinationInstance 
Write-Host "Finished creating share for win server 2012"
}
elseif($serverinfo -Match  "Microsoft Windows Server 2008*")

{

 Write-Host "creating share for win server 2008"
#Username/Group to give permissions to
$trustee = ([wmiclass]'Win32_trustee').psbase.CreateInstance()
$trustee.Domain = $null
$trustee.Name = "EVERYONE"

#Accessmask values
$fullcontrol = 2032127
$change = 1245631
$read = 1179785

#Create access-list
$ace = ([wmiclass]'Win32_ACE').psbase.CreateInstance()
$ace.AccessMask = $fullcontrol
$ace.AceFlags = 3
$ace.AceType = 0
$ace.Trustee = $trustee

#Securitydescriptor containting access
$sd = ([wmiclass]'Win32_SecurityDescriptor').psbase.CreateInstance()
$sd.ControlFlags = 4
$sd.DACL = $ace
$sd.group = $trustee
$sd.owner = $trustee
$string="\\"+$destinationInstance+"\root\cimv2:Win32_Share"

([wmiclass]$string).Create($RestoreDBpath, 'Restore', 0, 100, 'Refresh Share','',$sd).ReturnValue 
 Write-Host "Finished creating share for win server 2008"
}

$destinationPath="\\"+$destinationInstance+"\Restore"

$Acl = Get-Acl "$destinationPath"

$Ar = New-Object System.Security.AccessControl.FileSystemAccessRule("everyone", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")

$Acl.SetAccessRule($Ar)
Set-Acl "$destinationPath" $Acl

 
     Write-Host
    Write-Host "============================================================="
    Write-Host " 1a: Ensure db access is set to multiple user"
    Write-Host "============================================================="
    ##this check if the refresh failed once before and its left the database in single user mode.
               $getserver = GetServer($destinationInstance)
               $db = $getserver.Databases[$destinationDbName]
    
             if($db -and $db.DatabaseOptions.UserAccess -eq [Microsoft.SqlServer.Management.Smo.DatabaseUserAccess]:: Single)
            {

            #Database Options to change Database User Access
                 $server = KillsProcesses $destinationInstance $destinationDbName
                 $server.ConnectionContext.StatementTimeout = 0
                 $restoredb = $server.Databases["$destinationDbName"]
             #DatabaseUserAccess enum :: single, multiple, restricted
                 $restoredb.DatabaseOptions.UserAccess = [Microsoft.SqlServer.Management.Smo.DatabaseUserAccess]:: Multiple 
                 $restoredb.Alter()

                 write-host "$db in multiple user mode"
            }

    Write-Host
    Write-Host "============================================================="
    Write-Host " 1: Perform Initial Checks & Validate Input Parameters"
    Write-Host "============================================================="
 
 PerformValidation $sourceInstance $sourceDbName $sourcePath $destinationInstance $destinationDbName $destinationPath
 
    Write-Host
    Write-Host "============================================================="
    Write-Host " 2: Get ADHoc Backup for the Restore"
    Write-Host "============================================================="

#changed this bit from the original 
 $restoreFile = $RestoreFileName
  
    Write-Host
    Write-Host "============================================================="
    Write-Host " 3: Copy Backup File to the Destination"
    Write-Host "============================================================="
 
 CopyFile $sourcePath $restoreFile $destinationPath
 
    Write-Host
    Write-Host "============================================================="
    Write-Host " 4: Get Current Permissions on the Destination Database"
    Write-Host "============================================================="

	
 $existingPermissions = GetExistingPermissions $destinationInstance $destinationDbName
 
    Write-Host
    Write-Host "============================================================="
    Write-Host " 5: Restore Backup File to the Destination Server"
    Write-Host "============================================================="

 $restoreFile = $destinationPath + "\" + $restoreFile
 RestoreDatabase $destinationInstance $destinationDbName $restoreFile "Database"
  
    Write-Host
    Write-Host "============================================================="
    Write-Host " 6: Restore Permissions to the Destination Database"
    Write-Host "============================================================="

 if($existingPermissions)
 {
  RestorePermissions $destinationInstance $destinationDbName $existingPermissions
 }
 
    Write-Host
    Write-Host "============================================================="
    Write-Host " 7: Delete Backup File from the Destination Server"
    Write-Host "============================================================="

 DeleteFile $restoreFile
 
    Write-Host
    Write-Host "============================================================="
    Write-Host " 8: Fix Settings to Restored Database"
    Write-Host "============================================================="

    #Write-Host
    #Write-Host "============================================================="
    #Write-Host " 8a: Run Custom SqlCMD script"
   # Write-Host "============================================================="

	#sqlcmd -S $destinationInstance -i AgressoPostRefresh.sql -o AgressoPostRefresh.sql.txt -v Env="UAT"
	
    Write-Host
    Write-Host "============================================================="
    Write-Host "    Database refresh completed successfully"
    Write-Host "============================================================="

    Write-Host
    Write-Host "============================================================="
    Write-Host "  Remove Shared folder"
    Write-Host "============================================================="

    if($serverinfo -Match  "Microsoft Windows Server 2012*")
    {
    Remove-SmbShare -CimSession $destinationInstance -Name "Restore" -Force
    }
    
    elseif($serverinfo -Match  "Microsoft Windows Server 2008*")
    {

    if ($shareFolder = Get-WmiObject -Class Win32_Share -ComputerName $destinationInstance -Filter "Name='Restore'")
      { $shareFolder.delete() }

    }

}

#Hard-coded values used only for development
#$sourceInstance = "sql-fin-01"
#$sourceDbName = "Agresso"
#$sourcePath = "\\sql-fin-01\h$\MSSQL\BACKUP\SQL-FIN-01\Agresso\FULL"
#$destinationInstance = "UAT-SQL-FIN-01"
#$destinationDbName = "Agresso"
#$destinationPath = "\\UAT-SQL-FIN-01\h$\RestoreDb"

#Prompt for inputs for an interactive script
#$sourceInstance = $(Read-Host "Source SQL Server name (Ex: SERVER\INSTANCE)")
#$sourceDbName = $(Read-Host "Source database")
#$sourcePath = $(Read-Host "Source share where the file exists (UNC Path Ex: \\SERVER\BACKUP)")
#$destinationInstance = $(Read-Host "Destination SQL Server name (Ex: SERVER\INSTANCE)")
#$destinationDbName = $(Read-Host "Database to be refreshed/created on desitination server")
#$destinationPath = $(Read-Host "Destination share to copy backup file to (UNC Path Ex: \\SERVER\BACKUP)")

#Capture inputs from the command line.
$sourceInstance = $args[0]
$sourceDbName = $args[1]
$sourcePath = $args[2]
$RestoreFileName=$args[3]
$destinationInstance = $args[4]
$destinationDbName = $args[5]


$debug = "Source Instance Parameter: " + $sourceInstance
Write-Debug $debug
$debug = "Source Database Parameter: " + $sourceDbName
Write-Debug $debug
$debug = "Source Path Parameter: " + $sourcePath
Write-Debug $debug
$debug = "Destination Instance Parameter: " + $destinationInstance
Write-Debug $debug
$debug = "Destination Database Parameter: " + $destinationDbName
Write-Debug $debug
$debug = "Destination Path Parameter: " + $destinationPath
Write-Debug $debug

Main $sourceInstance $sourceDbName $sourcePath $RestoreFileName $destinationInstance $destinationDbName

