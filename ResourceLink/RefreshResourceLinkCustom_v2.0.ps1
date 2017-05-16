#Set Variables

## CHANGE Set Environment that needs the refresh. DEV or UAT
$refreshEnvironment = 'UAT'

$SourceDatabaseServer="sql-hrs-001"
$SourceDB="RLL"

## CHANGE directory to the backup location
$SourceFileLocationPath="\\$SourceDatabaseServer\h$\MSSQL\ADHoc"
## CHANGE filename to specific backup file
$SourceFileName="RLL_FULL_20170514_223001.bak"

$strFileName=$SourceFileLocationPath+"\"+$SourceFileName

#RLData Variables
$sourceDataPath = "\\hrs-app-001\d$\ResourceLink\rllive\rldata"

#set other variables depending on environment to be refreshed
switch ($refreshEnvironment) 
    { 
        "UAT" {
                Write-Host "Environment is: " $refreshEnvironment -BackgroundColor Red
                $WorkingDirectory = "D:\Application_Refreshes\ResourceLink\UAT001_Refresh"
                $DestinationDatabaseServer="uat-sql-hrs-001"
                $DestinationDB="RLU"
                $appserver="uat-hrs-app-001"
                $webserver="uat-hrs-web-001"
                $Secondwebserver="uat-hrs-web-002"
                } 
        "DEV" {
                Write-Host "Environment is: " $refreshEnvironment -BackgroundColor Red
                $WorkingDirectory = "D:\Application_Refreshes\ResourceLink\DEV001_Refresh"
                $DestinationDatabaseServer="dev-sql-hrs-001"
                $DestinationDB="RLD"
                $appserver="dev-hrs-app-001"
                $webserver="dev-hrs-web-001"
                $Secondwebserver="dev-hrs-web-002"
                } 
        default {"The Environment could not be determined."}
    }
 

#check database backup exists and proceed to refresh

if (Test-Path $strFileName)
    {
    set-location $WorkingDirectory
    Write-Host "file name is: " $strFileName

    #STEP 1: copy QMUL data tables from the destinationDB to the RLU_TABLESPACE
    sqlcmd -S $DestinationDatabaseServer -i 1stCustomSQLScript.sql -o 1stCustomSQLScriptOutput.txt
    Write-Host "finished STEP 1: copy QMUL data tables from the destinationDB to the RLU_TABLESPACE" -ForegroundColor green
    
    #STEP 2: stop the services 
    $serviceList = Import-CSV "$WorkingDirectory\ListServices.csv"
    ForEach ($HRSServers in $serviceList)
        {
        Get-Service -Name $HRSServers.Service -ComputerName $HRSServers.ComputerName  | Stop-Service
    }
    Write-Host "finished STEP 2: stop the services"  -ForegroundColor green

    #STEP 3: delete Folders from web servers 
    $WebServerDirectory = Import-CSV "$WorkingDirectory\ListWebServerDirectory.csv"
    ForEach ($directoryPath in $WebServerDirectory)
        {
        if (Test-Path $directoryPath.location)
            {
            Write-Host "Deleting files from " $directoryPath.location
   # stopped because of error deleting files on Web Server
   #         Get-ChildItem $directoryPath.location -Recurse | Remove-Item -Force
        }
    }
    Write-Host "finished STEP 3: delete Folders from web servers "  -ForegroundColor green

    #STEP 4: refresh the database
    set-location D:\Application_Refreshes\RefreshScriptTemplate
    Write-Host "start STEP 4: refresh the database"
    #run refresh template script
    .\RefreshAdHocFile.ps1 sql-ctl-12 DBA_Toolbox $SourceFileLocationPath $SourceFileName $DestinationDatabaseServer $DestinationDB
    #record refresh date
    $dt=Get-Date -format "d.MMM.yyyy"
    $time=Get-Date -format "HH.mm"
    $dt=$dt+"_"+$time
    sqlcmd -S $DestinationDatabaseServer -d $DestinationDB -i RefreshDate.sql -o "$WorkingDirectory\RefreshDateOUTPUT.txt" -v dt=$dt

    #STEP 5: The following script will move data (settings) from Temp table to restored database  
    set-location $WorkingDirectory
    sqlcmd -S $DestinationDatabaseServer -i 2ndCustomSQLScript.sql -o 2ndCustomSQLScriptOutput.txt
    Write-Host "finished STEP 5: The following script will move data (settings) from Temp table to restored database"  -ForegroundColor green
    
    #STEP 6: rename the existing data folder and copy live data folder to destination 
    $date=(get-date -Format d-MM-yyyy) -replace("/")
    $AppServerDataDirectory = Import-CSV "$WorkingDirectory\ListAppServerDataDirectory.csv"
    ForEach ($directoryPath in $AppServerDataDirectory)
        {
        #rename rldata folder and add date
        $destinationDataPath=$directoryPath.location
        if (Test-Path $directoryPath.location)
            {
            Rename-Item -path $directoryPath.location -NewName "$destinationDataPath-$date"
        }

        #copy rldata folder from live to uat
         try
            {
            Write-Host "Copying rldata..."
            Write-Debug "Copy $sourceDataPath to $destinationDataPath"
            copy-item $sourceDataPath -destination $destinationDataPath -Recurse
            Write-Host "finished STEP 6: rename the existing data folder and copy live data folder to destination"  -ForegroundColor green
        }
        catch
            {
            $ErrorMessage = $_.Exception.Message
            $FailedItem = $_.Exception.ItemName
            Send-MailMessage -From its-dba-team@qmul.ac.uk -To its-dba-team@qmulac.uk -Subject "copy rldata file failed" -SmtpServer smtp.qmul.ac.uk -Body "copy rldata file failed $FailedItem. The error message was $ErrorMessage"
            Break
        }
    }
    
    Write-Host "Copy file of rldata: OK"

    #STEP 7: start the services
    ForEach ($HRSServers in $serviceList)
        {
        Get-Service -Name $HRSServers.Service -ComputerName $HRSServers.ComputerName  | Start-Service
    }
    Write-Host "finished STEP 7: start the services" -ForegroundColor green

    #STEP 8: Restart Webview server for completeness
    Restart-Computer -ComputerName $Secondwebserver -Force

}
ELSE
    {
    Write-Host "File path specified not found " -ForegroundColor red
}