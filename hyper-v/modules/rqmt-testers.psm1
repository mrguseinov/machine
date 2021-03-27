$ErrorActionPreference = "Stop"

Import-Module "$PSScriptRoot\common-utils.psm1"
Import-Module "$PSScriptRoot\network-utils.psm1"
Import-Module "$PSScriptRoot\value-testers.psm1"

Function Test-HardwareNotCompatible {
    $HyperVInfo = Get-ComputerInfo -Property "*Hyper*"

    # If Hyper-V is already enabled, the hardware is compatible.
    If ($HyperVInfo.HyperVisorPresent) {
        Return $False
    }

    $HyperVRequirements = (
        "HyperVRequirementDataExecutionPreventionAvailable",
        "HyperVRequirementSecondLevelAddressTranslation",
        "HyperVRequirementVirtualizationFirmwareEnabled",
        "HyperVRequirementVMMonitorModeExtensions"
    )
    ForEach ($Requirement In $HyperVRequirements) {
        If (!($HyperVInfo.$Requirement)) {
            Return $True
        }
    }

    Return $False
}

Function Test-HyperVNotEnabled {
    $HyperV = Get-WindowsOptionalFeature -FeatureName "Microsoft-Hyper-V-All" -Online
    Return ($HyperV.State -Ne "Enabled")
}

Function Test-NamesAvailable($TakenNames, $NamesToTest) {
    Test-ValueIsArray $TakenNames
    Test-ValueIsArray $NamesToTest
    @($TakenNames + $NamesToTest) | ForEach-Object { Test-ValueIsString $_ }

    Return ($TakenNames.Where( { $NamesToTest -Contains $_ } ).Count -Eq 0)
}

Function Test-OsNotSupported {
    $SupportedEditions = ("Education", "Enterprise", "Professional")
    $CurrentEdition = (Get-WindowsEdition -Online).Edition
    $EditionSupported = $SupportedEditions.Contains($CurrentEdition)
    $Windows64Bit = [Environment]::Is64BitOperatingSystem
    Return !($EditionSupported -And $Windows64Bit)
}

Function Test-PathAvailable($Path) {
    Test-ValueIsPath $Path
    Return !(Test-Path $Path)
}

Function Test-PSRunsNotAsAdmin {
    $CurrentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = New-Object Security.Principal.WindowsPrincipal($CurrentUser)
    $AdminRole = [Security.Principal.WindowsBuiltInRole]::Administrator
    Return !($Principal.IsInRole($AdminRole))
}

Function Test-RamNotEnough {
    Return ((Get-TotalRamInstalled) -Lt 4GB)
}

Function Test-StorageNotEnough($DriveLetter) {
    Test-ValueIsDriveLetter $DriveLetter
    Return ((Get-AvailableStorage $DriveLetter) -Lt 15GB)
}

Function Test-SubnetAvailable($NetworkID) {
    Test-ValueIsIPv4 $NetworkID

    $HostAddresses = Get-NetIPAddress -AddressFamily "IPv4"
    ForEach ($Address In $HostAddresses) {
        $AddressSubnet = Get-Subnet $Address.IPAddress $Address.PrefixLength
        $IPRange = Get-IPRangeInSubnet $AddressSubnet $Address.PrefixLength

        If (Test-IPAddressInRange $NetworkID $IPRange.From $IPRange.To) {
            Return $False
        }
    }

    Return $True
}
