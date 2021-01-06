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

Write-Host
Write-Host "You are about to delete '$VmName' machine and all its related data." @Red
$Decision = Read-Host "Continue? Delete the machine and its data? [y/N]"
If (Test-DecisionNotPositive $Decision) {
    Return
}
Write-Host

Write-Host "Finding the virtual machine '$VmName'..." -NoNewline
Try {
    $Machine = Get-VM $VmName
    Write-Host " Done." @Green
}
Catch {
    Write-Host " Error." @Red
    Write-Host $_.Exception.Message @Warning
}

If ($Null -Ne $Machine) {
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
    Write-Host
}

Write-Host "Deleting the '$SwitchName' vSwitch..." -NoNewline
Try {
    Remove-VMSwitch -Name $SwitchName -Force
    Write-Host " Done." @Green
}
Catch {
    Write-Host " Error." @Red
    Write-Host $_.Exception.Message @Warning
}

Write-Host "Deleting the '$NatName' NAT..." -NoNewline
Try {
    Remove-NetNat -Name $NatName -Confirm:$False -ErrorAction "Stop"
    Write-Host " Done." @Green
}
Catch {
    Write-Host " Error." @Red
    Write-Host $_.Exception.Message @Warning
}

Write-Host "Deleting the '$VmPath' folder..." -NoNewline
Set-ParentLocationOrHome $VmPath
Try {
    Remove-Item -Path $VmPath -Recurse
    Write-Host " Done." @Green
}
Catch {
    Write-Host " Error." @Red
    Write-Host $_.Exception.Message @Warning
}

$ConfigFolderPath = "$HOME\.ssh"
Write-Host "Deleting the key(s) from '$ConfigFolderPath'..." -NoNewline
$KeyFilesPath = "$ConfigFolderPath\$VmName"
Try {
    $ItemsCountBefore = Get-NumberOfItemsInFolder $ConfigFolderPath
    Remove-Item -Path "$KeyFilesPath*"
    $ItemsCountAfter = Get-NumberOfItemsInFolder $ConfigFolderPath
    If ($ItemsCountBefore -Eq $ItemsCountAfter) {
        Throw "No files (keys) have been deleted."
    }
    Write-Host " Done." @Green
}
Catch {
    Write-Host " Error." @Red
    Write-Host $_.Exception.Message @Warning
}

$ConfigFilePath = "$ConfigFolderPath\config"
Write-Host "Deleting the config from '$ConfigFilePath'..." -NoNewline
Try {
    $LinesCountBefore = (Get-Content $ConfigFilePath).Length
    Remove-HostFromSHHConfig $ConfigFilePath $VMAddress
    $LinesCountAfter = (Get-Content $ConfigFilePath).Length
    If ($LinesCountBefore -Eq $LinesCountAfter) {
        Throw "No configuration has been deleted."
    }
    Write-Host " Done." @Green
}
Catch {
    Write-Host " Error." @Red
    Write-Host $_.Exception.Message @Warning
}
