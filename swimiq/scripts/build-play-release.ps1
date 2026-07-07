# Build a signed Google Play app bundle (reads Supabase keys from .env)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')

if (-not (Test-Path ".env")) {
    Write-Host "Missing swimiq/.env — add SUPABASE_URL and SUPABASE_ANON_KEY first." -ForegroundColor Red
    exit 1
}

$defines = @()
Get-Content ".env" | ForEach-Object {
    $line = $_.Trim()
    if ($line -eq '' -or $line.StartsWith('#')) { return }
    $eq = $line.IndexOf('=')
    if ($eq -lt 1) { return }
    $key = $line.Substring(0, $eq).Trim()
    $value = $line.Substring($eq + 1).Trim()
    if ($key -eq 'SUPABASE_URL' -or $key -eq 'SUPABASE_ANON_KEY') {
        $defines += "--dart-define=${key}=${value}"
    }
}

if (-not (Test-Path "android\key.properties")) {
    Write-Host @"

Google Play needs a release signing key.

1. Run once:
   cd android
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

2. Copy android\key.properties.example to android\key.properties and fill in passwords.

"@ -ForegroundColor Yellow
    exit 1
}

flutter pub get
flutter build appbundle --release @defines
Write-Host "`nUpload this file to Play Console → Internal testing:" -ForegroundColor Green
Write-Host "build\app\outputs\bundle\release\app-release.aab`n"
