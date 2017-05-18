Set-Location "D:\Patching"

$Servers = Get-Content 'D:\Patching\UATPatching.txt'
$serverfile=$env:computername


#$2008patch="SQLServer2008R2SP3-KB2979597-x64-ENU.exe"

$2012patch="SQLServer2012_SP3_CU8-KB4013104-x64.exe"

$2014patch="SQLServer2014_SP2_CU4-KB4010394-x64.exe"

$2016patch="SQLServer2016_SP1_CU2-KB4013106-x64.exe"


New-PSDrive –Name "Z" -PSProvider FileSystem -Root "\\qm.ds.qmul.ac.uk\APP\PROD\DBA" 

$path="Z:\SQL_Server_Software\PATCHES"

foreach($Server in $Servers)
{
#Write-Host $Server
 New-PSDrive –Name $Server -PSProvider FileSystem -Root "\\$Server\H$"
 $loc=$Server+':\'
  
If ( $Server -eq "UAT-BIR-SAS-01" -or $Server -eq "DEV-BIR-SAS-01" -or $Server -eq "BIR-SAS-01")
                {
                    write-host $Server

                       

                        ##copy patch file locally to server
                        Copy-Item -Path "$path\SQL_2012\$2012patch" -Destination "$loc\$2012patch" -Force
                       # Copy-Item -Path "D:\Patching\$2012patch" -Destination "\\$Server\H$\$2012patch" -Force
                    
                        ##create powershell patch file
                        $cmd = "H:\$2012patch /qs /IAcceptSQLServerLicenseTerms /Action=Patch /AllInstances"
                        $cmd | Out-File "$loc\patch.ps1"

                            ##invoke the powershell script to start patching 
                       # $sessions = New-PSSession -ComputerName $Server 
                       # invoke-command -filepath "\\$Server\H$\patch.ps1" -Session $sessions -AsJob 



                }


 ElseIf (($Server -ne "BIR-SAS-01 " -or $Server -ne "UAT-BIR-SAS-01 " -or $Server -eq "DEV-BIR-SAS-01") -and $Server -like "*SQL*" -or $Server -like "DEV-BIR-DQS-01" )
               {

              $version =Invoke-Sqlcmd -ServerInstance $Server -Query "SELECT @@Version AS 'Version'"
              $ver=$version.Version.Substring(0,25)
              write-host $Server $ver

                           if($ver.ToString() -Like  "Microsoft SQL Server 2012*")
                            {

                            WRITE-HOST "2012" $Server " " $ver  



                                ##copy patch file locally to server
                            Copy-Item -Path "$path\SQL_2012\$2012patch" -Destination "$loc\$2012patch" -Force
                            #Copy-Item -Path "D:\Patching\$2012patch" -Destination "\\$Server\H$\$2012patch" -Force
                            
                    
                            ##create powershell patch file
                            $cmd = "H:\$2012patch /qs /IAcceptSQLServerLicenseTerms /Action=Patch /AllInstances"
                            $cmd | Out-File "$loc\patch.ps1"

                                ##invoke the powershell script to start patching------ DOESNT ALWAYS WORK
                            # $sessions = New-PSSession -ComputerName $Server 
                            #invoke-command -filepath "\\$Server\H$\patch.ps1" -Session $sessions -AsJob 



                            }
                  

                                elseif($ver.ToString() -Like  "Microsoft SQL Server 2014*")
                            {

                            WRITE-HOST "2014" $Server " " $ver 
                 
                                ##copy patch file locally to server
                            Copy-Item -Path "$path\SQL_2014\$2014patch" -Destination "$loc\$2014patch" -Force
                             #Copy-Item -Path "D:\Patching\$2014patch" -Destination "\\$Server\H$\$2014patch" -Force
                    
                    
                                ##create powershell patch file
                            $cmd = "H:\$2014patch /qs /IAcceptSQLServerLicenseTerms /Action=Patch /AllInstances"
                            $cmd | Out-File "$loc\patch.ps1"

                                ##invoke the powershell script to start patching ---DOESNT ALWAYS WORK
                            #$sessions = New-PSSession -ComputerName $Server 
                            #invoke-command -filepath "\\$Server\H$\patch.ps1" -Session $sessions -AsJob 

                    
                            }

                            
                                elseif($ver.ToString() -Like  "Microsoft SQL Server 2016*")
                            {
                             WRITE-HOST "2016" $Server " " $ver 
                 
                                ##copy patch file locally to server
                            Copy-Item -Path "$path\SQL_2016\$2016patch" -Destination "$loc\$2016patch" -Force
                             #Copy-Item -Path "D:\Patching\$2016patch" -Destination "\\$Server\H$\$2016patch" -Force
                    
                    
                                ##create powershell patch file
                            $cmd = "H:\$2016patch /qs /IAcceptSQLServerLicenseTerms /Action=Patch /AllInstances"
                            $cmd | Out-File "$loc\patch.ps1"

                                ##invoke the powershell script to start patching ---DOESNT ALWAYS WORK
                            #$sessions = New-PSSession -ComputerName $Server 
                            #invoke-command -filepath "\\$Server\H$\patch.ps1" -Session $sessions -AsJob 

                    
                            }

                   
                        
                }

                
                         $ver=""
                         $loc=""

}