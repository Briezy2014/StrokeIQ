# Build SwimIQ for web → upload to GoDaddy public_html
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'swimiq-windows-paths.ps1')

Write-Host ''
Write-Host 'Building SwimIQ for GoDaddy...' -ForegroundColor Cyan
Write-Host ''

try {
    $paths = Initialize-SwimIqWindowsPaths -ScriptsRoot $PSScriptRoot
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

$envFile = Join-Path $paths.WorkDir '.env'
if (-not (Test-Path -LiteralPath $envFile)) {
    Write-Host 'ERROR: Missing .env in swimiq folder.' -ForegroundColor Red
    exit 1
}

$url = $null
$key = $null
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*SUPABASE_URL\s*=\s*(.+)\s*$') { $url = $matches[1].Trim() }
    if ($_ -match '^\s*SUPABASE_ANON_KEY\s*=\s*(.+)\s*$') { $key = $matches[1].Trim() }
}

if (-not $url -or -not $key) {
    Write-Host 'ERROR: .env must contain SUPABASE_URL and SUPABASE_ANON_KEY' -ForegroundColor Red
    exit 1
}

& $paths.FlutterBat clean
& $paths.FlutterBat pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& $paths.FlutterBat build web --release `
    --dart-define=SUPABASE_URL=$url `
    --dart-define=SUPABASE_ANON_KEY=$key

if ($LASTEXITCODE -ne 0) {
    Write-Host 'BUILD FAILED - do not upload to GoDaddy yet.' -ForegroundColor Red
    exit $LASTEXITCODE
}

if (-not (Test-Path (Join-Path $paths.WorkDir 'build\web\main.dart.js'))) {
    Write-Host 'BUILD FAILED - missing build\web\main.dart.js' -ForegroundColor Red
    exit 1
}

$htaccess = Join-Path $paths.WorkDir 'web\.htaccess'
if (Test-Path $htaccess) {
    Copy-Item $htaccess (Join-Path $paths.WorkDir 'build\web\.htaccess') -Force
    Write-Host 'Added build\web\.htaccess for GoDaddy'
}

Write-Host ''
Write-Host '========================================' -ForegroundColor Green
Write-Host 'DONE. Upload everything in build\web\ to GoDaddy public_html' -ForegroundColor Green
Write-Host '========================================' -ForegroundColor Green
