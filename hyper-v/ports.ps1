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
$Input = Read-Host "Enter ports to forward (space separated)"
$Ports = $Input -Split "\D+"  | Where-Object {$_ -Ne ""} | ForEach-Object { [Int]$_ }
Write-Host "Forwarding ports: $($Ports -Join ', ')..." -NoNewline
Foreach ($Port in $Ports) {
    Add-PortForwardingRule $VMAddress $Port
}
Write-Host " Done." @Green
