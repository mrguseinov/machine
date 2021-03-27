$ErrorActionPreference = "Stop"

Add-Type -AssemblyName "System.Windows.Forms"

Import-Module "$PSScriptRoot\modules\common-utils.psm1" -Force

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
$SSHUserBackupFile = "$PSScriptRoot\ssh-user.txt"
$SSHUser = Get-Content $SSHUserBackupFile -ErrorAction "SilentlyContinue"
If ($Null -Eq $SSHUser) {
    $SSHUser = [Environment]::UserName
}
Show-Console
[System.Windows.Forms.SendKeys]::SendWait($SSHUser)
$SSHUser = Read-Host "Enter your Ubuntu username"
Set-Content -Path $SSHUserBackupFile -Value $SSHUser

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

Write-Host "Sending the public key to and getting the hostname from the VM..."
$Command = "echo $(Get-Content $PublicKeyPath) >> ~/.ssh/authorized_keys && "
$Command += "chmod 600 ~/.ssh/* && cat /etc/hostname"
$HostName = Send-CommandOverSSH $SSHUser $VMAddress $Command
If (($Null -Eq $HostName) -Or ($HostName -IsNot [String])) {
    Write-Host "For some reason, SSH command failed." @Warning
    Return
}

$ConfigFilePath = "$ConfigFolderPath\config"
Write-Host "Adding configuration to $ConfigFilePath..." -NoNewline
$HostParams = @{
    Host         = $HostName
    HostName     = $VMAddress
    User         = $SSHUser
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
