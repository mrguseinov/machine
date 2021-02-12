$ErrorActionPreference = "Stop"

Import-Module "$PSScriptRoot\value-testers.psm1"

Function Add-HostToSSHConfig($ConfigFilePath, $HostParams) {
    Test-ValueIsPath $ConfigFilePath
    Test-HashtableHasKeys $HostParams ("Host", "HostName", "User", "IdentityFile")

    $Configuration = @"
Host $($HostParams.Host)
    HostName $($HostParams.HostName)
    User $($HostParams.User)
    IdentityFile $($HostParams.IdentityFile)
"@

    $ConfigFileContent = Get-Content $ConfigFilePath -ErrorAction "SilentlyContinue"
    If ($ConfigFileContent.Length -Eq 0) {
        Add-Content -Path $ConfigFilePath -Value $Configuration
    }
    Else {
        Add-Content -Path $ConfigFilePath -Value ("`n" + $Configuration)
    }
}

Function Enable-HyperV {
    $Name = "Microsoft-Hyper-V"
    Enable-WindowsOptionalFeature -Online -FeatureName $Name -All | Out-Null
}

Function Export-VariablesToCsv($Variables, $Path) {
    Test-ValueIsHashtable $Variables
    Test-ValueIsPath $Path

    $PreparedData = $Variables.GetEnumerator() | Select-Object Name, Value
    $PreparedData | Export-Csv $Path -NoTypeInformation
}

Function Get-AvailableStorage($DriveLetter) {
    Test-ValueIsDriveLetter $DriveLetter

    $WmiObjectParams = @{
        Class  = "Win32_LogicalDisk"
        Filter = "DeviceID = '$DriveLetter`:'"
    }
    Return (Get-WmiObject @WmiObjectParams).FreeSpace
}

Function Get-NumberOfItemsInFolder($Path) {
    Test-FolderExists $Path
    Return (Get-ChildItem $Path -Recurse | Measure-Object).Count
}

Function Get-NumberOfLogicalProcessors {
    Return (Get-CimInstance "Win32_ComputerSystem").NumberOfLogicalProcessors
}

Function Get-RandomInteger($Start, $End) {
    @($Start, $End) | ForEach-Object { Test-ValueIsInteger $_ }
    Return $Start..$End | Get-Random
}

Function Get-RandomLetters($Count) {
    Test-ValueIsInteger $Count

    $RandomAsciiCodes = 65..90 * $Count | Get-Random -Count $Count
    Return -Join ($RandomAsciiCodes | ForEach-Object { [Char]$_ } )
}

Function Get-TotalRamInstalled {
    $PhysicalMemory = Get-CimInstance "Cim_PhysicalMemory"
    Return ($PhysicalMemory | Measure-Object -Property "Capacity" -Sum).Sum
}

Function Import-VariablesFromCsv($Path) {
    Test-FileExists $Path
    Import-Csv $Path | ForEach-Object {
        Set-Variable $_.Name $_.Value -Scope "Global"
    }
}

