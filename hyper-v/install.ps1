$ErrorActionPreference = "Stop"

$BaseDirectory = $HOME # You can change the base directory if you want to.

Function Test-FileNotExists($Path) {
    Return !(Test-Path $Path -PathType "Leaf")
}

Function Test-FolderNotExists($Path) {
    Return !(Test-Path $Path -PathType "Container")
}

Function Test-PathNotValid($Path) {
    Return (($Path -IsNot [String]) -Or !(Test-Path $Path -IsValid))
}

Function Test-PSRunsNotAsAdmin {
    $CurrentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = New-Object Security.Principal.WindowsPrincipal($CurrentUser)
    $AdminRole = [Security.Principal.WindowsBuiltInRole]::Administrator
    Return !($Principal.IsInRole($AdminRole))
}

$Warning = @{ ForegroundColor = "Yellow"; Background = "Black" }

If (Test-PSRunsNotAsAdmin) {
    Write-Host "You need to run PowerShell as administrator." @Warning
    Return
}

If (Test-PathNotValid $BaseDirectory) {
    Write-Host "The value '$BaseDirectory' is not a valid path." @Warning
    Return
}

If (Test-FolderNotExists $BaseDirectory) {
    New-Item -ItemType "Directory" -Path $BaseDirectory | Out-Null
}

$RepositoryUrl = "https://github.com/mrguseinov/machine/archive/main.zip"
If ($RepositoryUrl -NotMatch "^https://github\.com(?:/[^./]+){4}\.zip$") {
    Write-Host "Something is wrong with the repository URL." @Warning
    Return
}
$RepositoryName = $RepositoryUrl.Split("/")[-3]
$BranchName = $RepositoryUrl.Split("/")[-1].Split(".")[0]

$ArchivePath = "$BaseDirectory\$BranchName.zip"
Try {
    (New-Object System.Net.WebClient).DownloadFile($RepositoryUrl, $ArchivePath)
}
Catch {
    Write-Host "Something went wrong while downloading the archive:" @Warning
    Write-Host "-" $_.Exception.Message @Warning
    Return
}

$UnzippedFolder = "$BaseDirectory\$RepositoryName-$BranchName"
If (Test-Path $UnzippedFolder) {
    Remove-Item -Path $UnzippedFolder -Recurse
}
Try {
    Expand-Archive -Path $ArchivePath -DestinationPath $BaseDirectory
}
Catch {
    Remove-Item -Path $ArchivePath
    Write-Host "Something went wrong while unzipping the archive:" @Warning
    Write-Host "-" $_.Exception.Message @Warning
    Return
}

$ScriptPath = "$UnzippedFolder\hyper-v\create.ps1"
If (Test-FileNotExists $ScriptPath) {
    Write-Host "The '$ScriptPath' script was not found." @Warning
}
Else {
    Set-ExecutionPolicy Bypass -Scope Process -Force
    & $ScriptPath
}

Remove-Item -Path $ArchivePath
Remove-Item -Path $UnzippedFolder -Recurse
