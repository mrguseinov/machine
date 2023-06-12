Using Namespace System.Net

$ErrorActionPreference = "Stop"

Import-Module "$PSScriptRoot\value-testers.psm1" -Force

Function Add-PortsFirewallRule($Name, $Ports) {
    Test-ValueIsString $Name
    Test-ValueIsArray $Ports
    ForEach ($Port in $Ports) {
        Test-ValueIsNetworkPort $Port
    }
    $Parameters = "-DisplayName '$Name' " +
                  "-LocalPort $($Ports -Join ', ') " +
                  "-Action Allow " +
                  "-Protocol TCP"
    Invoke-Expression "New-NetFireWallRule $Parameters -Direction Inbound" | Out-Null
}

Function Add-PortForwardingRule($IPAddress, $Port) {
    Test-ValueIsIPv4 $IPAddress
    Test-ValueIsNetworkPort $Port
    $Parameters = "listenaddress=0.0.0.0 " +
                  "listenport=$Port " +
                  "connectaddress=$IPAddress " +
                  "connectport=$Port"
    Invoke-Expression "netsh interface portproxy add v4tov4 $Parameters" | Out-Null
}

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

Function Get-ForwardedPorts($IPAddress) {
    # https://stackoverflow.com/q/18476634
    # https://stackoverflow.com/q/70863810
    Test-ValueIsIPv4 $IPAddress
    $FilteredRules = netsh interface portproxy show all | Select-String $IPAddress
    Return , @($FilteredRules | ForEach-Object { [Int](($_ -Split "\s+")[3]) })
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

Function Remove-FirewallRule($Name) {
    Test-ValueIsString $Name
    Remove-NetFireWallRule -DisplayName $Name -ErrorAction "SilentlyContinue"
}

Function Remove-PortForwardingRule($Port) {
    Test-ValueIsNetworkPort $Port
    $Parameters = "listenaddress=0.0.0.0 " +
                  "listenport=$Port"
    Invoke-Expression "netsh interface portproxy delete v4tov4 $Parameters" | Out-Null
}

Function Test-IPAddressInRange($IPAddress, $IPFrom, $IPTo) {
    @($IPAddress, $IPFrom, $IPTo) | ForEach-Object { Test-ValueIsIPv4 $_ }

    $IPAddress = ([IPAddress](Get-IPOctetsReversed $IPAddress)).Address
    $IPFrom = ([IPAddress](Get-IPOctetsReversed $IPFrom)).Address
    $IPTo = ([IPAddress](Get-IPOctetsReversed $IPTo)).Address

    Return ($IPFrom -Le $IPAddress) -And ($IPAddress -Le $IPTo)
}

Function Test-FirewallRuleExists($Name) {
    Test-ValueIsString $Name
    $Rule = Get-NetFirewallRule -DisplayName $Name -ErrorAction "SilentlyContinue"
    Return $Rule -Ne $Null
}
