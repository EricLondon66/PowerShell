# Display the drive space on all drives
# if any have < 20% free space, log to a file for review
# foreach ($computer in cat C:\batch\servers.txt) {DriveSpace "$computer"}
# This assumes you have saved a list of computernames to check in the file 'servers.txt'

function DriveSpace {
param( [string] $strComputer) 
"$strComputer ---- Free Space (percentage) ----"

# Does the server responds to a ping (otherwise the WMI queries will fail)

$query = "select * from win32_pingstatus where address = '$strComputer'"
$result = Get-WmiObject -query $query
if ($result.protocoladdress) {

    # Get the Disks for this computer
    $colDisks = get-wmiobject Win32_LogicalDisk -computername $strComputer -Filter "DriveType = 3"

    # For each disk calculate the free space
    foreach ($disk in $colDisks) {
       if ($disk.size -gt 0) {$PercentFree = [Math]::round((($disk.freespace/$disk.size) * 100))}
       else {$PercentFree = 0}

  $Drive = $disk.DeviceID
       "$strComputer - $Drive - $PercentFree"

       # if  < 20% free space, log to a file
       if ($PercentFree -le 20) {"$strComputer - $Drive - $PercentFree" | out-file -append -filepath "C:\logs\Drive Space.txt"}
    }
}
}

function GetDriveSpace {
param( [string] $strComputer) 

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
 
$disks = Get-WmiObject -ComputerName $strComputer -Class Win32_LogicalDisk -Filter "DriveType = 3"; 
     
#    Write-Output ("Server: {0}`tDrives #: {1}" -f $server, $disks.Count); 
    Write-Output $disks | Format-Table $fmtServer,$fmtDrive, $fmtName, $fmtSize, $fmtFree, $fmtPerc, $fmtMsg; 

}

<# 
.SYNOPSIS 
Get-Uptime retrieves boot up information from a Aomputer. 
.DESCRIPTION 
Get-Uptime uses WMI to retrieve the Win32_OperatingSystem 
LastBootuptime property. It displays the start up time 
as well as the uptime. 
 
Created By: Jason Wasser @wasserja 
Modified: 8/13/2015 01:59:53 PM   
Version 1.4 
 
Changelog: 
 * Added Credential parameter 
 * Changed to property hash table splat method 
 * Converted to function to be added to a module. 
 
.PARAMETER ComputerName 
The Computer name to query. Default: Localhost. 
.EXAMPLE 
Get-Uptime -ComputerName SERVER-R2 
Gets the uptime from SERVER-R2 
.EXAMPLE 
Get-Uptime -ComputerName (Get-Content C:\Temp\Computerlist.txt) 
Gets the uptime from a list of computers in c:\Temp\Computerlist.txt. 
.EXAMPLE 
Get-Uptime -ComputerName SERVER04 -Credential domain\serveradmin 
Gets the uptime from SERVER04 using alternate credentials. 
#> 
Function Get-Uptime { 
    [CmdletBinding()] 
    param ( 
        [Parameter(Mandatory=$false, 
                        Position=0, 
                        ValueFromPipeline=$true, 
                        ValueFromPipelineByPropertyName=$true)] 
        [Alias("Name")] 
        [string[]]$ComputerName=$env:COMPUTERNAME, 
        $Credential = [System.Management.Automation.PSCredential]::Empty 
        ) 
 
    begin{} 
 
    #Need to verify that the hostname is valid in DNS 
    process { 
        foreach ($Computer in $ComputerName) { 
            try { 
                $hostdns = [System.Net.DNS]::GetHostEntry($Computer) 
                $OS = Get-WmiObject win32_operatingsystem -ComputerName $Computer -ErrorAction Stop -Credential $Credential 
                $BootTime = $OS.ConvertToDateTime($OS.LastBootUpTime) 
                $Uptime = $OS.ConvertToDateTime($OS.LocalDateTime) - $boottime 
                $propHash = [ordered]@{ 
                    ComputerName = $Computer 
                    BootTime     = $BootTime 
                    Uptime       = $Uptime 
                    } 
                $objComputerUptime = New-Object PSOBject -Property $propHash 
                $objComputerUptime 
                }  
            catch [Exception] { 
                Write-Output "$computer $($_.Exception.Message)" 
                #return 
                } 
        } 
    } 
    end{} 
}


function FuncCheckService{
#to call run the following
#FuncCheckService -ServiceName "SQLSERVERAGENT"
    param($ServiceName)
    $arrService = Get-Service -Name $ServiceName
    if ($arrService.Status -ne "Running"){
        Start-Service $ServiceName
        FuncMail -To "e.gumo@qmul.ac.uk" -From "e.gumo@qmul.ac.uk"  -Subject "Servername : ($ServiceName) service started." -Body "Service $ServiceName started. Please review the logs as soon as possible." -smtpServer "smtp.qmul.ac.uk"
    }
}
 
