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
    Write-Host '[WARN] Git update skipped — using local copy.' -ForegroundColor Yellow
} finally {
    Pop-Location
}

# Keep Video on the working legacy path until the Elite Python server is running.
try {
    $envLines = Get-Content -LiteralPath $envFile
    $out = @()
    $found = $false
    foreach ($line in $envLines) {
        if ($line -match '^\s*VIDEO_ENGINE_V2\s*=') {
            $out += 'VIDEO_ENGINE_V2=false'
            $found = $true
        } else {
            $out += $line
        }
    }
    if (-not $found) { $out += 'VIDEO_ENGINE_V2=false' }
    Set-Content -LiteralPath $envFile -Value $out -Encoding UTF8
    Write-Host '[OK] VIDEO_ENGINE_V2=false (working Video Lab path)' -ForegroundColor Green
} catch {
    Write-Host '[WARN] Could not update VIDEO_ENGINE_V2 in .env' -ForegroundColor Yellow
}

Write-Host 'Checking branding PNG...' -ForegroundColor Cyan
$brandDir = Join-Path $paths.WorkDir 'assets\branding'
$loginIcon = Join-Path $brandDir 'icon.png'
$legacyIcon = Join-Path $brandDir 'swimiq_icon.png'
if (Test-Path -LiteralPath $loginIcon) {
    Write-Host "OK  Login uses assets\branding\icon.png" -ForegroundColor Green
} elseif (Test-Path -LiteralPath $legacyIcon) {
    Write-Host 'WARN Found swimiq_icon.png only — copying to icon.png for login...' -ForegroundColor Yellow
    Copy-Item -LiteralPath $legacyIcon -Destination $loginIcon -Force
} else {
    Write-Host 'WARN No icon.png — drag your 512x512 icon onto COPY-LOGO.bat' -ForegroundColor Yellow
}

Write-Host 'Cleaning old build cache (fixes objective_c hook errors)...' -ForegroundColor Yellow
Invoke-FlutterCleanSafe -FlutterBat $paths.FlutterBat

Write-Host 'Starting Chrome - wait 2-3 minutes...' -ForegroundColor Cyan
Write-Host ''

& $paths.FlutterBat pub get
if ($LASTEXITCODE -ne 0) {
    Read-Host 'Press Enter to close'
    exit $LASTEXITCODE
}

& $paths.FlutterBat run -d chrome `
    --dart-define-from-file=$envFile

$code = $LASTEXITCODE
Write-Host ''
if ($code -ne 0) {
    Write-Host "Launch failed (code $code)" -ForegroundColor Red
} else {
    Write-Host 'Chrome session ended.' -ForegroundColor Green
}
Read-Host 'Press Enter to close'
exit $code
