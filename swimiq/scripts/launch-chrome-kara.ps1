# SwimIQ Chrome launcher (Kara Williams / OneDrive / spaces / objective_c hooks)
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'swimiq-windows-paths.ps1')

$repoRoot = Split-Path $PSScriptRoot -Parent
$ensureScript = Join-Path $PSScriptRoot 'ensure-video-db-fix.ps1'
if (Test-Path -LiteralPath $ensureScript) {
    try {
        . $ensureScript
        Ensure-VideoDbFix -Root $repoRoot
    } catch {
        Write-Host "Note: could not write video DB fix files: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

Write-Host ''
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ' SwimIQ - Launch Chrome' -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ''

try {
    $paths = Initialize-SwimIqWindowsPaths -ScriptsRoot $PSScriptRoot -CleanDartTool
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host 'Press Enter to close'
    exit 1
}

$envFile = Join-Path $paths.WorkDir '.env'
$exampleFile = Join-Path $paths.WorkDir '.env.example'

if (-not (Test-Path -LiteralPath $envFile)) {
    if (Test-Path -LiteralPath $exampleFile) {
        Copy-Item $exampleFile $envFile
    }
    Write-Host 'Created .env - add Supabase URL + anon key, save, run again.' -ForegroundColor Yellow
    notepad $envFile
    Read-Host 'Press Enter to close'
    exit 1
}

$url = $null
$key = $null
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*SUPABASE_URL\s*=\s*(.+)\s*$') { $url = $matches[1].Trim() }
    if ($_ -match '^\s*SUPABASE_ANON_KEY\s*=\s*(.+)\s*$') { $key = $matches[1].Trim() }
}

if ($url) {
    $url = $url -replace 'https:https//', 'https://'
    $url = $url -replace 'https//', 'https://'
    if ($url -notmatch '^https://') { $url = "https://$url" }
}

if (-not $url -or -not $key -or $url -match 'your-project' -or $key -match 'your-supabase') {
    Write-Host 'ERROR: Edit .env with real Supabase keys.' -ForegroundColor Red
    notepad $envFile
    Read-Host 'Press Enter to close'
    exit 1
}

Write-Host 'Pulling fixed app branch (dashboard + Elite Video)...' -ForegroundColor Yellow
Push-Location (Split-Path $paths.WorkDir -Parent)
try {
    git fetch origin cursor/elite-video-on-dashboard-b7ef 2>$null
    git checkout -f cursor/elite-video-on-dashboard-b7ef 2>$null
    git reset --hard origin/cursor/elite-video-on-dashboard-b7ef 2>$null
    Write-Host '[OK] On cursor/elite-video-on-dashboard-b7ef' -ForegroundColor Green
} catch {
    Write-Host '[WARN] Git update skipped - using local copy.' -ForegroundColor Yellow
} finally {
    Pop-Location
}

# Elite Video Lab is the product Video experience (old Gemini tab path stays off).
try {
    $envLines = Get-Content -LiteralPath $envFile
    $out = @()
    $foundV2 = $false
    $foundApi = $false
    $foundDual = $false
    foreach ($line in $envLines) {
        if ($line -match '^\s*VIDEO_ENGINE_V2\s*=') {
            $out += 'VIDEO_ENGINE_V2=true'
            $foundV2 = $true
        } elseif ($line -match '^\s*ANALYSIS_API_BASE_URL\s*=') {
            $out += 'ANALYSIS_API_BASE_URL=http://127.0.0.1:8080'
            $foundApi = $true
        } elseif ($line -match '^\s*VIDEO_ENGINE_V2_DUAL_RUN\s*=') {
            $out += 'VIDEO_ENGINE_V2_DUAL_RUN=false'
            $foundDual = $true
        } else {
            $out += $line
        }
    }
    if (-not $foundV2) { $out += 'VIDEO_ENGINE_V2=true' }
    if (-not $foundApi) { $out += 'ANALYSIS_API_BASE_URL=http://127.0.0.1:8080' }
    if (-not $foundDual) { $out += 'VIDEO_ENGINE_V2_DUAL_RUN=false' }
    # ASCII avoids UTF-8 BOM, which breaks --dart-define-from-file parsing.
    Set-Content -LiteralPath $envFile -Value $out -Encoding ascii
    Write-Host '[OK] VIDEO_ENGINE_V2=true (Elite Video Lab)' -ForegroundColor Green
    Write-Host '     ANALYSIS_API_BASE_URL=http://127.0.0.1:8080' -ForegroundColor Green
} catch {
    Write-Host '[WARN] Could not update VIDEO_ENGINE_V2 in .env' -ForegroundColor Yellow
}

# START-SWIMIQ-WITH-ELITE already started Elite. Only ping health here - never kill/restart.
$eliteWait = Join-Path $PSScriptRoot 'start-elite-and-wait.ps1'
if (Test-Path -LiteralPath $eliteWait) {
    Write-Host ''
    Write-Host 'Confirming Elite analysis server is still up...' -ForegroundColor Cyan
    & powershell -NoProfile -ExecutionPolicy Bypass -File $eliteWait -CheckOnly
    if ($LASTEXITCODE -ne 0) {
        Write-Host ''
        Write-Host 'ERROR: Elite server is not reachable at http://127.0.0.1:8080/health' -ForegroundColor Red
        Write-Host 'Run START-SWIMIQ-WITH-ELITE.bat and leave the Elite window open.' -ForegroundColor Red
        Read-Host 'Press Enter to close'
        exit 1
    }
}

Write-Host 'Checking Aspyn login icon (assets\branding\icon.png)...' -ForegroundColor Cyan
$brandDir = Join-Path $paths.WorkDir 'assets\branding'
$loginIcon = Join-Path $brandDir 'icon.png'
$logoIcon = Join-Path $brandDir 'logo.png'
$legacyIcon = Join-Path $brandDir 'swimiq_icon.png'
$webFav = Join-Path $paths.WorkDir 'web\favicon.png'
$web512 = Join-Path $paths.WorkDir 'web\icons\Icon-512.png'
$web192 = Join-Path $paths.WorkDir 'web\icons\Icon-192.png'
New-Item -ItemType Directory -Force -Path $brandDir | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $paths.WorkDir 'web\icons') | Out-Null

