Using Namespace System.Net

$ErrorActionPreference = "Stop"

Import-Module "$PSScriptRoot\value-testers.psm1" -Force

Function Add-IntToIPAddress($IPAddress, $Number) {
    Test-ValueIsIPv4 $IPAddress
    Test-ValueIsInteger $Number

    $IPAddress = [IPAddress](Get-IPOctetsReversed $IPAddress)
    $IPAddress.Address += $Number
    Return Get-IPOctetsReversed $IPAddress.ToString()
}

Function Convert-CidrToMask($PrefixLength) {
    Test-ValueIsCidr $PrefixLength
    $IPAddress = [IPAddress]([UInt32]::MaxValue -shl (32 - $PrefixLength))
    Return Get-IPOctetsReversed $IPAddress.ToString()
}

Function Get-IPOctetsReversed($IPAddress) {
    Test-ValueIsIPv4 $IPAddress
    Return $IPAddress.Split(".")[4..0] -Join "."
}

Function Get-IPRangeInSubnet($IPAddress, $PrefixLength) {
    Test-ValueIsIPv4 $IPAddress
    Test-ValueIsCidr $PrefixLength

    $NetworkID = Get-Subnet $IPAddress $PrefixLength
    $NumberOfHosts = Get-NumberOfAddresses $PrefixLength
    $Broadcast = Add-IntToIPAddress $NetworkID ($NumberOfHosts - 1)
    Return @{ From = $NetworkID; To = $Broadcast }
}

Function Get-NumberOfAddresses($PrefixLength) {
    Test-ValueIsCidr $PrefixLength
    Return [Int]([System.Math]::Pow(2, (32 - $PrefixLength)))
}

Function Get-Subnet($IPAddress, $PrefixLength) {
    Test-ValueIsIPv4 $IPAddress
    Test-ValueIsCidr $PrefixLength

    $IPAddress = ([IPAddress]$IPAddress).Address
    $Mask = ([IPAddress](Convert-CidrToMask $PrefixLength)).Address
    Return ([IPAddress]($IPAddress -BAnd $Mask)).ToString()
}

Function Test-IPAddressInRange($IPAddress, $IPFrom, $IPTo) {
    @($IPAddress, $IPFrom, $IPTo) | ForEach-Object { Test-ValueIsIPv4 $_ }

    $IPAddress = ([IPAddress](Get-IPOctetsReversed $IPAddress)).Address
    $IPFrom = ([IPAddress](Get-IPOctetsReversed $IPFrom)).Address
    $IPTo = ([IPAddress](Get-IPOctetsReversed $IPTo)).Address

    Return ($IPFrom -Le $IPAddress) -And ($IPAddress -Le $IPTo)
}
