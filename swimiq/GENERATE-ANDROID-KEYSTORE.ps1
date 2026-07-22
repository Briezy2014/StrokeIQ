# One-time: create Google Play upload keystore
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'scripts\swimiq-windows-paths.ps1')

Write-Host ''
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ' SwimIQ - Generate Android Keystore' -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ''

try {
    $paths = Initialize-SwimIqWindowsPaths -ScriptsRoot (Join-Path $PSScriptRoot 'scripts')
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host 'Press Enter'; exit 1
}

$keystoreDir = Join-Path $paths.WorkDir 'android\keystore'
$keystoreFile = Join-Path $keystoreDir 'swimiq-upload.jks'
$keyProps = Join-Path $paths.WorkDir 'android\key.properties'
$keyPropsExample = Join-Path $paths.WorkDir 'android\key.properties.example'

New-Item -ItemType Directory -Force -Path $keystoreDir | Out-Null

if (Test-Path -LiteralPath $keystoreFile) {
    Write-Host "Keystore already exists:`n  $keystoreFile" -ForegroundColor Yellow
    Write-Host 'Delete it first only if you are starting a brand-new Play listing.' -ForegroundColor Yellow
    Read-Host 'Press Enter'; exit 0
}

$keytool = Get-Command keytool -ErrorAction SilentlyContinue
if (-not $keytool) {
    Write-Host 'ERROR: keytool not found. Install Android Studio (includes JDK).' -ForegroundColor Red
    Write-Host 'Then add JDK bin to PATH, or run from Android Studio Terminal.' -ForegroundColor Yellow
    Read-Host 'Press Enter'; exit 1
}

Write-Host 'You will be asked for a keystore password TWICE (store + key).' -ForegroundColor Cyan
Write-Host 'Write passwords down — Google Play needs this same keystore forever.' -ForegroundColor Yellow
Write-Host ''

& keytool -genkeypair -v `
    -keystore $keystoreFile `
    -keyalg RSA -keysize 2048 -validity 10000 `
    -alias swimiq `
    -dname "CN=SwimIQ, OU=Mobile, O=SwimIQ, L=US, ST=US, C=US"

if ($LASTEXITCODE -ne 0) {
    Write-Host 'keytool failed.' -ForegroundColor Red
    Read-Host 'Press Enter'; exit 1
}

Write-Host ''
Write-Host 'Keystore created:' -ForegroundColor Green
Write-Host "  $keystoreFile" -ForegroundColor Green
Write-Host ''

if (-not (Test-Path -LiteralPath $keyProps)) {
    Copy-Item -LiteralPath $keyPropsExample -Destination $keyProps
    Write-Host 'Created android\key.properties from example.' -ForegroundColor Cyan
    Write-Host 'Edit android\key.properties and replace YOUR_STORE_PASSWORD and YOUR_KEY_PASSWORD.' -ForegroundColor Yellow
} else {
    Write-Host 'android\key.properties already exists — verify storeFile points to:' -ForegroundColor Yellow
    Write-Host '  ../keystore/swimiq-upload.jks' -ForegroundColor White
}

Write-Host ''
Write-Host 'Next: edit android\key.properties, then double-click SWIMIQ-BUILD-AAB-NOW.bat' -ForegroundColor Green
Read-Host 'Press Enter'
