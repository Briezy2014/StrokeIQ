# SwimIQ — launch Flutter web in Chrome (Windows paths with spaces safe)
# If you see: 'C:\Users\Kara' is not recognized — use THIS script, not raw flutter run.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = $PSScriptRoot
$strokeRoot = Split-Path -Parent $projectRoot

$flutterCandidates = @(
    "$env:USERPROFILE\flutter",
    'C:\flutter',
    'C:\src\flutter'
)

$flutterBin = $null
foreach ($candidate in $flutterCandidates) {
    if (Test-Path "$candidate\bin\flutter.bat") {
        $flutterBin = "$candidate\bin"
        break
    }
}

if (-not $flutterBin) {
    $flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
    if ($flutterCmd) { $flutterBin = Split-Path -Parent $flutterCmd.Source }
}

if (-not $flutterBin) {
    Write-Host 'ERROR: Flutter not found. Install to C:\flutter (no spaces) or see docs/WINDOWS_SETUP.md'
    exit 1
}

$flutterRoot = $flutterBin.TrimEnd('\bin')
if ($flutterRoot -match ' ') {
    subst F: $flutterRoot 2>$null
    $flutterBin = 'F:\bin'
    Write-Host 'Mapped Flutter to F:\ (path had spaces)' -ForegroundColor Yellow
}

if ($projectRoot -match ' ' -or $strokeRoot -match ' ') {
    subst S: $strokeRoot 2>$null
    $projectRoot = 'S:\swimiq'
    Write-Host 'Mapped project to S:\swimiq (path had spaces)' -ForegroundColor Yellow
}

# Pub cache under "Kara Williams" breaks native hooks (objective_c) — keep it on S:
$pubCache = 'S:\pub-cache'
New-Item -ItemType Directory -Force -Path $pubCache | Out-Null
$env:PUB_CACHE = $pubCache
$env:Path = "$flutterBin;$env:Path"

Set-Location $projectRoot

Write-Host "`nSwimIQ Flutter web launcher" -ForegroundColor Cyan
Write-Host "Project: $projectRoot"
Write-Host "Flutter: $flutterBin"
Write-Host "PUB_CACHE: $pubCache`n"

flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "`nIf pub get still fails, run scripts\setup-short-path.bat once," -ForegroundColor Yellow
    Write-Host "open a NEW PowerShell window, then run .\run-chrome.ps1 again.`n" -ForegroundColor Yellow
    exit $LASTEXITCODE
}

flutter run -d chrome
