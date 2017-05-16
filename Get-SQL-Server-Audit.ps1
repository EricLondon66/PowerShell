# Get list of SQL servers
$sqlservers = Get-Content "C:\Users\ericg\Desktop\SQL_Servers.txt";
# Load SMO extension
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | out-null;
# Get the datetime to use for the log filename
$datetime = Get-Date -Format "yyyy-MM-ddThh-mm-ssZ";
$filename = "$datetime.csv";
# If database details should be audited
$auditDatabases = $true;
# Flag used to indicate column headers have been added to the database audit file
$headerAdded = $false;
 
# Add the column headers to the log file
Add-Content "C:\Users\ericg\Desktop\Servers_$filename" "sqlserver,Collation,Edition,EngineEdition,OSVersion,PhysicalMemory,Processors,VersionString,Version,ProductLevel,Product,Platform,loginMode,LinkedServerCount,databaseCount,minConfigMem,clrRunValue,clrConfigValue";
 
# For each SQL server listed in $sqlservers
foreach($sqlserver in $sqlservers)
{
	Write-Host "Processing sql server: $sqlserver.";
	# Create an instance of SMO.Server for the current sql server
	$srv = New-Object "Microsoft.SqlServer.Management.Smo.Server" $sqlserver;
 
	$collation = $srv.Information.Collation;					# Server collation
	$edition = $srv.Information.Edition;						# Server edition
	$engineEdition = $srv.Information.EngineEdition;			# Engine Edition
	$OSVersion = $srv.Information.OSVersion;					# OS Version
	$PhysicalMemory = $srv.Information.PhysicalMemory;			# Physical Memory
	$Product = $srv.Information.Product;						# Server Product
	$Platform = $srv.Information.Platform;						# Server Platform
	$Processors = $srv.Information.Processors;					# Processor count
	$VersionString = $srv.Information.VersionString;			# Version String
	$Version = $srv.Information.Version;						# Version
	$ProductLevel = $srv.Information.ProductLevel;				# Product Level
 
	$loginMode = $srv.Settings.LoginMode;						# Login Mode setting
	$linkedServers = $srv.LinkedServers.Count;					# Get the number of linked servers
	$databaseCount = $srv.Databases.Count;						# Get the number of databases hosted by the sql server
	$minMem = $srv.Configuration.MinServerMemory.ConfigValue;	# Configured minimum memory
	$clrRun = $srv.Configuration.IsSqlClrEnabled.RunValue;		# SQLCLR run value
	$clrConfig = $srv.Configuration.IsSqlClrEnabled.ConfigValue;# SQLCLR config value
 
	# Write the info for the current sql server
	Add-Content "C:\Users\ericg\Desktop\Servers_$filename" "$sqlserver,$collation,$edition,$engineEdition,$OSVersion,$PhysicalMemory,$Processors,$VersionString,$Version,$ProductLevel,$Product,$Platform,$loginMode,$linkedServers,$databaseCount,$minMem,$clrRun,$clrConfig";
 
	# If $auditDatabases is true then log details of databases
	if($auditDatabases)
	{
		$dbFilename = "C:\Users\ericg\Desktop\Databases_$filename";
		# Get the databases on the current server
		$databases = $srv.Databases;
 
		# Check to see if the header has been added
		if($headerAdded -eq $false)
		{
			# Add column headers to the file
			Add-Content $dbFilename "sqlserver,dbName,ActiveConnections,CaseSensitive,Collation,CompatibilityLevel,CreateDate,DefaultSchema,Owner,Size,SpaceAvailable,Status,ProcCount,TableCount,ViewCount,TriggerCount,UDFCount,RecoveryModel,LastBackupDate,LastLogBackupDate";
			# Set to true so the header isn't added again
			$headerAdded = $true;
		}
		# For each database on the current server
		foreach($database in $databases)
		{
			Write-Host "Processing database: $database.";
			# Get database object properties
			$dbName = $database.Name;
			$ActiveConnections = $database.ActiveConnections;
			$CaseSensitive = $database.CaseSensitive;
			$Collation = $database.Collation;
			$CompatibilityLevel = $database.CompatibilityLevel;
			$CreateDate = $database.CreateDate;
			$DefaultSchema = $database.DefaultSchema;
			$Owner = $database.Owner;
			$Size = $database.Size/1024;
			$SpaceAvailable = $database.SpaceAvailable;
			$Status = ([string]$database.Status) -replace ",", "";
			$ProcCount = $database.StoredProcedures.Count;
			$TableCount = $database.Tables.Count;
			$ViewCount = $database.Views.Count;
			$TriggerCount = $database.Triggers.Count;
			$UDFCount = $database.UserDefinedFunctions.Count;
            $RecoveryModel = $database.RecoveryModel;
            $LastBackupDate = $database.LastBackupDate;
            $LastLogBackupDate = $database.LastLogBackupDate;
 
			# Append line to file for the current database
			Add-Content $dbFilename "$sqlserver,$dbName,$ActiveConnections,$CaseSensitive,$Collation,$CompatibilityLevel,$CreateDate,$DefaultSchema,$Owner,$Size,$SpaceAvailable,$Status,$ProcCount,$TableCount,$ViewCount,$TriggerCount,$UDFCount,$RecoveryModel,$LastBackupDate,$LastLogBackupDate";
		}
	}
 
}
