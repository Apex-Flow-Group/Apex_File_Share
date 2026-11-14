<#
.SYNOPSIS
Uploads the new Apex File Share Windows installer to the company server as the app "transfer" of the
Aljawal Field releases ("our apps").

.DESCRIPTION
Windows only. Android is released on Google Play, not here: this script has no APK path.

The upload itself is done by the Aljawal Field transport, never copied here:
  <FieldRepo>\scripts\app_release_upload\upload.ps1 -App transfer -Kind exe -File ... -Version ... -Build ...
That script holds the server rules (version format, build newer than the last upload, the auction freeze)
and its own access; this script reads no token, key or password.

Before anything is sent the installer is checked and the run is refused on any error:
 - version and build come from pubspec.yaml (x.y.z+BUILD);
 - installer\ApexFileShare_Setup_<x.y.z.BUILD>.exe exists and its FileVersion is x.y.z.BUILD.
Build first with build_windows.bat (installer).

The install link is made by the super admin in the app's "our apps" page; the app does not update itself
from the company server.

WRITES production unless -DryRun. Run without -DryRun only on the owner's word for that exact upload.
The first upload needs the server deploy that knows the app "transfer".

.PARAMETER Notes
Release notes sent with the upload (optional).

.PARAMETER AuctionConfirm
The owner's word passed through to upload.ps1 for the post-auction freeze guard (see that script).

.PARAMETER DryRun
No network: runs the local checks and upload.ps1 -DryRun, and prints the exact command.

.PARAMETER FieldRepo
The Aljawal Field checkout (default: ..\Aljawal-Field beside this repository).

.EXAMPLE
powershell -ExecutionPolicy Bypass -File scripts\upload_release.ps1 -DryRun

.EXAMPLE
powershell -ExecutionPolicy Bypass -File scripts\upload_release.ps1 -Notes "chat fixes"
#>
param(
    [string]$Notes = '',
    [string]$FieldRepo = '',
    [string]$AuctionConfirm = '',
    [switch]$DryRun,
    [switch]$Help
)
$ErrorActionPreference = 'Stop'
if ($Help) { Get-Help $PSCommandPath -Full; exit 0 }

$AppId = 'transfer'
$root = Split-Path $PSScriptRoot -Parent
if (-not $FieldRepo) { $FieldRepo = Join-Path (Split-Path $root -Parent) 'Aljawal-Field' }
$uploader = Join-Path $FieldRepo 'scripts\app_release_upload\upload.ps1'
$errors = New-Object System.Collections.Generic.List[string]

# -- version and build from pubspec.yaml
$pubspec = [IO.File]::ReadAllText((Join-Path $root 'pubspec.yaml'))
$m = [regex]::Match($pubspec, '(?m)^version:\s*([0-9]+(?:\.[0-9]+){1,3})\+([0-9]+)\s*$')
if (-not $m.Success) { Write-Host 'REFUSED: pubspec.yaml has no version x.y.z+BUILD'; exit 1 }
$Version = $m.Groups[1].Value
$Build = [int]$m.Groups[2].Value
Write-Host "Apex File Share $Version+$Build  (server app id: $AppId, Windows installer only)"
if (-not (Test-Path -LiteralPath $uploader)) { $errors.Add("upload script not found: $uploader (give -FieldRepo)") }

function Test-Exe([string]$path) {
    $four = "$Version.$Build"
    if (-not (Test-Path -LiteralPath $path)) { return @("installer not found: $path (run build_windows.bat)") }
    $fv = ([string](Get-Item -LiteralPath $path).VersionInfo.FileVersion).Trim()
    Write-Host "  exe FileVersion $fv"
    if ($fv -ne $four) { return @("installer FileVersion $fv is not $four") }
    return @()
}

$exe = Join-Path $root ("installer\ApexFileShare_Setup_{0}.{1}.exe" -f $Version, $Build)
Write-Host "exe: $exe"
foreach ($e in (Test-Exe $exe)) { $errors.Add("exe: $e") }

if ($errors.Count -gt 0) {
    Write-Host ''
    Write-Host "REFUSED - nothing was sent ($($errors.Count)):"
    foreach ($e in $errors) { Write-Host "  - $e" }
    exit 1
}

$ErrorActionPreference = 'Continue'  # the exit code of upload.ps1 decides, not its stderr lines
$cmd = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $uploader, '-App', $AppId, '-Kind', 'exe',
          '-File', $exe, '-Version', $Version, '-Build', "$Build")
if ($Notes) { $cmd += @('-Notes', $Notes) }
if ($AuctionConfirm) { $cmd += @('-AuctionConfirm', $AuctionConfirm) }
if ($DryRun) { $cmd += '-DryRun' }
$shown = ($cmd | ForEach-Object { if ($_ -match '[\s"]') { '"' + ($_ -replace '"', '\"') + '"' } else { $_ } }) -join ' '
Write-Host ''
Write-Host "RUN: powershell $shown"
& powershell.exe @cmd
if ($LASTEXITCODE -ne 0) {
    Write-Host "upload.ps1 refused or failed (exit $LASTEXITCODE)"
    exit $LASTEXITCODE
}
exit 0
