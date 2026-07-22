# SwimIQ - Google Play App Bundle (.aab) release build
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'scripts\swimiq-windows-paths.ps1')

Write-Host ''
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ' SwimIQ - Build Google Play AAB' -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ''

try {
    $paths = Initialize-SwimIqWindowsPaths -ScriptsRoot (Join-Path $PSScriptRoot 'scripts')
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host 'Press Enter'; exit 1
}

$envFile = Join-Path $paths.WorkDir '.env'
$keyProps = Join-Path $paths.WorkDir 'android\key.properties'
$keystoreFile = Join-Path $paths.WorkDir 'android\keystore\swimiq-upload.jks'

if (-not (Test-Path -LiteralPath $envFile)) {
    Write-Host 'ERROR: Missing .env in swimiq folder' -ForegroundColor Red
    Read-Host 'Press Enter'; exit 1
}

$url = $null; $key = $null
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*SUPABASE_URL\s*=\s*(.+)\s*$') { $url = $matches[1].Trim() }
    if ($_ -match '^\s*SUPABASE_ANON_KEY\s*=\s*(.+)\s*$') { $key = $matches[1].Trim() }
}
$url = $url -replace 'https:https//','https://' -replace 'https//','https://'
if ($url -and $url -notmatch '^https://') { $url = "https://$url" }
if (-not $url -or -not $key -or $url -match 'your-project') {
    Write-Host 'ERROR: .env needs SUPABASE_URL and SUPABASE_ANON_KEY' -ForegroundColor Red
    Read-Host 'Press Enter'; exit 1
}

Write-Host 'Checking Android toolchain...' -ForegroundColor Cyan
$doctor = & $paths.FlutterBat doctor 2>&1 | Out-String
if ($doctor -notmatch '\[√\].*Android toolchain' -and $doctor -notmatch '\[√\].*Android SDK') {
    Write-Host 'WARNING: Android toolchain may not be ready. Run: flutter doctor' -ForegroundColor Yellow
    Write-Host $doctor
}

if (-not (Test-Path -LiteralPath $keyProps)) {
    Write-Host ''
    Write-Host 'WARNING: android\key.properties missing — build will use DEBUG signing.' -ForegroundColor Yellow
    Write-Host 'Google Play requires a release keystore. Run GENERATE-ANDROID-KEYSTORE.bat first.' -ForegroundColor Yellow
    Write-Host ''
} elseif (-not (Test-Path -LiteralPath $keystoreFile)) {
    Write-Host 'WARNING: keystore file missing at android\keystore\swimiq-upload.jks' -ForegroundColor Yellow
}

Write-Host ''
Write-Host 'Building release App Bundle (first run: 5-15 minutes)...' -ForegroundColor Cyan
Invoke-FlutterCleanSafe -FlutterBat $paths.FlutterBat
& $paths.FlutterBat pub get
if ($LASTEXITCODE -ne 0) { Read-Host 'Press Enter'; exit $LASTEXITCODE }

& $paths.FlutterBat build appbundle --release `
    --dart-define=SUPABASE_URL=$url `
    --dart-define=SUPABASE_ANON_KEY=$key

$aab = Join-Path $paths.WorkDir 'build\app\outputs\bundle\release\app-release.aab'
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $aab)) {
    Write-Host ''
    Write-Host 'BUILD FAILED' -ForegroundColor Red
    Write-Host ''
    Write-Host 'Common fixes:' -ForegroundColor Yellow
    Write-Host '  1. Android Studio -> SDK Manager -> Android SDK + Build-Tools' -ForegroundColor White
    Write-Host '  2. flutter doctor --android-licenses  (accept all)' -ForegroundColor White
    Write-Host '  3. Install JDK 17 (Android Studio bundles it)' -ForegroundColor White
    Write-Host '  4. Double-click DIAGNOSE-ANDROID.bat and read the log' -ForegroundColor White
    Write-Host '  5. If Gradle OOM: close Chrome, reboot, retry' -ForegroundColor White
    Write-Host ''
    Write-Host 'Save full error: flutter build appbundle --release > build-log.txt 2>&1' -ForegroundColor Cyan
    Read-Host 'Press Enter'; exit 1
}

Write-Host ''
Write-Host '========================================' -ForegroundColor Green
Write-Host ' GOOGLE PLAY AAB READY' -ForegroundColor Green
Write-Host '========================================' -ForegroundColor Green
Write-Host " Upload this file in Play Console:`n  $aab" -ForegroundColor Green
Write-Host ''
Write-Host 'Play Console -> Release -> Production -> Create release -> Upload' -ForegroundColor Cyan
Read-Host 'Press Enter to close'
