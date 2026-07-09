# SwimIQ Chrome launcher (Kara Williams / OneDrive / spaces / objective_c hooks)
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'swimiq-windows-paths.ps1')

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

Write-Host 'Pulling latest SwimIQ code from GitHub...' -ForegroundColor Yellow
Push-Location $paths.WorkDir
try {
    git fetch origin cursor/windows-chrome-spaces-fix-17e8 2>$null
    git checkout cursor/windows-chrome-spaces-fix-17e8 2>$null
    git pull origin cursor/windows-chrome-spaces-fix-17e8 2>$null
    Write-Host '[OK] Code updated.' -ForegroundColor Green
} catch {
    Write-Host '[WARN] Git pull skipped — using local copy.' -ForegroundColor Yellow
} finally {
    Pop-Location
}

Write-Host 'Checking branding PNG...' -ForegroundColor Cyan
$brandDir = Join-Path $paths.WorkDir 'assets\branding'
$logo = Join-Path $brandDir 'swimiq_logo.png'
$icon = Join-Path $brandDir 'swimiq_icon.png'
if (Test-Path -LiteralPath $logo) {
    Write-Host "OK  Using assets\branding\swimiq_logo.png" -ForegroundColor Green
} elseif (Test-Path -LiteralPath $icon) {
    Write-Host 'WARN Only swimiq_icon.png found — drag NEW logo onto SYNC-LOGO-NOW.bat' -ForegroundColor Yellow
} else {
    Write-Host 'WARN No logo PNG — drag 512x512 onto SYNC-LOGO-NOW.bat' -ForegroundColor Yellow
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
