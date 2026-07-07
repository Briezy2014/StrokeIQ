# SwimIQ — run in Chrome on Windows (handles paths with spaces)
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
  if (Test-Path "$candidate\bin\flutter.bat") {
    $flutterBin = "$candidate\bin"
    break
  }
}

if ($null -eq $flutterBin) {
  $flutterBin = (Get-Command flutter -ErrorAction SilentlyContinue).Source
  if ($flutterBin) {
    $flutterBin = Split-Path -Parent $flutterBin
  }
}

if (-not $flutterBin) {
  Write-Host "Flutter not found. Install to C:\flutter (no spaces) and add C:\flutter\bin to PATH."
  exit 1
}

# Map drive letters when paths contain spaces (Flutter/Dart native hooks break otherwise).
if ($flutterBin -match " ") {
  subst F: $flutterBin.TrimEnd('\bin') 2>$null
  $flutterBin = "F:\bin"
  Write-Host "Mapped Flutter to F:\ (path had spaces)"
}

if ($projectRoot -match " ") {
  subst S: $strokeRoot 2>$null
  $projectRoot = "S:\swimiq"
  Write-Host "Mapped project to S:\swimiq (path had spaces)"
}

$env:Path = "$flutterBin;$env:Path"

# Pub cache under a spaced username breaks native hooks — keep it on S:
$pubCache = "S:\pub-cache"
New-Item -ItemType Directory -Force -Path $pubCache | Out-Null
$env:PUB_CACHE = $pubCache

Set-Location $projectRoot

if (-not (Test-Path ".env")) {
  Write-Host "Creating .env from .env.example — add your Supabase keys before login works."
  Copy-Item ".env.example" ".env"
}

Write-Host "Running from: $projectRoot"
Write-Host "Flutter: $flutterBin\flutter.bat"

flutter clean
flutter pub get
flutter run -d chrome
