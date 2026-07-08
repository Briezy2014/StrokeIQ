# SwimIQ - ONE FILE GoDaddy web build (Kara Williams / Windows)
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'scripts\swimiq-windows-paths.ps1')

Write-Host ''
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ' SwimIQ - Build for GoDaddy' -ForegroundColor Cyan
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
    Write-Host 'ERROR: Missing .env' -ForegroundColor Red
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

Write-Host 'Building release web app (3-5 minutes)...' -ForegroundColor Cyan
Invoke-FlutterCleanSafe -FlutterBat $paths.FlutterBat
& $paths.FlutterBat pub get
if ($LASTEXITCODE -ne 0) { Read-Host 'Press Enter'; exit $LASTEXITCODE }

& $paths.FlutterBat build web --release `
    --dart-define=SUPABASE_URL=$url `
    --dart-define=SUPABASE_ANON_KEY=$key

$webOut = Join-Path $paths.WorkDir 'build\web'
if ($LASTEXITCODE -ne 0) {
    Write-Host 'BUILD FAILED - do not upload to GoDaddy' -ForegroundColor Red
    Read-Host 'Press Enter'; exit 1
}

if (-not (Test-Path (Join-Path $webOut 'main.dart.js'))) {
    Write-Host 'BUILD FAILED - missing main.dart.js' -ForegroundColor Red
    Read-Host 'Press Enter'; exit 1
}

$htaccess = Join-Path $paths.WorkDir 'web\.htaccess'
if (Test-Path $htaccess) {
    Copy-Item $htaccess (Join-Path $webOut '.htaccess') -Force
    Write-Host 'OK  Added .htaccess for GoDaddy' -ForegroundColor Green
}

$zipScript = Join-Path $PSScriptRoot 'scripts\zip-web-godaddy.ps1'
$zipPath = Join-Path $paths.WorkDir 'build\swimiq-web-godaddy.zip'
if (Test-Path $zipScript) {
    & $zipScript -WebDir $webOut -ZipPath $zipPath
}

Write-Host ''
Write-Host '========================================' -ForegroundColor Green
Write-Host ' BUILD DONE' -ForegroundColor Green
Write-Host '========================================' -ForegroundColor Green
Write-Host " Option A - ZIP (easiest on GoDaddy):" -ForegroundColor Green
Write-Host "   Upload ONE file:`n   $zipPath" -ForegroundColor Green
Write-Host '   Then Extract in File Manager (see below)' -ForegroundColor Green
Write-Host ''
Write-Host " Option B - upload folder:`n   $webOut" -ForegroundColor Green
Write-Host ' to GoDaddy public_html (keep cgi-bin)' -ForegroundColor Green
Read-Host 'Press Enter to close'
