$ErrorActionPreference = "Stop"

Import-Module "$PSScriptRoot\modules\common-utils.psm1" -Force
Import-Module "$PSScriptRoot\modules\network-utils.psm1" -Force
Import-Module "$PSScriptRoot\modules\rqmt-testers.psm1" -Force

$BaseDirectory = $HOME

Set-ColorVariables # $Red, $Green, $Warning

Write-Host "Is PowerShell running as administrator?" -NoNewline
If (Test-PSRunsNotAsAdmin) {
    Write-Host " No." @Red
    Write-Host "You need to run PowerShell as administrator." @Warning
    Return
}
Write-Host " Yes." @Green

Write-Host "Is Hyper-V available for your operating system?" -NoNewline
If (Test-OsNotSupported) {
    Write-Host " No." @Red
    Write-Host "You need 64-bit Windows 10 Pro, Enterprise, or Education." @Warning
    Return
}
Write-Host " Yes." @Green

Write-Host "Is the hardware compatible (DEP, SLAT, V12N, VT-x/AMD-V)?" -NoNewline
If (Test-HardwareNotCompatible) {
    Write-Host " No." @Red
    Write-Host "For more information, visit https://bit.ly/38YlXL4." @Warning
    Return
}
Write-Host " Yes." @Green

Write-Host "Is there at least 4 GB of installed RAM?" -NoNewline
If (Test-RamNotEnough) {
    Write-Host " No." @Red
    Write-Host "Before proceeding, you need to install more RAM." @Warning
    Return
}
Write-Host " Yes." @Green

Write-Host "Is Hyper-V already enabled on your system?" -NoNewline
If (Test-HyperVNotEnabled) {
    Write-Host " No." @Red

    $Decision = Read-Host "Do you want to enable Hyper-V (restart required)? [y/N]"
    If (Test-DecisionPositive $Decision) {
        Enable-HyperV
    }
    Else {
        Write-Host "Before proceeding, you need to enable Hyper-V." @Warning
    }

    Return
}
Write-Host " Yes." @Green

$DriveLetter = $BaseDirectory[0]
Write-Host "Is there at least 15 GB of free storage ($DriveLetter drive)?" -NoNewline
If (Test-StorageNotEnough $DriveLetter) {
    Write-Host " No." @Red
    Write-Host "Before proceeding, you need to free up some memory." @Warning
    Return
}
Write-Host " Yes." @Green

Write-Host
$Title = "`rGenerating names for folder, VM, vSwitch, and NAT..."
Write-Host $Title -NoNewline
$TakenNames = Get-TakenNames
$TrialNumber = 1
$TotalTrials = 100
While ($True) {
    Write-Host "$Title $TrialNumber/$TotalTrials" -NoNewline

    If ($TrialNumber -Eq $TotalTrials) {
        Write-Host $Title -NoNewline
        Write-Host " Failed." @Red
        Write-Host "We've tried many random names. All of them were taken." @Warning
        Return
    }

    $RandomLetters = Get-RandomLetters -Count 5
    $VmName = "Ubuntu-$RandomLetters"
    $VmPath = "$BaseDirectory\$VmName"
    $SwitchName = "Switch-$RandomLetters"
    $NatName = "NAT-$RandomLetters"

    $NamesToTest = @($VmName, $SwitchName, $NatName)
    $NamesAvailable = Test-NamesAvailable $TakenNames $NamesToTest
    $FolderAvailable = Test-PathAvailable $VmPath
    If ($NamesAvailable -And $FolderAvailable) {
        Write-Host $Title -NoNewline
        Write-Host " Done." @Green
        Break
    }

    $TrialNumber++
}

Write-Host "Looking for an available subnet..." -NoNewline
$Trials = 0
While ($True) {
    $Trials++
    If ($Trials -Gt 100) {
        Write-Host " Failed." @Red
        Write-Host "We've tried many random subnets. All of them were taken." @Warning
        Return
    }

    $RandomByte = Get-RandomInteger -Start 0 -End 255
    $Subnet = @{ ID = "192.168.$RandomByte.0"; PrefixLength = 24 }
    If (Test-SubnetAvailable $Subnet.ID) {
        Write-Host " Done." @Green
        Break
    }
}

Write-Host
$Decision = Read-Host "The virtual machine is ready to be created. Continue? [Y/n]"
If (Test-DecisionNegative $Decision) {
    Write-Host
    Write-Host "Up until now nothing has been changed or created on your computer."
    Write-Host "Run the script again when you're ready to start over. Bye!"
    Return
}
Write-Host

Write-Host "Creating '$VmPath' folder for VM..." -NoNewline
New-Item -ItemType "Directory" -Path $VmPath | Out-Null
Set-Location $VmPath
Write-Host " Done." @Green

Write-Host "Downloading installation media (iso file)..." -NoNewline
$IsoUrl = "https://releases.ubuntu.com/22.04.2/ubuntu-22.04.2-live-server-amd64.iso"
$IsoFileName = $IsoUrl.Split("/")[-1]
$BitsTransferParams = @{
    Source      = $IsoUrl
    Destination = $IsoFileName
    Description = "File: '$VmPath\$IsoFileName'"
    DisplayName = "Downloading installation media..."
}
Start-BitsTransfer @BitsTransferParams
Write-Host " Done." @Green

Write-Host "Checking '$IsoFileName' hash..." -NoNewline
$ActualHash = (Get-FileHash $IsoFileName -Algorithm "SHA256").Hash
$ExpectedHash = "5e38b55d57d94ff029719342357325ed3bda38fa80054f9330dc789cd2d43931"
If ($ActualHash -Ne $ExpectedHash) {
    Write-Host
    Write-Host "Something went wrong. Hashes do not match!" @Warning
    Write-Host "Try to run the script again later."
    Return
}
Write-Host " Done." @Green

