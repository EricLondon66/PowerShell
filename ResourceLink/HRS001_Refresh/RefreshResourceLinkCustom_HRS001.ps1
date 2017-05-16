 set-location D:\Application_Refreshes\ResourceLink\HRS001_Refresh
 $server="sql-hrs-001"
 $appserver="hrs-app-001"
 $DistinationDB="RLL"
 

  #stop the services 

  $list = Get-Content "D:\Application_Refreshes\ResourceLink\HRS001_Refresh\ListServices.txt"
 
 foreach ($TheService in $list)
 {
 $service =Get-Service -name $TheService -Computername $appserver
 $service.Stop() 
 
 }
  Write-Host "finished stopping services" 


  
 #change filename.bak to the backup filename
 $SourceFileLocationPath="\\SQL-HRS-01\h$\MSSQL\ADHoc"

 

#specific file name
$SourceFileName="RLL_20170323081500.BAK"


$strFileName=$SourceFileLocationPath+"\"+$SourceFileName


Write-Host "file name is: " $strFileName

if (Test-Path $strFileName)
{



        try{
        
             $dt=Get-Date -format "d.MMM.yyyy"
            $time=Get-Date -format "HH.mm"
            $dt=$dt+"_"+$time

            
                set-location D:\Application_Refreshes\RefreshScriptTemplate

 ############################### Refresh ###########################################################
            Write-Host "starting RefreshADHoc.ps1 script"
             #run refresh template script
            .\RefreshAdHocFile.ps1 sql-ctl-12 DBA_Toolbox $SourceFileLocationPath $SourceFileName $server $DistinationDB
            

            
             set-location  D:\Application_Refreshes\RefreshScriptTemplate
        #record refresh date
        sqlcmd -S $server -d $DistinationDB -i RefreshDate.sql -o D:\Application_Refreshes\ResourceLink\HRS001_Refresh\RefreshDateOUTPUT.txt -v dt=$dt
             Write-Host "finished RefreshDate.sql" -ForegroundColor Green

             
############################### rename existing appserver files and copy live rldata to appserver   ######################### 

                         #rename the existing uat folder to be replace by live folder 
                $date=(get-date -Format d-MM-yyyy) -replace("/")


                #copy  rldata folder from live to uat
                $source = "\\sql-hrs-01\c$\Resourcelink\rllive\rldata"

                $destinationPath="\\$appserver\D$\ResourceLink\rllive\rldata"    

                if (Test-Path $destinationPath)
                {
                Rename-Item -path "\\$appserver\D$\ResourceLink\rllive\rldata" -newName "rldata_$date"
                #Software folder does not get replaced
                
                  Write-Host "finished renaming uat rldata folders"
                }
               
                 
                    try
                    {
                      Write-Host "Copying rldata..."
                      Write-Debug "Copy $source to $destinationPath"
                      copy-item $source -destination $destinationPath -Recurse
                    }
                    catch
                    {
                        $ErrorMessage = $_.Exception.Message
                        $FailedItem = $_.Exception.ItemName
                        Send-MailMessage -From its-dba-team@qmul.ac.uk -To its-dba-team@qmulac.uk -Subject "copy rldata file failed" -SmtpServer smtp.qmul.ac.uk -Body "copy rldata file failed $FailedItem. The error message was $ErrorMessage"
                        Break
                    }

                 Write-Host "Copy file of rldata: OK"


############################### rename existing appserver files and copy live rlsoft to appserver   ######################### 
           #rename the existing uat folder to be replace by live folder 
                $date=(get-date -Format d-MM-yyyy) -replace("/")




                #copy  rlsoft folder from live to uat
                $sourcerlsoft = "\\sql-hrs-01\c$\Resourcelink\rllive\rlsoft"
                $destinationPathrlsoft="\\$appserver\D$\ResourceLink\rllive\rlsoft" 

                if (Test-Path $destinationPathrlsoft)
                {
                Rename-Item -path "\\$appserver\D$\ResourceLink\rllive\rlsoft" -newName "rlsoft_$date"
                #Software folder does not get replaced
                
                  Write-Host "finished renaming uat rldata folders"
                }
               
               
                   try
                    {
                        Write-Host "Copying rldata..."
                        Write-Debug "Copy $sourcerlsoft to $destinationPathrlsoft"
                        copy-item $sourcerlsoft -destination $destinationPathrlsoft -Recurse
                    }
                    catch
                    {
                    $ErrorMessage = $_.Exception.Message
                    $FailedItem = $_.Exception.ItemName
                    Send-MailMessage -From its-dba-team@qmul.ac.uk -To its-dba-team@qmulac.uk -Subject "copy rlsoft file failed" -SmtpServer smtp.qmul.ac.uk -Body "copy rlsoft file failed $FailedItem. The error message was $ErrorMessage"
                    Break
                    }

                 Write-Host "Copy file of rlsoft: OK"




            }
                         
        
        catch
        {

        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
        Send-MailMessage -From its-dba-team@qmul.ac.uk -To its-dba-team@qmulac.uk -Subject "Adhoc refresh failed" -SmtpServer smtp.qmul.ac.uk -Body "Adhoc refresh failed $FailedItem. The error message was $ErrorMessage"
        Break
    

        }


 }



 ELSE{

Write-Host "Backup File path specified not found " -ForegroundColor red
}

 #start the services
 foreach ($TheService in $list)
 {
 $service =Get-Service -name $TheService -Computername $appserver
 $service.Start()
 
 }

  Write-Host "finished starting of the services" 
