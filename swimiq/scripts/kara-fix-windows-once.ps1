# ONE-TIME: fix Windows paths with spaces for Kara Williams
# Maps F: = Flutter, S: = StrokeIQ, PUB_CACHE = S:\pub-cache (permanent)

$ErrorActionPreference = 'Stop'

$swimiqRoot = Split-Path -Parent $PSScriptRoot
$strokeRoot = Split-Path -Parent $swimiqRoot

Write-Host ''
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ' SwimIQ — permanent Windows path fix' -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ''

# Find Flutter
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
    exit 1
}

Write-Host "Flutter:  $flutterRoot"
Write-Host "Project:  $strokeRoot"
Write-Host "SwimIQ:   $swimiqRoot"
Write-Host ''

# Remove old drive letters if stuck
subst F: /D 2>$null
subst S: /D 2>$null

# Map drive letters (no spaces)
subst F: $flutterRoot
subst S: $strokeRoot

New-Item -ItemType Directory -Force -Path 'S:\pub-cache' | Out-Null

# Permanent PUB_CACHE for your Windows user (fixes objective_c every time)
[Environment]::SetEnvironmentVariable('PUB_CACHE', 'S:\pub-cache', 'User')
$env:PUB_CACHE = 'S:\pub-cache'

Write-Host 'OK  F:  ->  Flutter' -ForegroundColor Green
Write-Host 'OK  S:  ->  StrokeIQ folder' -ForegroundColor Green
Write-Host 'OK  PUB_CACHE = S:\pub-cache (saved to your Windows user profile)' -ForegroundColor Green
Write-Host ''

Set-Location 'S:\swimiq'
Write-Host 'Cleaning old build cache on spaced paths...' -ForegroundColor Yellow
& 'F:\bin\flutter.bat' clean 2>$null

Write-Host ''
Write-Host '========================================' -ForegroundColor Green
Write-Host ' DONE. IMPORTANT — do this now:' -ForegroundColor Green
Write-Host '========================================' -ForegroundColor Green
Write-Host ' 1. CLOSE all PowerShell windows' -ForegroundColor Yellow
Write-Host ' 2. CLOSE VS Code completely' -ForegroundColor Yellow
Write-Host ' 3. Re-open VS Code' -ForegroundColor Yellow
Write-Host ' 4. Double-click LAUNCH-CHROME.bat in the swimiq folder' -ForegroundColor Yellow
Write-Host ''
Write-Host ' Do NOT click VS Code Run / F5 for Flutter.' -ForegroundColor Red
Write-Host ' Do NOT type flutter run -d chrome yourself.' -ForegroundColor Red
Write-Host ''
