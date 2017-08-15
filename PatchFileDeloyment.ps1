#Gets the latest file within a directory
function Get-LatestFileName {
    Param([string]$filePath)
    $latest = Get-ChildItem -Path $filePath | Sort-Object LastAccessTime -Descending | Select-Object -First 1
    return $latest.name
}

#Set-Location "D:\FilesPowershell"

#Get SQL Servers from text file
#$compArray = get-content D:\FilesPowershell\SQL_Servers_Patch.txt

#get SQL servers from table
push-location
import-module sqlps -disablenamechecking
$compArray = @(Invoke-SQLCmd -query "SELECT DISTINCT [Server] FROM [DBA_Toolbox]" -Server SQL-XXX-XX) | select-object -expand Server
pop-location

$serverfile=$env:computername

$PatchFileDirectory = "\SQL_Server_Software\PATCHES"

$2012PatchfilePath = "$PatchFileDirectory\SQL_2012"
$2014PatchfilePath = "$PatchFileDirectory\SQL_2014"
$2016PatchfilePath = "$PatchFileDirectory\SQL_2016"

$2012PatchfileName = Get-LatestFileName($2012PatchfilePath)
$2014PatchfileName = Get-LatestFileName($2014PatchfilePath)
$2016PatchfileName = Get-LatestFileName($2016PatchfilePath)

foreach($Server in $compArray)
{
    write-host "Testing connection to : $Server"

    If ( $Server -like  "*SAS*")
    {
       $destinationFolder = "\\$Server\H$\PATCH"
        if (!(Test-Path -path $destinationFolder)) {New-Item $destinationFolder -Type Directory}
        Remove-Item "\\$Server\H$\PATCH\*" -Recurse 
        write-host "$Server SAS Server" -ForegroundColor Yellow
        Copy-Item -Path "$2012PatchfilePath\$2012PatchfileName" -Destination "$destinationFolder\$2012PatchfileName" -Recurse -Force               
        ##create powershell patch file
        $cmd = "H:\PATCH\$2012PatchfileName /qs /IAcceptSQLServerLicenseTerms /Action=Patch /AllInstances"
        $cmd | Out-File "\\$Server\H$\SQLServerPatchScript.ps1"
    }
    elseIf ( $Server -like  "*DQS*" )
    {
##        write-host "$Server DQS Server : Copy File Manually" -BackgroundColor Red
        $destinationFolder = "\\$Server\H$\PATCH"
        if (!(Test-Path -path $destinationFolder)) {New-Item $destinationFolder -Type Directory}
        Remove-Item "\\$Server\H$\PATCH\*" -Recurse 
        write-host "$Server DQS Server" -ForegroundColor Yellow
        Copy-Item -Path "$2012PatchfilePath\$2012PatchfileName" -Destination "$destinationFolder\$2012PatchfileName" -Recurse -Force               
        ##create powershell patch file
        $cmd = "H:\PATCH\$2012PatchfileName /qs /IAcceptSQLServerLicenseTerms /Action=Patch /AllInstances"
        $cmd | Out-File "\\$Server\H$\SQLServerPatchScript.ps1"
    }
    Else
    {
        $destinationFolder = "\\$Server\H$\PATCH"
        if (!(Test-Path -path $destinationFolder)) {New-Item $destinationFolder -Type Directory}
        Remove-Item "\\$Server\H$\PATCH\*" -Recurse 

        $version =Invoke-Sqlcmd -ServerInstance $Server -Query "SELECT @@Version AS 'Version'"
        $ver=$version.Version.Substring(0,25)

        if($ver.ToString() -Like  "Microsoft SQL Server 2012*")
        {
            ##copy patch file locally to server
            write-host $Server $ver -BackgroundColor Gray
            Copy-Item -Path "$2012PatchfilePath\$2012PatchfileName" -Destination "$destinationFolder\$2012PatchfileName" -Recurse -Force               
            ##create powershell patch file
            $cmd = "H:\PATCH\$2012PatchfileName /qs /IAcceptSQLServerLicenseTerms /Action=Patch /AllInstances"
            $cmd | Out-File "\\$Server\H$\SQLServerPatchScript.ps1"
        }
        elseif($ver.ToString() -Like  "Microsoft SQL Server 2014*")
        {
            ##copy patch file locally to server
            ##write-host "$Server $ver : SKIPPED"
            write-host $Server $ver -BackgroundColor Cyan
            Copy-Item -Path "$2014PatchfilePath\$2014PatchfileName" -Destination "$destinationFolder\$2014PatchfileName" -Recurse -Force               
            ##create powershell patch file
            $cmd = "H:\PATCH\$2014PatchfileName /qs /IAcceptSQLServerLicenseTerms /Action=Patch /AllInstances"
            $cmd | Out-File "\\$Server\H$\SQLServerPatchScript.ps1"
        }
        elseif($ver.ToString() -Like  "Microsoft SQL Server 2016*")
        {
            ##copy patch file locally to server
            write-host $Server $ver -BackgroundColor Green
            Copy-Item -Path "$2016PatchfilePath\$2016PatchfileName" -Destination "$destinationFolder\$2016PatchfileName" -Recurse -Force               
            ##create powershell patch file
            $cmd = "H:\PATCH\$2016PatchfileName /qs /IAcceptSQLServerLicenseTerms /Action=Patch /AllInstances"
            $cmd | Out-File "\\$Server\H$\SQLServerPatchScript.ps1"
        }
        else
        {
            WRITE-HOST "$Server Unknown Version : EXIT" -BackgroundColor Red
        }
    }
}

