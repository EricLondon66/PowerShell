﻿###### Configuration ######
 
    # FQDN of Analysis Services server. If no server name is specified then
    # defaults to localhost. example: $server_name = "ssas1.microsoft.com"
    $server_name = "BIR-SAS-01"
 
    # UNC path of share or on-disk location to which backups will be stored.
    # Do not including trailing slash. If null then defaults to SSAS BackupDir
    # example: $backup_location = "\\storage.microsoft.com\ssas-backup"
    $backup_location = $null
 
    # Array of databases that will be backed-up. If $null then all databases
    # will be backed up.
    $user_requested_databases = $null
 
    # How long backups will be retained
    $retention_period_in_days = 30
 
    ###### End Configuration ######
 
    trap [Exception] {
        write-error $("TRAPPED: " + $_.Exception.GetType().FullName)
        write-error $("TRAPPED: " + $_.Exception.Message)
        if ($server) {
            $server.disconnect()
        }
        exit 1
    }
 
    if ($server_name -eq $null) {
        $server_name = "localhost"
    }
 
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.AnalysisServices") | out-null
    $server = New-Object Microsoft.AnalysisServices.Server
    $server.connect($server_name)
 
    # Set the directory for backups to the server property
    # "BackupDir" if it's not otherwise specified
    if ($backup_location -eq $null) {
        $backup_location = ($server.get_ServerProperties() | Where {$_.Name -eq "BackupDir"}).Value}
    elseif (!(Test-Path -path $backup_location)) {
        throw "Specified path ($backup_location) does not exist."
    }
 
    # Generate an array of databases to be backed up
    $available_databases = ($server.get_Databases() | foreach {$_.Name})
    if ($user_requested_databases -eq $null) {
        $databases = $available_databases}
    else {
        $databases = $user_requested_databases.Split(",")
        # Check that all specified databases actually exist on the server.
        foreach ($database in $databases) {
            if ($available_databases -notcontains $database) {
                throw "$database does not exist on specified server."
            }
        }
    }
     
    foreach ($database in ($server.get_Databases() | Where {$databases -contains $_.Name})) {
        $directory_path = $backup_location + "\" + $database.Name

        $loc="\\$server_name\h$\"+$directory_path.Substring(3)

        if (!(Test-Path -Path $loc)) {
        
            New-Item $loc -type directory | out-null
        }
        [string] $timestamp = date
        $timestamp = $timestamp.Replace(':','').Replace('/','-').Replace(' ','-')
        $database.Backup("$directory_path\$database-$timestamp.abf")
 
       write-host $database.Name  -ForegroundColor Green
    }

 
    $server.disconnect()