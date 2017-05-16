# ********************************************* 
# ScriptName: Get-myFreeSpace.ps1 
# 
# Description: Script to get the free disk space 
#            : on a remote computer and display it usefully 
# 
# ModHist: 26/11/2014 - Initial, Charlie 
#        : 
# 
# 
# ********************************************* 
#[CmdletBinding()] 
#Param ([Parameter(Mandatory=$False,Position=0)] 
#         [String[]]$ComputerName = "Server1") 
#Write-Host "" 

$ComputerName = Get-Content “D:\FilesPowershell\SQL_Servers.txt”

# Configuration data. 
# Add your machine names to check for to the list: 

[float] $levelWarn  = 20.0;  # Warn-level in percent. 
[float] $levelAlarm = 10.0;  # Alarm-level in percent. 
 
# Defining output format for each column. 
$fmtServer =@{label="Server"      ;alignment="left"  ;width=15  ;Expression={$_.SystemName};};
$fmtDrive =@{label="Drv"      ;alignment="left"  ;width=3  ;Expression={$_.DeviceID};}; 
$fmtName  =@{label="Vol Name" ;alignment="left"  ;width=15 ;Expression={$_.VolumeName};}; 
$fmtSize  =@{label="Size MB"  ;alignment="right" ;width=12 ;Expression={$_.Size / 1048576};; FormatString="N0";}; 
$fmtFree  =@{label="Free MB"  ;alignment="right" ;width=12 ;Expression={$_.FreeSpace / 1048576}    ; FormatString="N0";}; 
$fmtPerc  =@{label="Free %"   ;alignment="right" ;width=10 ;Expression={100.0 * $_.FreeSpace / $_.Size}; FormatString="N1";}; 
$fmtMsg   =@{label="Message"  ;alignment="left"  ;width=12 ; ` 
              Expression={     if (100.0 * $_.FreeSpace / $_.Size -le $levelAlarm) {"Alarm !!!"} ` 
                           elseif (100.0 * $_.FreeSpace / $_.Size -le $levelWarn)  {"Warning !"} };}; 
 
foreach($server in $ComputerName) 
{ 
    $disks = Get-WmiObject -ComputerName $server -Class Win32_LogicalDisk -Filter "DriveType = 3"; 
     
#    Write-Output ("Server: {0}`tDrives #: {1}" -f $server, $disks.Count); 
    Write-Output $disks | Format-Table $fmtServer,$fmtDrive, $fmtName, $fmtSize, $fmtFree, $fmtPerc, $fmtMsg; 
}