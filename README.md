# clc-powershell
PowerShell Module for interfacing with CenturyLink Cloud API



# Install 

To install in your personal modules folder (e.g. ~\Documents\WindowsPowerShell\Modules), run:

```powershell
iex (new-object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/cdhunt/clc-powershell/master/install.ps1')
```

# Example Usage Report

Here is an example script that utilizes this module to get Group and Server details.

```powershell
$auth = Get-ClcAuthenticationHeader user.name
$dc = Get-CLCDataCenter -Authentication $auth -AccountAlias ABC -DataCenter VA1 -GroupLink
$groups = $dc | Expand-ClcLink -Relation group -Authentication $auth
$servers = $groups.groups.where({$_.name -eq 'Default Group'}).groups | Expand-ClcLink -Relation server -Authentication $auth

$report = foreach ($server in $servers) 
{
    $billingDetail = $server | Expand-ClcLink -Relation billing -Authentication $auth
    
    $ipAddress = $server.details | Select-Object -ExpandProperty ipAddresses -First 1 | Select-Object -ExpandProperty internal
    $publicAddress = $server.details | Select-Object -ExpandProperty ipAddresses -First 1 | Select-Object -ExpandProperty public -ErrorAction SilentlyContinue
    $cpu = $server.details.cpu
    $memoryMB = $server.details.memoryMB
    $storageGB = $server.details.storageGB

    $hours = 720
    $cpuCost = $billingDetail.cpu * $cpu * $hours
    $memoryCost = $billingDetail.memoryGB * ($memoryMB/1024) * $hours
    $storageCost = $billingDetail.storageGB * $storageGB * $hours
    $manageCosts = $billingDetail.managedOS  * $hours

    $server | Select-Object Name, 
                            status, 
                            type, 
                            osType, 
                            storageType, 
                            @{N='ipAddress';E={$ipAddress}}, 
                            @{N='cpu';E={$cpu}}, 
                            @{N='memoryMB';E={$memoryMB}}, 
                            @{N='storageGB';E={$storageGB}},
                            @{N='costPerMonth';E={[Math]::Round( ($cpuCost + $memoryCost + $storageCost + $manageCosts), 2)}} |
                Write-Output
}

$sum = $report | Measure-Object -Property cpu, memoryMB, storageGB, costPerMonth -Sum
$cpuTotal = $sum.Where({$_.Property -eq 'cpu'}).Sum
$memoryTotal = $sum.Where({$_.Property -eq 'memoryMB'}).Sum
$storageTotal = $sum.Where({$_.Property -eq 'storageGB'}).Sum
$costTotal = $sum.Where({$_.Property -eq 'costPerMonth'}).Sum

$report += [PSCustomObject]@{name="TOTAL"
                             status='-'
                             type='-'
                             osType='-'
                             storageType='-'
                             ipAddress='-'
                             cpu = $cpuTotal
                             memoryMB = $memoryTotal
                             storageGB = $storageTotal
                             costPerMonth= $costTotal }

$report | Format-Table -AutoSize
```