Write-Host "Creating an internal virtual switch..." -NoNewline
$NewSwitchParams = @{
    Name       = $SwitchName
    SwitchType = "Internal"
}
New-VMSwitch @NewSwitchParams | Out-Null
Write-Host " Done." @Green

Write-Host "Setting an IP address for the vNIC..." -NoNewline
$VNicAddress = Add-IntToIPAddress -IPAddress $Subnet.ID -Number 1
$NewIPParams = @{
    IPAddress      = $VNicAddress
    InterfaceAlias = "vEthernet ($SwitchName)"
    PrefixLength   = $Subnet.PrefixLength
}
New-NetIPAddress @NewIPParams | Out-Null
Write-Host " Done." @Green

Write-Host "Configuring network address translation (NAT)..." -NoNewline
$SubnetInCidrFormat = $Subnet.ID + "/" + $Subnet.PrefixLength
$NewNatParams = @{
    Name                             = $NatName
    InternalIPInterfaceAddressPrefix = $SubnetInCidrFormat
}
New-NetNat @NewNatParams | Out-Null
Write-Host " Done." @Green

Write-Host
Write-Host "     Write Down The Following Info     " @Warning
$NumberOfDashes = 39
Write-Host $("-" * $NumberOfDashes) @Warning
$VMAddress = Add-IntToIPAddress -IPAddress $VNicAddress -Number 1
$NetworkInfo = [Ordered]@{
    "Subnet"         = $SubnetInCidrFormat
    "Address"        = $VMAddress
    "Gateway"        = $VNicAddress
    "Name servers"   = "1.1.1.1, 8.8.8.8"
    "Search domains" = "(leave empty)"
}
$NetworkInfo.Keys | ForEach-Object { "{0, 15} ..... {1}" -F ($_, $NetworkInfo.$_) }
Write-Host $("-" * $NumberOfDashes) @Warning
Write-Host

Write-Host "Creating a virtual machine..." -NoNewline
$NewVMParams = @{
    Name               = $VmName
    MemoryStartupBytes = 2GB
    SwitchName         = $SwitchName
    NewVHDPath         = "$VmPath\$VmName.vhdx"
    NewVHDSizeBytes    = 30GB
    Path               = $BaseDirectory
    Generation         = 2
}
New-VM @NewVMParams | Out-Null
Write-Host " Done." @Green

Write-Host "Configuring the virtual machine..." -NoNewline
$SetVMParams = @{
    Name                 = $VmName
    ProcessorCount       = Get-NumberOfLogicalProcessors
    DynamicMemory        = $True
    MemoryMinimumBytes   = 0.5GB
    MemoryMaximumBytes   = Select-MaxRamAmount
    AutomaticStartAction = "StartIfRunning"
    AutomaticStopAction  = "Save"
    AutomaticStartDelay  = 0
}
Set-VM @SetVMParams
Write-Host " Done." @Green

Write-Host "Adding a virtual DVD drive using the iso file..." -NoNewline
Add-VMDvdDrive -VMName $VmName -Path "$VmPath\$IsoFileName"
Write-Host " Done." @Green

Write-Host "Setting the VM to boot off of the DVD drive..." -NoNewline
$VMDvdDrive = Get-VMDvdDrive -VMName $VmName
$FirmwareParams = @{
    VMName           = $VmName
    FirstBootDevice  = $VMDvdDrive
    EnableSecureBoot = "Off"
}
Set-VMFirmware @FirmwareParams
Write-Host " Done." @Green

$ScriptsPath = "$VmPath\Scripts"
Write-Host "Copying the scripts to '$ScriptsPath'..." -NoNewline
New-Item -ItemType "Directory" -Path $ScriptsPath | Out-Null
Copy-Item -Path "$PSScriptRoot\ports.ps1" -Destination $ScriptsPath
Copy-Item -Path "$PSScriptRoot\provision.ps1" -Destination $ScriptsPath
Copy-Item -Path "$PSScriptRoot\ssh.ps1" -Destination $ScriptsPath
Copy-Item -Path "$PSScriptRoot\uninstall.ps1" -Destination $ScriptsPath
$ModulesPath = "$VmPath\Scripts\modules"
New-Item -ItemType "Directory" -Path $ModulesPath | Out-Null
Copy-Item -Path "$PSScriptRoot\modules\common-utils.psm1" -Destination $ModulesPath
Copy-Item -Path "$PSScriptRoot\modules\network-utils.psm1" -Destination $ModulesPath
Copy-Item -Path "$PSScriptRoot\modules\value-testers.psm1" -Destination $ModulesPath
Write-Host " Done." @Green

Write-Host "Saving some data to 'Scripts\variables.csv'..." -NoNewline
$DataToExport = @{
    VmName     = $VmName
    VmPath     = $VmPath
    SwitchName = $SwitchName
    NatName    = $NatName
    VMAddress  = $VMAddress
}
Export-VariablesToCsv -Variables $DataToExport -Path "$ScriptsPath\variables.csv"
Write-Host " Done." @Green

Write-Host
$Decision = Read-Host "The virtual machine is ready to be started. Continue? [Y/n]"
If (Test-DecisionNegative $Decision) {
    Write-Host
    Write-Host "Your virtual machine is available in the Hyper-V Manager."
    Write-Host "Thank you for choosing my script. Bye!"
    Return
}
Write-Host

Write-Host "Starting and connecting to the virtual machine..." -NoNewline
Start-VM -Name $VmName
$HostName = [System.Net.Dns]::GetHostName()
VMConnect $HostName $VmName
Write-Host " Done." @Green

Write-Host
Write-Host "Your virtual machine is also available in the Hyper-V Manager."
Write-Host "Thank you for choosing my script. Bye!"
