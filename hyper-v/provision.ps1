$ErrorActionPreference = "Stop"

Import-Module "$PSScriptRoot\modules\common-utils.psm1"

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

Write-Host "Finding the virtual machine '$VmName'..." -NoNewline
Try {
    $Machine = Get-VM $VmName
    Write-Host " Done." @Green
}
Catch {
    Write-Host " Error." @Red
    Write-Host $_.Exception.Message @Warning
    Return
}

Write-Host "Is the machine '$VmName' running?" -NoNewline
If ($Machine.State -Ne "Running") {
    Write-Host " No." @Red
    Try {
        Write-Host "Starting the virtual machine '$VmName'..." -NoNewline
        Start-VM -Name $VmName
        Write-Host " Done." @Green
    }
    Catch {
        Write-Host " Error." @Red
        Write-Host $_.Exception.Message @Warning
        Return
    }
}
Else {
    Write-Host " Yes." @Green
}

Write-Host "Is the machine accessible over the network?" -NoNewline
If (Test-HostNotPinging $VMAddress) {
    Write-Host " No." @Red
    Write-Host "For some reason, we cannot ping '$VMAddress'." @Warning
    Return
}
Write-Host " Yes." @Green

Write-Host
Write-Host "Connecting to the machine over SSH to start provisioning..."
$Command = "echo && cd ~ && rm -rf machine/ && "
$Command += "git clone https://github.com/mrguseinov/machine.git && "
$Command += "bash machine/ubuntu/bootstrap.sh"
Send-CommandOverSSHWithPTY $VMAddress $Command
