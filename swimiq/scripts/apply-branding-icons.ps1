# Regenerate Android, iOS, and web launcher icons from assets/branding/swimiq_icon.png
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')

if (-not (Test-Path "assets\branding\swimiq_icon.png")) {
    Write-Host "Missing assets\branding\swimiq_icon.png — add your square icon first." -ForegroundColor Red
    exit 1
}

flutter pub get
dart run flutter_launcher_icons
Write-Host "`nIcons updated. Run: flutter clean && flutter run -d chrome`n" -ForegroundColor Green
