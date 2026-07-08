# SwimIQ - Android release APK build (Kara Williams / Windows)
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'scripts\swimiq-windows-paths.ps1')

Write-Host ''
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ' SwimIQ - Build Android APK' -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ''

try {
    $paths = Initialize-SwimIqWindowsPaths -ScriptsRoot (Join-Path $PSScriptRoot 'scripts')
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host 'Press Enter'; exit 1
}

$envFile = Join-Path $paths.WorkDir '.env'
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
& $paths.FlutterBat doctor --android-licenses 2>$null | Out-Null
& $paths.FlutterBat doctor | Select-String -Pattern 'Android toolchain'

Write-Host ''
Write-Host 'Building release APK (5-10 minutes first time)...' -ForegroundColor Cyan
Invoke-FlutterCleanSafe -FlutterBat $paths.FlutterBat
& $paths.FlutterBat pub get
if ($LASTEXITCODE -ne 0) { Read-Host 'Press Enter'; exit $LASTEXITCODE }

& $paths.FlutterBat build apk --release `
    --dart-define=SUPABASE_URL=$url `
    --dart-define=SUPABASE_ANON_KEY=$key

$apk = Join-Path $paths.WorkDir 'build\app\outputs\flutter-apk\app-release.apk'
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $apk)) {
    Write-Host 'BUILD FAILED' -ForegroundColor Red
    Write-Host 'Run: flutter doctor' -ForegroundColor Yellow
    Write-Host 'Install Android Studio + SDK if Android toolchain shows X' -ForegroundColor Yellow
    Read-Host 'Press Enter'; exit 1
}

Write-Host ''
Write-Host '========================================' -ForegroundColor Green
Write-Host ' ANDROID BUILD DONE' -ForegroundColor Green
Write-Host '========================================' -ForegroundColor Green
Write-Host " APK file:`n  $apk" -ForegroundColor Green
Write-Host ''
Write-Host 'Install on phone:' -ForegroundColor Cyan
Write-Host '  1. Copy app-release.apk to your Android phone' -ForegroundColor White
Write-Host '  2. Open it and allow Install from unknown sources if asked' -ForegroundColor White
Write-Host '  3. Sign in with your SwimIQ account' -ForegroundColor White
Read-Host 'Press Enter to close'
