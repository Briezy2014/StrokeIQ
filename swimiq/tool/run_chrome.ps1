# SwimIQ - run in Chrome on Windows (handles paths with spaces)
# Usage: powershell -ExecutionPolicy Bypass -File tool\run_chrome.ps1

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$strokeRoot = Split-Path -Parent $projectRoot

# Common Flutter install locations when the username contains a space.
$flutterCandidates = @(
  "$env:USERPROFILE\flutter",
  "C:\flutter",
  "C:\src\flutter"
)

$flutterBin = $null
foreach ($candidate in $flutterCandidates) {
  $bat = Join-Path $candidate "bin\flutter.bat"
  if (Test-Path $bat) {
    $flutterBin = Join-Path $candidate "bin"
    break
  }
}

if ($null -eq $flutterBin) {
  $flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
  if ($flutterCmd) {
    $flutterBin = Split-Path -Parent $flutterCmd.Source
  }
}

if (-not $flutterBin) {
  Write-Host "Flutter not found. Install to C:\flutter (no spaces) and add C:\flutter\bin to PATH."
  exit 1
}

# Map drive letters when paths contain spaces (Flutter/Dart native hooks break otherwise).
$flutterRoot = Split-Path -Parent $flutterBin
if ($flutterRoot -match " ") {
  subst F: $flutterRoot 2>$null
  $flutterBin = "F:\bin"
  Write-Host "Mapped Flutter to F:\ (path had spaces)"
}

if ($projectRoot -match " ") {
  subst S: $strokeRoot 2>$null
  $projectRoot = "S:\swimiq"
  Write-Host "Mapped project to S:\swimiq (path had spaces)"
}

$env:Path = "$flutterBin;$env:Path"

Set-Location $projectRoot

if (-not (Test-Path ".env")) {
  Write-Host "Creating .env from .env.example - add your Supabase keys before login works."
  Copy-Item ".env.example" ".env"
}

$flutterBat = Join-Path $flutterBin "flutter.bat"
Write-Host "Running from: $projectRoot"
Write-Host "Flutter: $flutterBat"

& $flutterBat clean
& $flutterBat pub get
& $flutterBat run -d chrome
