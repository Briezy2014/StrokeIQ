# SwimIQ one-time Windows path fix (Kara Williams)
# Called by: FIX-KARA-PATHS.bat, fix-kara-paths.ps1

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$strokeRoot = Split-Path -Parent $projectRoot

Write-Host ''
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ' SwimIQ - Fix Windows Paths (once)' -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
Write-Host "SwimIQ folder: $projectRoot"
Write-Host ''

$flutterRoot = $null
foreach ($candidate in @("$env:USERPROFILE\flutter", 'C:\flutter', 'C:\src\flutter')) {
    if (Test-Path "$candidate\bin\flutter.bat") {
        $flutterRoot = $candidate
        break
    }
}
if (-not $flutterRoot) {
    $cmd = Get-Command flutter -ErrorAction SilentlyContinue
    if ($cmd) { $flutterRoot = (Split-Path -Parent $cmd.Source).TrimEnd('\bin') }
}
if (-not $flutterRoot) {
    Write-Host 'ERROR: Flutter not found.' -ForegroundColor Red
    Read-Host 'Press Enter to close'
    exit 1
}

subst F: /D 2>$null | Out-Null
subst S: /D 2>$null | Out-Null
subst F: $flutterRoot | Out-Null
subst S: $strokeRoot | Out-Null

New-Item -ItemType Directory -Force -Path 'S:\pub-cache' | Out-Null
[Environment]::SetEnvironmentVariable('PUB_CACHE', 'S:\pub-cache', 'User')
$env:PUB_CACHE = 'S:\pub-cache'
$env:Path = 'F:\bin;' + $env:Path

Set-Location 'S:\swimiq'
& 'F:\bin\flutter.bat' clean 2>$null | Out-Null

Write-Host 'OK  F: maps to Flutter' -ForegroundColor Green
Write-Host 'OK  S: maps to StrokeIQ' -ForegroundColor Green
Write-Host 'OK  PUB_CACHE saved as S:\pub-cache' -ForegroundColor Green
Write-Host ''
Write-Host 'Close ALL PowerShell + VS Code, then double-click LAUNCH-CHROME.bat' -ForegroundColor Yellow
Read-Host 'Press Enter to close'
