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
Write-Host "Creating a new SSH key pair using the 'Ed25519' algorithm..." -NoNewline
$ConfigFolderPath = "$HOME\.ssh"
$KeyFilesPath = "$ConfigFolderPath\$VmName"
Try {
    New-Item -ItemType "Directory" -Path $ConfigFolderPath -Force | Out-Null
    $ItemsCountBefore = Get-NumberOfItemsInFolder $ConfigFolderPath
    $PublicKeyPath, $PrivateKeyPath = New-SSHKeys "ed25519" $KeyFilesPath
    $ItemsCountAfter = Get-NumberOfItemsInFolder $ConfigFolderPath
    If ($ItemsCountBefore -Eq $ItemsCountAfter) {
        Throw "No files (keys) have been created."
    }
    Write-Host " Done." @Green
}
Catch {
    Write-Host " Error." @Red
    Write-Host $_.Exception.Message @Warning
    Return
}

Write-Host "Sending public key to and getting username and hostname from the VM..."
$PublicKeyContent = Get-Content $PublicKeyPath
$Command = "echo $PublicKeyContent >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/*"
$Command += "&& whoami && cat /etc/hostname"
$Result = Send-CommandOverSSH $VMAddress $Command
If (($Null -Eq $Result) -Or ($Result.Length -Ne 2)) {
    Write-Host "For some reason, SSH command failed." @Warning
    Return
}
$UserName, $HostName = $Result[0], $Result[1]

$ConfigFilePath = "$ConfigFolderPath\config"
Write-Host "Adding configuration to $ConfigFilePath..." -NoNewline
$HostParams = @{
    Host         = $HostName
    HostName     = $VMAddress
    User         = $UserName
    IdentityFile = $PrivateKeyPath
}
Try {
    Add-HostToSSHConfig $ConfigFilePath $HostParams
    Write-Host " Done." @Green
}
Catch {
    Write-Host " Error." @Red
    Write-Host $_.Exception.Message @Warning
    Return
}
