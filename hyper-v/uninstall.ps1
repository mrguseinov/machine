$ErrorActionPreference = "Stop"

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

Write-Host
Write-Host "You are about to delete '$VmName' machine and all its related data." @Red
$Decision = Read-Host "Continue? Delete the machine and its data? [y/N]"
If (Test-DecisionNotPositive $Decision) {
    Return
}
Write-Host

Write-Host "Finding the virtual machine '$VmName'..." -NoNewline
$Machine = Get-VM $VmName -ErrorAction "SilentlyContinue"
If ($Null -Ne $Machine) {
    Write-Host " Done." @Green

    Write-Host "Is the machine '$VmName' turned off?" -NoNewline
    If ($Machine.State -Ne "Off") {
        Write-Host " No." @Red
        Try {
            Write-Host "Turning off the virtual machine '$VmName'..." -NoNewline
            Stop-VM -Name $VmName -TurnOff -Force
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

    Write-Host
    Write-Host "Deleting the '$VmName' machine..." -NoNewline
    Try {
        Remove-VM -Name $VmName -Force
        Write-Host " Done." @Green
    }
    Catch {
        Write-Host " Error." @Red
        Write-Host $_.Exception.Message @Warning
        Return
    }
}
Else {
    Write-Host " Skip." @Green
    Write-Host "The machine was not found." @Warning
    Write-Host
}

Write-Host "Deleting the '$SwitchName' vSwitch..." -NoNewline
$Switch = Get-VMSwitch $SwitchName -ErrorAction "SilentlyContinue"
If ($Null -Ne $Switch) {
    Try {
        Remove-VMSwitch -Name $SwitchName -Force
        Write-Host " Done." @Green
    }
    Catch {
        Write-Host " Error." @Red
        Write-Host $_.Exception.Message @Warning
    }
}
Else {
    Write-Host " Skip." @Green
    Write-Host "The switch was not found." @Warning
}

Write-Host "Deleting the '$NatName' NAT..." -NoNewline
$Nat = Get-NetNat $NatName -ErrorAction "SilentlyContinue"
If ($Null -Ne $Nat) {
    Try {
        Remove-NetNat -Name $NatName -Confirm:$False -ErrorAction "Stop"
        Write-Host " Done." @Green
    }
    Catch {
        Write-Host " Error." @Red
        Write-Host $_.Exception.Message @Warning
    }
}
Else {
    Write-Host " Skip." @Green
    Write-Host "The NAT was not found." @Warning
}

Write-Host "Deleting the '$VmPath' folder..." -NoNewline
If (Test-Path $VmPath -PathType "Container") {
    If (Test-PathsEqual $VmPath (Get-Location).Path) {
        Set-ParentLocationOrHome $VmPath
    }

    Try {
        Remove-Item -Path $VmPath -Recurse
        Write-Host " Done." @Green
    }
    Catch {
        Write-Host " Error." @Red
        Write-Host $_.Exception.Message @Warning
    }
}
Else {
    Write-Host " Skip." @Green
    Write-Host "The folder was not found." @Warning
}

$SSHFolderPath = "$HOME\.ssh"
Write-Host "Deleting the keys from '$SSHFolderPath'..." -NoNewline
$SSHKeysPath = "$SSHFolderPath\$VmName"
If (Test-Path "$SSHKeysPath*" -PathType "Leaf") {
    $ItemsCountBefore = Get-NumberOfItemsInFolder $SSHFolderPath
    Remove-Item -Path "$SSHKeysPath*"
    $ItemsCountAfter = Get-NumberOfItemsInFolder $SSHFolderPath

    If ($ItemsCountBefore -Gt $ItemsCountAfter) {
        Write-Host " Done." @Green
    }
    Else {
        Write-Host " Error." @Red
        Write-Host "The keys have not been deleted." @Warning
    }
}
Else {
    Write-Host " Skip." @Green
    Write-Host "The keys were not found." @Warning
}

$SSHConfigFilePath = "$SSHFolderPath\config"
Write-Host "Deleting the config from '$SSHConfigFilePath'..." -NoNewline
If (Test-Path $SSHConfigFilePath -PathType "Leaf") {
    If (Test-StringInFile $VMAddress $SSHConfigFilePath) {
        $LinesCountBefore = (Get-Content $SSHConfigFilePath).Length
        Remove-HostFromSHHConfig $VMAddress $SSHConfigFilePath
        $LinesCountAfter = (Get-Content $SSHConfigFilePath).Length

        If ($LinesCountBefore -Gt $LinesCountAfter) {
            Write-Host " Done." @Green
        }
        Else {
            Write-Host " Error." @Red
            Write-Host "The configuration has not been deleted." @Warning
        }
    }
    Else {
        Write-Host " Skip." @Green
        Write-Host "The '$VMAddress' hostname was not found." @Warning
    }
}
Else {
    Write-Host " Skip." @Green
    Write-Host "The file was not found." @Warning
}

$KnownHostsFilePath = "$SSHFolderPath\known_hosts"
Write-Host "Deleting the host from '$KnownHostsFilePath'..." -NoNewline
If (Test-Path $KnownHostsFilePath -PathType "Leaf") {
    If (Test-StringInFile $VMAddress $KnownHostsFilePath) {
        $LinesCountBefore = (Get-Content $KnownHostsFilePath).Length
        Remove-HostFromKnownHosts $VMAddress $KnownHostsFilePath
        $LinesCountAfter = (Get-Content $KnownHostsFilePath).Length

        If ($LinesCountBefore -Gt $LinesCountAfter) {
            Write-Host " Done." @Green
        }
        Else {
            Write-Host " Error." @Red
            Write-Host "The host has not been deleted." @Warning
        }
    }
    Else {
        Write-Host " Skip." @Green
        Write-Host "The '$VMAddress' host was not found." @Warning
    }
}
Else {
    Write-Host " Skip." @Green
    Write-Host "The file was not found." @Warning
}

Write-Host "Deleting the '$SSHFolderPath' folder (if empty)..." -NoNewline
If (Test-Path $SSHFolderPath -PathType "Container") {
    If (Test-PathsEqual $SSHFolderPath (Get-Location).Path) {
        Set-ParentLocationOrHome $SSHFolderPath
    }

    $FolderIsEmpty = (Get-NumberOfItemsInFolder $SSHFolderPath) -Eq 0
    $FolderHasOnlyEmptyFiles = Test-FolderHasOnlyEmptyFiles $SSHFolderPath
    If ($FolderIsEmpty -Or $FolderHasOnlyEmptyFiles) {
        Remove-Item -Path $SSHFolderPath -Recurse

        If (Test-Path $SSHFolderPath -PathType "Container") {
            Write-Host " Error." @Red
            Write-Host "The folder has not been deleted." @Warning
        }
        Else {
            Write-Host " Done." @Green
        }
    }
    Else {
        Write-Host " Skip." @Green
        Write-Host "The folder is not empty." @Warning
    }
}
Else {
    Write-Host " Skip." @Green
    Write-Host "The folder was not found." @Warning
}

Write-Host "Deleting the forwarded ports..." -NoNewline
$Ports = Get-ForwardedPorts $VMAddress
If ($Ports.Length -Gt 0) {
    Write-Host " [$($Ports -Join ', ')]" -NoNewline
    Foreach ($Port in $Ports) {
        Remove-PortForwardingRule $Port
    }
    Write-Host " Done." @Green
}
Else {
    Write-Host " Skip." @Green
    Write-Host "The ports were not found." @Warning
}
