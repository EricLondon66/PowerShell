Set-Location "D:\Patching"

$compArray = get-content D:\Patching\DEVPatching.txt

$serverfile=$env:computername

$PatchFileDirectory = "D:\Patching"

$2012PatchfilePath = "$PatchFileDirectory\SQL2012"
$2014PatchfilePath = "$PatchFileDirectory\SQL2014"
$2016PatchfilePath = "$PatchFileDirectory\SQL2016"

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
        write-host "$Server SAS Server" -ForegroundColor Yellow
        Copy-Item -Path "$2012PatchfilePath\$2012PatchfileName" -Destination "$destinationFolder\$2012PatchfileName" -Recurse -Force               
        ##create powershell patch file
        $cmd = "H:\PATCH\$2012PatchfileName /qs /IAcceptSQLServerLicenseTerms /Action=Patch /AllInstances"
        $cmd | Out-File "\\$Server\H$\SQLServerPatchScript.ps1"
    }
    elseIf ( $Server -like  "*DQS*")
    {
        write-host "$Server DQS Server : Copy File Manually" -BackgroundColor Red
    }
    Else
    {
        $destinationFolder = "\\$Server\H$\PATCH"
        if (!(Test-Path -path $destinationFolder)) {New-Item $destinationFolder -Type Directory}

        $version =Invoke-Sqlcmd -ServerInstance $Server -Query "SELECT @@Version AS 'Version'"
        $ver=$version.Version.Substring(0,25)

        if($ver.ToString() -Like  "Microsoft SQL Server 2012*")
        {
            ##copy patch file locally to server
            write-host $Server $ver -BackgroundColor Green
            Copy-Item -Path "$2012PatchfilePath\$2012PatchfileName" -Destination "$destinationFolder\$2012PatchfileName" -Recurse -Force               
            ##create powershell patch file
            $cmd = "H:\PATCH\$2012PatchfileName /qs /IAcceptSQLServerLicenseTerms /Action=Patch /AllInstances"
            $cmd | Out-File "\\$Server\H$\SQLServerPatchScript.ps1"
        }
        elseif($ver.ToString() -Like  "Microsoft SQL Server 2014*")
        {
            ##copy patch file locally to server
            write-host $Server $ver -BackgroundColor Green
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


function Get-LatestFileName {
    Param([string]$filePath)
    $latest = Get-ChildItem -Path $filePath | Sort-Object LastAccessTime -Descending | Select-Object -First 1
    return $latest.name
}
