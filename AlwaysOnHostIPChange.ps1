#************************************************************************** 
#This script is provided "AS IS" with no warranties, and confers no rights. 
#   Use of included script samples are subject to the terms specified at 
#   http://www.microsoft.com/info/cpyright.htm 
#**************************************************************************

#************************************************************************** 
#  VARIABLES 
#$strAGName          the name of the availability group 
#$TTLValue           the # of seconds for HostRecordTTL timeout value 
#$AllIPs             [0 | 1] 0 = only register one IP, 1 = register all IPs 
#$RestartListener    [0 | 1] 1 = restart listener / 0 = do not restart 
#$RemoveDependencies [0 | 1] 1 = temporarily remove / 0 = leave alone 
#**************************************************************************

#************************************************************************** 
# 
# CHANGE THESE VARIABLES 
#Define Variables 
$strAGName = "DEVSQLRSTAG"         #<<<<<<<<<<<<<<<<<<<<<<<<< 
$TTLValue = "60"             #<<<<<<<<<<<<<<<<<<<<<<<<< 
$AllIPs = 1                   #<<<<<<<<<<<<<<<<<<<<<<<<< 
$RestartListener = 1          #<<<<<<<<<<<<<<<<<<<<<<<<< 
$RemoveDependencies = 1       #<<<<<<<<<<<<<<<<<<<<<<<<< 
# 
#**************************************************************************

#************************************************************************** 
#Notes:  
#   1) Test this script in non-production environments first. 
#   2) This script will change the parameters for _all_ listeners 
#      for the specified availability group  
#   3) This script can optionally restart the listener(s) 
#   4) if restaring listeners, it can optionally temporarily 
#      remove and restore the dependencies to take the 
#      listener(s) offline without taking the availability group 
#      itself offline.  If choosing not to temporarily remove 
#      and restore dependencies, then when the listener(s) are 
#      taken offline, the availability group resource will also 
#      go offline – thus making the databases in the AG inaccessible. 
#   5) if choosing to remove dependencies, the existing depenedencies 
#      are collected and restored after restaring the listener(s) 
#   6) Windows Server 2012/2012R2 has a powershell command to 
#      re-register listener(s) with DNS.  Server 2008/2008R2 does 
#      does not.  there is logic to determine and use the CLUSTER.EXE 
#      command for Windows Server 2008/2008R2 
#**************************************************************************

#no changes required below this point

#Get OS version 
$OSMajor = ([System.Environment]::OSVersion.Version).Major 
$OSMinor = ([System.Environment]::OSVersion.Version).Minor

#load cluster module 
Import-Module FailoverClusters

#get the cluster role (group) object based on the AG name provided above 
$objAGGroup = Get-ClusterGroup $strAGName -ErrorAction SilentlyContinue

if ($objAGGroup -eq $null) 
    {Write-Host "Error:  Availability Group not found."} 
else 
    { 
    #get the AG resource object in this cluster role (group) 
    $objAGRes = $objAGGroup | Get-ClusterResource | 
        Where-Object {$_.ResourceType -match "SQL Server Availability Group*"} 
    #get the listener(s) object(s) in this cluster role (group) 
    $objListener = $objAGGroup | Get-ClusterResource | 
          Where-Object {$_.ResourceType -match "Network Name*"}

    #change the parameter settings: HostRecordTTL & RegisterAllProvidersIP 
    Write-Host "Making changes to Network Name:"  $list.Name 
    $objListener | Set-ClusterParameter -Name HostRecordTTL -Value $TTLValue 
    $objListener | Set-ClusterParameter -Name RegisterAllProvidersIP -Value @AllIPs 
    $objListener | Get-ClusterParameter -Name HostRecordTTL 
    $objListener | Get-ClusterParameter -Name RegisterAllProvidersIP

    if ($RestartListener -eq 1) { 
        if($RemoveDependencies -eq 1) { 
            #capture the dependency(ies) that the AG resource depends on 
            $DepStr = ($objAGRes | Get-ClusterResourceDependency).DependencyExpression 
            Write-Host "Removing dependecny for " $objAGRes.Name  " on ‘" $DepStr "’" 
             Set-ClusterResourceDependency -Resource $objAGRes -Dependency $null 
        } #if remove dependencies

        #restart the listener resource(es) 
        Write-Host "Restarting Network Name resource:" $list.Name 
        $objListener | Stop-ClusterResource 
        $objListener | Start-ClusterResource

        #force re-registration in DNS 
        if ($OSMajor -ge 6 -and $OSMinor -ge 2) { 
            #Windows Server 2012 and up 
            $objListener | Update-ClusterNetworkNameResource -Verbose 
         } 
        else { 
            #for Windows Server 2008/2008R2 
             ForEach($list in $objListener) { 
                cluster.exe res $list.name  /registerdns 
            }#foreach 
         } 
        if($RemoveDependencies -eq 1) { 
            #restore the dependency(ies) to previous setting 
            Write-Host "Reapplying dependencies for " $objAGRes.Name 
            Set-ClusterResourceDependency -Resource $objAGRes -Dependency $DepStr 
            #show dependency (so it can be compared) / show the settings 
            $objAGRes | Get-ClusterResourceDependency 
        } #if remove dependencies 
        else { 
        #if we chose not to remove dependencies we need to restart 
        #the availability group resource 
        $objAGRes | Start-ClusterResource 
        } 
    } #if restart 
}#else – availability group found