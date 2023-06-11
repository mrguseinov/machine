$ErrorActionPreference = "Stop"

Import-Module "$PSScriptRoot\modules\common-utils.psm1" -Force
Import-Module "$PSScriptRoot\modules\network-utils.psm1" -Force

Restart-ScriptAsAdminNoExitOnce $PSCommandPath

Set-ColorVariables # $Red, $Green, $Warning

Write-Host "Importing data from 'variables.csv'..." -NoNewline
Import-VariablesFromCsv "$PSScriptRoot\variables.csv"
If (Test-VariablesNotImported) {
    Write-Host " Error." @Red
    Write-Host "Something went wrong while importing the variables." @Warning
    Return
}
Write-Host " Done." @Green

Write-Host
$Input = Read-Host "Enter ports to allow through firewall (space separated)"
$Ports = Get-IntegersFromString $Input
Write-Host "Creating rule '$VmName' with ports '$($Ports -Join ', ')'..." -NoNewline
Add-PortsFirewallRule $VmName $Ports
Write-Host " Done." @Green
