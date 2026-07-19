# Build SwimIQ Flutter web for GoDaddy public_html (NOT the old marketing website/).
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'swimiq-windows-paths.ps1')

Write-Host ''
Write-Host 'Building SwimIQ FLUTTER APP for https://swimiqapp.com ...' -ForegroundColor Cyan
Write-Host '(This replaces the old marketing homepage with the real login app.)' -ForegroundColor Yellow
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
    $line = $_.Trim()
    if ($line -match '^\s*SUPABASE_URL\s*=\s*(.+)\s*$') { $url = $matches[1].Trim().Trim('"').Trim("'") }
    if ($line -match '^\s*SUPABASE_ANON_KEY\s*=\s*(.+)\s*$') { $key = $matches[1].Trim().Trim('"').Trim("'") }
}
$url = $url -replace 'https:https//', 'https://' -replace 'https//', 'https://'
if ($url -and $url -notmatch '^https://') { $url = "https://$url" }

if (-not $url -or -not $key -or $url -match 'your-project' -or $key -match 'your-supabase') {
    Write-Host 'ERROR: .env must contain real SUPABASE_URL and SUPABASE_ANON_KEY' -ForegroundColor Red
    exit 1
}

# Hosted site shows Elite Video Lab UI and calls Elite on THIS PC when
# START-SWIMIQ-WITH-ELITE.bat left 127.0.0.1:8080 running (Chrome PNA + CORS).
$prodEnv = Join-Path $env:TEMP 'swimiq-godaddy-defines.env'
@(
    "SUPABASE_URL=$url"
    "SUPABASE_ANON_KEY=$key"
    'VIDEO_ENGINE_V2=true'
    'VIDEO_ENGINE_V2_DUAL_RUN=true'
    'ANALYSIS_API_BASE_URL=http://127.0.0.1:8080'
) | Set-Content -LiteralPath $prodEnv -Encoding ascii

Write-Host 'Cleaning + pub get...' -ForegroundColor Cyan
Invoke-FlutterCleanSafe -FlutterBat $paths.FlutterBat
& $paths.FlutterBat pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host 'flutter build web --release (3-8 minutes)...' -ForegroundColor Cyan
& $paths.FlutterBat build web --release --base-href=/ --dart-define-from-file=$prodEnv
if ($LASTEXITCODE -ne 0) {
    Write-Host 'BUILD FAILED - do not upload to GoDaddy yet.' -ForegroundColor Red
    exit $LASTEXITCODE
}

$webOut = Join-Path $paths.WorkDir 'build\web'
if (-not (Test-Path (Join-Path $webOut 'main.dart.js'))) {
    Write-Host 'BUILD FAILED - missing build\web\main.dart.js' -ForegroundColor Red
    exit 1
}

# SPA routing for GoDaddy Apache
$htaccess = Join-Path $paths.WorkDir 'web\.htaccess'
if (Test-Path $htaccess) {
    Copy-Item $htaccess (Join-Path $webOut '.htaccess') -Force
    Write-Host '[OK] .htaccess' -ForegroundColor Green
}

# Keep legal pages at /privacy /terms /ai beside the Flutter app
$websiteDir = Join-Path $paths.WorkDir 'website'
foreach ($page in @('privacy.html', 'terms.html', 'ai.html')) {
    $src = Join-Path $websiteDir $page
    if (Test-Path -LiteralPath $src) {
        Copy-Item -LiteralPath $src -Destination (Join-Path $webOut $page) -Force
    }
}
$cssSrc = Join-Path $websiteDir 'css'
$cssDst = Join-Path $webOut 'css'
if (Test-Path -LiteralPath $cssSrc) {
    New-Item -ItemType Directory -Force -Path $cssDst | Out-Null
    Copy-Item -Path (Join-Path $cssSrc '*') -Destination $cssDst -Recurse -Force
}
Write-Host '[OK] privacy/terms/ai pages copied into build\web' -ForegroundColor Green

# Marker so we can tell Flutter deploy from old marketing site
"SwimIQ Flutter web build $(Get-Date -Format o)" | Set-Content (Join-Path $webOut 'SWIMIQ-FLUTTER-BUILD.txt') -Encoding ascii

Write-Host ''
Write-Host '========================================' -ForegroundColor Green
Write-Host 'DONE. Flutter app is in build\web\' -ForegroundColor Green
Write-Host 'Upload THAT folder to GoDaddy public_html' -ForegroundColor Green
Write-Host '(Replace old index.html - do NOT upload website\ alone)' -ForegroundColor Yellow
Write-Host '========================================' -ForegroundColor Green
