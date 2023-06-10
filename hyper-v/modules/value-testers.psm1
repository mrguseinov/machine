$ErrorActionPreference = "Stop"

Function Test-HashtableHasKeys($Hashtable, $Keys) {
    Test-ValueIsHashtable $Hashtable
    Test-ValueIsArray $Keys

    $Keys | ForEach-Object {
        If (!($Hashtable.ContainsKey($_))) {
            Throw "The hashtable does not contain the key '$_'."
        }
    }
}

Function Test-ValueIsArray($Value) {
    If ($Value -IsNot [Array]) {
        $TypeName = $Value.GetType().Name
        Throw "The type of '$Value' is not an Array. It's of type '$TypeName'."
    }
}

Function Test-ValueIsCidr($PrefixLength) {
    If (($PrefixLength -As [Byte]) -Ne $PrefixLength) {
        $TypeName = $PrefixLength.GetType().Name
        Throw "The type of '$PrefixLength' ($TypeName) is wrong for a prefix length."
    }

    If (($PrefixLength -Lt 1) -Or ($PrefixLength -Gt 32)) {
        Throw "The prefix length '$PrefixLength' is not in the range [1, 32]."
    }
}

Function Test-ValueIsDriveLetter($Value) {
    If ($Value -CNotMatch "^[A-Z]$") {
        Throw "The drive letter '$Value' is not in the range [A-Z]."
    }
}

Function Test-ValueIsHashtable($Value) {
    If ($Value -IsNot [Hashtable]) {
        $TypeName = $Value.GetType().Name
        Throw "The type of '$Value' is not a Hashtable. It's of type '$TypeName'."
    }
}

Function Test-ValueIsInteger($Value) {
    If ($Value -IsNot [Int]) {
        $TypeName = $Value.GetType().Name
        Throw "The type of '$Value' is not an Integer. It's of type '$TypeName'."
    }
}

Function Test-ValueIsIPv4($IPAddress) {
    Test-ValueIsString $IPAddress

    $Byte = "(?:[0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])" # 0 to 255
    $IPv4Regex = "^$Byte\.$Byte\.$Byte\.$Byte$"
    If ($IPAddress -NotMatch $IPv4Regex) {
        Throw "The value '$IPAddress' is not a valid IPv4."
    }
}

Function Test-ValueIsPath($Path) {
    Test-ValueIsString $Path
    If (!(Test-Path $Path -IsValid)) {
        Throw "The value '$Path' is not a valid path."
    }
}

Function Test-ValueIsNetworkPort($Port) {
    Test-ValueIsInteger $Port
    If ($Port -Lt 0 -Or $Port -Gt 65535) {
        Throw "The value '$Port' is not a valid port."
    }
}

Function Test-ValueIsSSHAlgorithm($Algorithm) {
    Test-ValueIsString $Algorithm
    If (!("dsa", "ecdsa", "ed25519", "rsa").Contains($Algorithm.ToLower())) {
        Throw "The value '$Algorithm' is not a supported SSH algorithm."
    }
}

Function Test-ValueIsString($Value) {
    If ($Value -IsNot [String]) {
        $TypeName = $Value.GetType().Name
        Throw "The type of '$Value' is not a String. It's of type '$TypeName'."
    }
}
