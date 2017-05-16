#Set Variables

set-location D:\Application_Refreshes\ResourceLink\UAT001_Refresh
$SourceDatabaseServer="sql-hrs-001"
$SourceDB="RLL"
$DestinationDatabaseServer="uat-sql-hrs-001"
$DestinationDB="RLU"
$appserver="uat-hrs-app-001"
$webserver="uat-hrs-web-001"
$Secondwebserver="uat-hrs-web-002"

#change directory to the backup location
$SourceFileLocationPath="\\$SourceDatabaseServer\h$\MSSQL\ADHoc"
#change filename to specific backup file
$SourceFileName="RLL_FULL_20170514_223001.bak"

$strFileName=$SourceFileLocationPath+"\"+$SourceFileName

#RLData Variables
$sourceDataPath = "\\hrs-app-001\d$\ResourceLink\rllive\rldata"

#check database backup exists and proceed to refresh

if (Test-Path $strFileName)
    {
    Write-Host "file name is: " $strFileName

    #STEP 1: copy QMUL data tables from the RLU to the RLU_TABLESPACE
    sqlcmd -S $DestinationDatabaseServer -i 1stCustomSQLScript.sql -o 1stCustomSQLScriptOutput.txt
    Write-Host "finished step 1 custom sql script" -ForegroundColor green
    
    #STEP 2: stop the services 
    $serviceList = Import-CSV "D:\Application_Refreshes\ResourceLink\UAT001_Refresh\ListServices.csv"
    ForEach ($HRSServers in $serviceList)
        {
        Get-Service -Name $HRSServers.Service -ComputerName $HRSServers.ComputerName  | Stop-Service
    }
    Write-Host "finished stopping services"  -ForegroundColor green

    #STEP 3: delete Folders from web servers 
    $WebServerDirectory = Import-CSV "D:\Application_Refreshes\ResourceLink\UAT001_Refresh\ListWebServerDirectory.csv"
    ForEach ($directoryPath in $WebServerDirectory)
        {
        if (Test-Path $directoryPath.location)
            {
            Get-ChildItem $directoryPath.location -Recurse | Remove-Item -Force
        }
    }
    Write-Host "finished deleting directory"  -ForegroundColor green

    #STEP 4: refresh the database
    set-location D:\Application_Refreshes\RefreshScriptTemplate
    Write-Host "starting RefreshADHoc.ps1 script"
    #run refresh template script
    .\RefreshAdHocFile.ps1 sql-ctl-12 DBA_Toolbox $SourceFileLocationPath $SourceFileName $DestinationDatabaseServer $DestinationDB
    #record refresh date
    sqlcmd -S $DestinationDatabaseServer -d $DistinationDB -i RefreshDate.sql -o D:\Application_Refreshes\ResourceLink\UAT001_Refresh\RefreshDateOUTPUT.txt -v dt=$dt

    #STEP 5: The following script will move data (settings) from Temp table to restored database  
    set-location D:\Application_Refreshes\ResourceLink\UAT001_Refresh
    sqlcmd -S $DestinationDatabaseServer -i 2ndCustomSQLScript.sql -o 2ndCustomSQLScriptOutput.txt
    Write-Host "finished step 2 custom sql script"  -ForegroundColor green
    
    #STEP 6: rename the existing data folder and copy live data folder to destination 
    $date=(get-date -Format d-MM-yyyy) -replace("/")
    $AppServerDataDirectory = Import-CSV "D:\Application_Refreshes\ResourceLink\UAT001_Refresh\ListAppServerDataDirectory.csv"
    ForEach ($directoryPath in $AppServerDataDirectory)
        {
        #rename rldata folder and add date
        $destinationDataPath=$directoryPath.location
        if (Test-Path $directoryPath.location)
            {
            Rename-Item -path $directoryPath.location -NewName "$destinationDataPath-$date"
            Write-Host "finished renaming rldata folders"
        }

        #copy rldata folder from live to uat
         try
            {
            Write-Host "Copying rldata..."
            Write-Debug "Copy $sourceDataPath to $destinationDataPath"
            copy-item $sourceDataPath -destination $destinationDataPath -Recurse
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
    Write-Host "finished starting of the services" -ForegroundColor green

    #STEP 8: Restart Webview server for completeness
    Restart-Computer -ComputerName $Secondwebserver -Force

}
ELSE
    {
    Write-Host "File path specified not found " -ForegroundColor red
}