# Prefer a real PNG (>= 20KB). Tiny/corrupt files cause the triangle fallback.
function Test-GoodPng([string]$path) {
    if (-not (Test-Path -LiteralPath $path)) { return $false }
    return ((Get-Item -LiteralPath $path).Length -ge 20000)
}

if (-not (Test-GoodPng $loginIcon)) {
    if (Test-GoodPng $logoIcon) {
        Copy-Item -LiteralPath $logoIcon -Destination $loginIcon -Force
        Write-Host 'OK  Copied logo.png -> icon.png for login' -ForegroundColor Green
    } elseif (Test-GoodPng $legacyIcon) {
        Copy-Item -LiteralPath $legacyIcon -Destination $loginIcon -Force
        Copy-Item -LiteralPath $legacyIcon -Destination $logoIcon -Force
        Write-Host 'OK  Copied swimiq_icon.png -> icon.png for login' -ForegroundColor Green
    } else {
        Write-Host '[FAIL] Aspyn login icon missing or too small.' -ForegroundColor Red
        Write-Host "Expected: $loginIcon (at least 20KB PNG)" -ForegroundColor Red
        Write-Host 'Drag your 512x512 SwimIQ/Aspyn icon onto COPY-LOGO.bat, then run this again.' -ForegroundColor Yellow
        Read-Host 'Press Enter to close'
        exit 1
    }
}

# Keep web favicons in sync so Chrome never shows a stale triangle tab icon.
Copy-Item -LiteralPath $loginIcon -Destination $logoIcon -Force
Copy-Item -LiteralPath $loginIcon -Destination $webFav -Force
Copy-Item -LiteralPath $loginIcon -Destination $web512 -Force
Copy-Item -LiteralPath $loginIcon -Destination $web192 -Force
$iconBytes = (Get-Item -LiteralPath $loginIcon).Length
Write-Host ("OK  Login icon ready ({0} bytes): {1}" -f $iconBytes, $loginIcon) -ForegroundColor Green

Write-Host 'Cleaning old build cache (fixes objective_c hook errors)...' -ForegroundColor Yellow
Invoke-FlutterCleanSafe -FlutterBat $paths.FlutterBat

Write-Host ''
Write-Host '############################################' -ForegroundColor Yellow
Write-Host ' CLOSE every swimiqapp.com tab first.' -ForegroundColor Yellow
Write-Host ' Fixed app address must be localhost' -ForegroundColor Yellow
Write-Host ' or 127.0.0.1 - NEVER swimiqapp.com' -ForegroundColor Yellow
Write-Host ' Black workstation banner = OLD website.' -ForegroundColor Yellow
Write-Host '############################################' -ForegroundColor Yellow
Write-Host ''
Write-Host 'Clearing old Flutter web ports (fixes errno 10048)...' -ForegroundColor Cyan
$killWeb = Join-Path $PSScriptRoot 'kill-flutter-web-port.ps1'
if (Test-Path -LiteralPath $killWeb) {
    & powershell -NoProfile -ExecutionPolicy Bypass -File $killWeb
}

Write-Host 'Starting Chrome - wait 2-3 minutes...' -ForegroundColor Cyan
Write-Host ''

& $paths.FlutterBat pub get
if ($LASTEXITCODE -ne 0) {
    Read-Host 'Press Enter to close'
    exit $LASTEXITCODE
}

# Force a clean localhost URL so Chrome does not reopen swimiqapp.com.
# Disable HTTP cache so an old triangle/favicon cannot stick.
# Try a few ports if Windows still holds the last one.
$webPorts = @(7357, 7358, 7359, 7360)
$code = 1
foreach ($webPort in $webPorts) {
    Write-Host ("Trying http://127.0.0.1:{0} ..." -f $webPort) -ForegroundColor Cyan
    & $paths.FlutterBat run -d chrome `
        --web-hostname=127.0.0.1 `
        --web-port=$webPort `
        --web-browser-flag=--disable-http-cache `
        --dart-define-from-file=$envFile
    $code = $LASTEXITCODE
    if ($code -eq 0) { break }
    # 10048 / bind failure: clear again and try next port
    Write-Host ("Port {0} failed (code {1}). Trying next..." -f $webPort, $code) -ForegroundColor Yellow
    if (Test-Path -LiteralPath $killWeb) {
        & powershell -NoProfile -ExecutionPolicy Bypass -File $killWeb
    }
    Start-Sleep -Seconds 1
}
Write-Host ''
if ($code -ne 0) {
    Write-Host "Launch failed (code $code)" -ForegroundColor Red
} else {
    Write-Host 'Chrome session ended.' -ForegroundColor Green
}
Read-Host 'Press Enter to close'
exit $code