Function New-SSHKeys($Algorithm, $KeyFilesPath) {
    Test-ValueIsSSHAlgorithm $Algorithm
    Test-ValueIsPath $KeyFilesPath

    ssh-keygen -q -t $Algorithm -f $KeyFilesPath -N """"

    Return ("$KeyFilesPath.pub", $KeyFilesPath)
}

Function Remove-HostFromKnownHosts($HostName, $KnownHostsFilePath) {
    Test-ValueIsString $HostName
    Test-FileExists $KnownHostsFilePath

    $KnownHostsContent = Get-Content $KnownHostsFilePath
    $FilteredHosts = $KnownHostsContent.Where( { $_ -NotLike "*$HostName*" } )
    Set-Content -Path $KnownHostsFilePath -Value $FilteredHosts
}

Function Remove-HostFromSHHConfig($HostName, $ConfigFilePath) {
    Test-ValueIsString $HostName
    Test-FileExists $ConfigFilePath

    $ConfigFileContent = [System.Collections.ArrayList](Get-Content $ConfigFilePath)

    For ($Index = 0; $Index -Lt $ConfigFileContent.Count; $Index++) {
        If ($ConfigFileContent[$Index] -Like "*HostName $HostName*") {
            While ($ConfigFileContent[$Index] -NotLike "*Host *" -And $Index -Ne 0) {
                $Index--
            }
            $ConfigFileContent.RemoveAt($Index) # Shifts subsequent elements by -1.
            While ($ConfigFileContent[$Index] -NotLike "*Host *") {
                If ($Index -Eq $ConfigFileContent.Count) {
                    If ($ConfigFileContent[-1] -Eq "") {
                        $ConfigFileContent.RemoveAt($ConfigFileContent.Count - 1)
                    }
                    Break
                }
                $ConfigFileContent.RemoveAt($Index)
            }
            Break
        }
    }

    Set-Content -Path $ConfigFilePath -Value $ConfigFileContent
}

Function Restart-ScriptAsAdminNoExitOnce($ScriptPath) {
    Test-FileExists $ScriptPath

    $LockFilePath = "$ScriptPath.lock"
    If (!(Test-Path $LockFilePath)) {
        New-Item -Path $LockFilePath | Out-Null

        $CommandsToRun = "Set-ExecutionPolicy Bypass -Scope Process -Force;"
        $CommandsToRun += "& $ScriptPath"
        $PowerShellParams = @{
            Verb         = "RunAs"
            ArgumentList = "-NoExit -Command $CommandsToRun"
        }
        Start-Process PowerShell @PowerShellParams

        Exit
    }
    Remove-Item -Path $LockFilePath
}

Function Select-MaxRamAmount {
    Return [System.Math]::Min((Get-TotalRamInstalled) / 2, 8GB)
}

Function Send-CommandOverSSH($User, $HostName, $Command) {
    @($User, $HostName, $Command) | ForEach-Object { Test-ValueIsString $_ }
    Return ssh "$User@$HostName" $Command
}

Function Send-CommandOverSSHWithPTY($User, $HostName, $Command) {
    @($User, $HostName, $Command) | ForEach-Object { Test-ValueIsString $_ }
    ssh -t "$User@$HostName" $Command
}

Function Set-ColorVariables {
    $Colors = @{
        Red     = @{ ForegroundColor = "Red" }
        Green   = @{ ForegroundColor = "Green" }
        Warning = @{ ForegroundColor = "Yellow"; Background = "Black" }
    }
    $Colors.GetEnumerator() | ForEach-Object {
        Set-Variable $_.Name $_.Value -Scope "Global"
    }
}

Function Set-ParentLocationOrHome($Path) {
    Test-ValueIsPath $Path

    $ParentPath = Split-Path -Path $Path -Parent
    If ([String]::IsNullOrEmpty($ParentPath)) {
        Set-Location $HOME
    }
    Else {
        Set-Location $ParentPath
    }
}

Function Show-Console() {
    $Signature = @"
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
"@

    $TypeParams = @{
        Name             = "Methods"
        MemberDefinition = $Signature
        Namespace        = "Win32"
        PassThru         = $True
    }
    Add-Type @TypeParams | Out-Null

    $hWnd = (Get-Process -Id $PID).MainWindowHandle
    If ($hWnd -Ne [Win32.Methods]::GetForegroundWindow()) {
        [Win32.Methods]::ShowWindow($hWnd, 2) | Out-Null # 2 = SW_SHOWMINIMIZED
        [Win32.Methods]::ShowWindow($hWnd, 9) | Out-Null # 9 = SW_RESTORE
    }
}

Function Test-DecisionNegative($Decision) {
    Test-ValueIsString $Decision
    Return ("n", "no", "nah", "nope").Contains($Decision.ToLower())
}

Function Test-DecisionNotPositive($Decision) {
    Test-ValueIsString $Decision
    Return !(Test-DecisionPositive $Decision)
}

Function Test-DecisionPositive($Decision) {
    Test-ValueIsString $Decision
    Return ("y", "yes", "yeah", "yep").Contains($Decision.ToLower())
}

Function Test-FileExists($Path) {
    Test-ValueIsPath $Path
    If (!(Test-Path $Path -PathType "Leaf")) {
        Throw "The file '$Path' was not found."
    }
}

Function Test-FolderExists($Path) {
    Test-ValueIsPath $Path
    If (!(Test-Path $Path -PathType "Container")) {
        Throw "The folder '$Path' was not found."
    }
}

Function Test-FolderHasOnlyEmptyFiles($Path) {
    $AllFiles = Get-ChildItem $Path -Recurse -File
    Return $AllFiles.Where( { $_.Length -Ne 0 } ).Count -Eq 0
}

Function Test-HostNotPinging($HostNameOrAddress) {
    $Ping = New-Object System.Net.NetworkInformation.Ping
    Return ($Ping.Send($HostNameOrAddress).Status -Ne "Success")
}

Function Test-PathsEqual($FirstPath, $SecondPath) {
    Return (Join-Path $FirstPath "") -Eq (Join-Path $SecondPath "")
}

Function Test-StringInFile($String, $Path) {
    Test-ValueIsString $String
    Test-FileExists $Path
    Return Select-String $String -Path $Path -Quiet
}

Function Test-VariablesNotImported {
    $Variables = @($VMAddress, $SwitchName, $VmName, $NatName, $VmPath)
    Return $Variables.Where( { $Null -Eq $_ } ).Count -Ne 0
}