function FuncMail {
    #param($strTo, $strFrom, $strSubject, $strBody, $smtpServer)
    param($To, $From, $Subject, $Body, $smtpServer)
    $msg = new-object Net.Mail.MailMessage
    $smtp = new-object Net.Mail.SmtpClient($smtpServer)
    $msg.From = $From
    $msg.To.Add($To)
    $msg.Subject = $Subject
    $msg.IsBodyHtml = 1
    $msg.Body = $Body
    $smtp.Send($msg)
}
 
Function Get-PendingReboot 
{ 
<# 
.SYNOPSIS 
    Gets the pending reboot status on a local or remote computer. 
 
.DESCRIPTION 
    This function will query the registry on a local or remote computer and determine if the 
    system is pending a reboot, from either Microsoft Patching or a Software Installation. 
    For Windows 2008+ the function will query the CBS registry key as another factor in determining 
    pending reboot state.  "PendingFileRenameOperations" and "Auto Update\RebootRequired" are observed 
    as being consistant across Windows Server 2003 & 2008. 
   
    CBServicing = Component Based Servicing (Windows 2008) 
    WindowsUpdate = Windows Update / Auto Update (Windows 2003 / 2008) 
    CCMClientSDK = SCCM 2012 Clients only (DetermineIfRebootPending method) otherwise $null value 
    PendFileRename = PendingFileRenameOperations (Windows 2003 / 2008) 
 
.PARAMETER ComputerName 
    A single Computer or an array of computer names.  The default is localhost ($env:COMPUTERNAME). 
 
.PARAMETER ErrorLog 
    A single path to send error data to a log file. 
 
.EXAMPLE 
    PS C:\> Get-PendingReboot -ComputerName (Get-Content C:\ServerList.txt) | Format-Table -AutoSize 
   
    Computer CBServicing WindowsUpdate CCMClientSDK PendFileRename PendFileRenVal RebootPending 
    -------- ----------- ------------- ------------ -------------- -------------- ------------- 
    DC01     False   False           False      False 
    DC02     False   False           False      False 
    FS01     False   False           False      False 
 
    This example will capture the contents of C:\ServerList.txt and query the pending reboot 
    information from the systems contained in the file and display the output in a table. The 
    null values are by design, since these systems do not have the SCCM 2012 client installed, 
    nor was the PendingFileRenameOperations value populated. 
 
.EXAMPLE 
    PS C:\> Get-PendingReboot 
   
    Computer     : WKS01 
    CBServicing  : False 
    WindowsUpdate      : True 
    CCMClient    : False 
    PendComputerRename : False 
    PendFileRename     : False 
    PendFileRenVal     :  
    RebootPending      : True 
   
    This example will query the local machine for pending reboot information. 
   
.EXAMPLE 
    PS C:\> $Servers = Get-Content C:\Servers.txt 
    PS C:\> Get-PendingReboot -Computer $Servers | Export-Csv C:\PendingRebootReport.csv -NoTypeInformation 
   
    This example will create a report that contains pending reboot information. 
 
.LINK 
    Component-Based Servicing: 
    http://technet.microsoft.com/en-us/library/cc756291(v=WS.10).aspx 
   
    PendingFileRename/Auto Update: 
    http://support.microsoft.com/kb/2723674 
    http://technet.microsoft.com/en-us/library/cc960241.aspx 
    http://blogs.msdn.com/b/hansr/archive/2006/02/17/patchreboot.aspx 
 
    SCCM 2012/CCM_ClientSDK: 
    http://msdn.microsoft.com/en-us/library/jj902723.aspx 
 
.NOTES 
    Author:  Brian Wilhite 
    Email:   bcwilhite (at) live.com 
    Date:    29AUG2012 
    PSVer:   2.0/3.0/4.0/5.0 
    Updated: 01DEC2014 
    UpdNote: Added CCMClient property - Used with SCCM 2012 Clients only 
       Added ValueFromPipelineByPropertyName=$true to the ComputerName Parameter 
       Removed $Data variable from the PSObject - it is not needed 
       Bug with the way CCMClientSDK returned null value if it was false 
       Removed unneeded variables 
       Added PendFileRenVal - Contents of the PendingFileRenameOperations Reg Entry 
       Removed .Net Registry connection, replaced with WMI StdRegProv 
       Added ComputerPendingRename 
#> 
 
[CmdletBinding()] 
param( 
  [Parameter(Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)] 
  [Alias("CN","Computer")] 
  [String[]]$ComputerName="$env:COMPUTERNAME", 
  [String]$ErrorLog 
  ) 
 
Begin {  }## End Begin Script Block 
Process { 
  Foreach ($Computer in $ComputerName) { 
  Try { 
      ## Setting pending values to false to cut down on the number of else statements 
      $CompPendRen,$PendFileRename,$Pending,$SCCM = $false,$false,$false,$false 
       
      ## Setting CBSRebootPend to null since not all versions of Windows has this value 
      $CBSRebootPend = $null 
             
      ## Querying WMI for build version 
      $WMI_OS = Get-WmiObject -Class Win32_OperatingSystem -Property BuildNumber, CSName -ComputerName $Computer -ErrorAction Stop 
 
      ## Making registry connection to the local/remote computer 
      $HKLM = [UInt32] "0x80000002" 
      $WMI_Reg = [WMIClass] "\\$Computer\root\default:StdRegProv" 
             
      ## If Vista/2008 & Above query the CBS Reg Key 
      If ([Int32]$WMI_OS.BuildNumber -ge 6001) { 
        $RegSubKeysCBS = $WMI_Reg.EnumKey($HKLM,"SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\") 
        $CBSRebootPend = $RegSubKeysCBS.sNames -contains "RebootPending"     
      } 
               
      ## Query WUAU from the registry 
      $RegWUAURebootReq = $WMI_Reg.EnumKey($HKLM,"SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\") 
      $WUAURebootReq = $RegWUAURebootReq.sNames -contains "RebootRequired" 
             
      ## Query PendingFileRenameOperations from the registry 
      $RegSubKeySM = $WMI_Reg.GetMultiStringValue($HKLM,"SYSTEM\CurrentControlSet\Control\Session Manager\","PendingFileRenameOperations") 
      $RegValuePFRO = $RegSubKeySM.sValue 
 
      ## Query ComputerName and ActiveComputerName from the registry 
      $ActCompNm = $WMI_Reg.GetStringValue($HKLM,"SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName\","ComputerName")       
      $CompNm = $WMI_Reg.GetStringValue($HKLM,"SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName\","ComputerName") 
      If ($ActCompNm -ne $CompNm) { 
    $CompPendRen = $true 
      } 
             
      ## If PendingFileRenameOperations has a value set $RegValuePFRO variable to $true 
      If ($RegValuePFRO) { 
        $PendFileRename = $true 
      } 
 
      ## Determine SCCM 2012 Client Reboot Pending Status 
      ## To avoid nested 'if' statements and unneeded WMI calls to determine if the CCM_ClientUtilities class exist, setting EA = 0 
      $CCMClientSDK = $null 
      $CCMSplat = @{ 
    NameSpace='ROOT\ccm\ClientSDK' 
    Class='CCM_ClientUtilities' 
    Name='DetermineIfRebootPending' 
    ComputerName=$Computer 
    ErrorAction='Stop' 
      } 
      ## Try CCMClientSDK 
      Try { 
    $CCMClientSDK = Invoke-WmiMethod @CCMSplat 
      } Catch [System.UnauthorizedAccessException] { 
    $CcmStatus = Get-Service -Name CcmExec -ComputerName $Computer -ErrorAction SilentlyContinue 
    If ($CcmStatus.Status -ne 'Running') { 
        Write-Warning "$Computer`: Error - CcmExec service is not running." 
        $CCMClientSDK = $null 
    } 
      } Catch { 
    $CCMClientSDK = $null 
      } 
 
      If ($CCMClientSDK) { 
    If ($CCMClientSDK.ReturnValue -ne 0) { 
      Write-Warning "Error: DetermineIfRebootPending returned error code $($CCMClientSDK.ReturnValue)"     
        } 
        If ($CCMClientSDK.IsHardRebootPending -or $CCMClientSDK.RebootPending) { 
      $SCCM = $true 
        } 
      } 
       
      Else { 
    $SCCM = $null 
      } 
 
      ## Creating Custom PSObject and Select-Object Splat 
      $SelectSplat = @{ 
    Property=( 
        'Computer', 
        'CBServicing', 
        'WindowsUpdate', 
        'CCMClientSDK', 
        'PendComputerRename', 
        'PendFileRename', 
        'PendFileRenVal', 
        'RebootPending' 
    )} 
      New-Object -TypeName PSObject -Property @{ 
    Computer=$WMI_OS.CSName 
    CBServicing=$CBSRebootPend 
    WindowsUpdate=$WUAURebootReq 
    CCMClientSDK=$SCCM 
    PendComputerRename=$CompPendRen 
    PendFileRename=$PendFileRename 
    PendFileRenVal=$RegValuePFRO 
    RebootPending=($CompPendRen -or $CBSRebootPend -or $WUAURebootReq -or $SCCM -or $PendFileRename) 
      } | Select-Object @SelectSplat 
 
  } Catch { 
      Write-Warning "$Computer`: $_" 
      ## If $ErrorLog, log the file to a user specified location/path 
      If ($ErrorLog) { 
    Out-File -InputObject "$Computer`,$_" -FilePath $ErrorLog -Append 
      }         
  }       
  }## End Foreach ($Computer in $ComputerName)       
}## End Process 
 
End {  }## End End 
 
}## End Function Get-PendingReboot

function Set-PowerPlan {

	$PreferredPlan = "High Performance"
	 
	Write-Verbose "Setting power plan to `"$PreferredPlan`""
	$guid = (Get-WmiObject -Class Win32_PowerPlan -Namespace root\cimv2\power -Filter "ElementName='$PreferredPlan'").InstanceID.ToString()
	$regex = [regex]"{(.*?)}$"
	$plan = $regex.Match($guid).groups[1].value 
	
	powercfg -S $plan
	$Output = "Power plan set to "
	$Output += "`"" + ((Get-WmiObject -Class Win32_PowerPlan -Namespace root\cimv2\power -Filter "IsActive='$True'").ElementName) + "`""
	Write-Verbose $Output
}