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

# Kill any previous zip so a failed build cannot leave an uploadable OLD zip.
$oldZip = Join-Path $paths.WorkDir 'build\swimiq-web-godaddy.zip'
if (Test-Path -LiteralPath $oldZip) {
    Remove-Item -LiteralPath $oldZip -Force
    Write-Host '[OK] Deleted old swimiq-web-godaddy.zip (prevents uploading a stale zip).' -ForegroundColor Yellow
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

$repoRoot = Split-Path $paths.WorkDir -Parent
$gitBranch = ''
$gitCommit = ''
try {
    Push-Location $repoRoot
    $gitBranch = (git rev-parse --abbrev-ref HEAD 2>$null | Out-String).Trim()
    $gitCommit = (git rev-parse --short HEAD 2>$null | Out-String).Trim()
} catch {
    $gitBranch = 'unknown'
    $gitCommit = 'unknown'
} finally {
    Pop-Location
}

Write-Host ('Git branch: ' + $gitBranch) -ForegroundColor Cyan
Write-Host ('Git commit: ' + $gitCommit) -ForegroundColor Cyan
if ($gitBranch -ne 'cursor/dryland-power-index-b7ef') {
    Write-Host ''
    Write-Host 'ERROR: Wrong git branch for website publish.' -ForegroundColor Red
    Write-Host ('Current: ' + $gitBranch) -ForegroundColor Red
    Write-Host 'Required: cursor/dryland-power-index-b7ef' -ForegroundColor Yellow
    Write-Host 'Run GET-LATEST-FIXED-APP.bat, then PUBLISH-SWIMIQAPP-COM.bat again.' -ForegroundColor Yellow
    exit 1
}

# Public website: cloud coaching only (no local Elite URL baked into the build).
$prodEnv = Join-Path $env:TEMP 'swimiq-godaddy-defines.env'
@(
    "SUPABASE_URL=$url"
    "SUPABASE_ANON_KEY=$key"
    'VIDEO_ENGINE_V2=true'
    'VIDEO_ENGINE_V2_DUAL_RUN=false'
) | Set-Content -LiteralPath $prodEnv -Encoding ascii

Write-Host 'Cleaning + pub get...' -ForegroundColor Cyan
Write-Host 'If this fails on pub.dev, Wi-Fi/DNS is blocked — fix internet, then retry.' -ForegroundColor Yellow
Invoke-FlutterCleanSafe -FlutterBat $paths.FlutterBat
& $paths.FlutterBat pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host ''
    Write-Host 'BUILD FAILED at flutter pub get (often pub.dev / Wi-Fi).' -ForegroundColor Red
    Write-Host 'DO NOT upload any zip. Old zip was deleted on purpose.' -ForegroundColor Red
    Write-Host 'Open https://pub.dev in Chrome. When it loads, run Publish again.' -ForegroundColor Yellow
    exit $LASTEXITCODE
}

Write-Host 'flutter build web --release (3-8 minutes)...' -ForegroundColor Cyan
& $paths.FlutterBat build web --release --base-href=/ --dart-define-from-file=$prodEnv
if ($LASTEXITCODE -ne 0) {
    Write-Host 'BUILD FAILED - do not upload to GoDaddy yet.' -ForegroundColor Red
    Write-Host 'DO NOT upload any zip. Old zip was deleted on purpose.' -ForegroundColor Red
    exit $LASTEXITCODE
}

$webOut = Join-Path $paths.WorkDir 'build\web'
$mainJs = Join-Path $webOut 'main.dart.js'
if (-not (Test-Path (Join-Path $webOut 'main.dart.js'))) {
    Write-Host 'BUILD FAILED - missing build\web\main.dart.js' -ForegroundColor Red
    exit 1
}

# Prove this is the NEW Dryland/Power Index / 25MB-messaging build.
$mainText = Get-Content -LiteralPath $mainJs -Raw -ErrorAction Stop
$mustHave = @(
    'Build highlight package',
    '720p',
    'National caliber'
)
$mustNotHave = @(
    'under about 50 MB',
    'Coming soon — Elite feature',
    'coming soon (Elite)'
)
foreach ($needle in $mustHave) {
    if ($mainText -notlike ("*" + $needle + "*")) {
        Write-Host ''
        Write-Host ('BUILD LOOKS STALE — missing proof string: ' + $needle) -ForegroundColor Red
        Write-Host 'Wrong branch or old code was compiled. Do NOT upload.' -ForegroundColor Red
        exit 1
    }
}
foreach ($needle in $mustNotHave) {
    if ($mainText -like ("*" + $needle + "*")) {
        Write-Host ''
        Write-Host ('BUILD LOOKS STALE — still contains: ' + $needle) -ForegroundColor Red
        Write-Host 'Wrong branch or old code was compiled. Do NOT upload.' -ForegroundColor Red
        exit 1
    }
}
Write-Host '[OK] New-build proof strings found in main.dart.js' -ForegroundColor Green

# SPA routing for GoDaddy Apache
$htaccess = Join-Path $paths.WorkDir 'web\.htaccess'
if (Test-Path $htaccess) {
    Copy-Item $htaccess (Join-Path $webOut '.htaccess') -Force
    Write-Host '[OK] .htaccess' -ForegroundColor Green
}

# Keep legal pages at /privacy /terms /ai beside the Flutter app
$websiteDir = Join-Path $paths.WorkDir 'website'
foreach ($page in @('privacy.html', 'terms.html', 'ai.html', 'delete-account.html')) {
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

# Marker so we can tell Flutter deploy from old marketing site / stale zip
$stamp = @(
    'SwimIQ Flutter web build'
    ('branch=' + $gitBranch)
    ('commit=' + $gitCommit)
    ('built_at=' + (Get-Date -Format o))
    'proof=Build highlight package|720p|National caliber'
    'forbidden_absent=under about 50 MB|coming soon (Elite)'
) -join "`r`n"
Set-Content -LiteralPath (Join-Path $webOut 'SWIMIQ-FLUTTER-BUILD.txt') -Value $stamp -Encoding ascii
Write-Host ('[OK] Wrote SWIMIQ-FLUTTER-BUILD.txt commit=' + $gitCommit) -ForegroundColor Green

Write-Host ''
Write-Host '========================================' -ForegroundColor Green
Write-Host 'DONE. Flutter app is in build\web\' -ForegroundColor Green
Write-Host 'Upload THAT folder to GoDaddy public_html' -ForegroundColor Green
Write-Host '(Replace old index.html - do NOT upload website\ alone)' -ForegroundColor Yellow
Write-Host '========================================' -ForegroundColor Green
