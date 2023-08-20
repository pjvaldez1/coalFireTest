#CIS Benchmark Win2019 - 18.9.45.4.1.2 
<#
Ensure 'Configure Attack Surface 
Reduction rules: Set the state for each ASR rule' is 
configured – ‘26190899-1602-49e8-8b27-
eb1d0a1ce869
#>
$ruleId="26190899-1602-49e8-8b27-eb1d0a1ce869"
Add-MpPreference -AttackSurfaceReductionRules_Ids $ruleId  -AttackSurfaceReductionRules_Actions Enabled

#CIS Benchmark Winserver 2019 - 2.2.21
#
<# 
Deny access to this computer from 
the network' to include 'Guests, Local account and 
member of Administrators group' (MS only) - Guests, 
Local account and member of Administrators group
#>
Import-Module #C:\Path\To\Scripts\Set-UserRights.ps1
Set-UserRights -AddRight -Username S-1-5-113,S-1-5-114 -UserRight SeDenyNetworkLogonRight
