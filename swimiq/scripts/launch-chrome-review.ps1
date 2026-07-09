# SwimIQ Chrome review — NO git pull (safe while Play upload / merge fixes in progress)
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'swimiq-windows-paths.ps1')

Write-Host ''
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ' SwimIQ - Chrome Review (local copy)' -ForegroundColor Cyan
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
if (-not (Test-Path -LiteralPath $envFile)) {
    Write-Host 'ERROR: Missing .env — copy from .env.example and add Supabase keys.' -ForegroundColor Red
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

if (-not $url -or -not $key -or $url -match 'your-project') {
    Write-Host 'ERROR: Edit .env with real SUPABASE_URL and SUPABASE_ANON_KEY' -ForegroundColor Red
    notepad $envFile
    Read-Host 'Press Enter to close'
    exit 1
}

Write-Host 'Using LOCAL code only (no git pull).' -ForegroundColor Green
Write-Host 'Starting Chrome — first launch may take 2-3 minutes...' -ForegroundColor Cyan
Write-Host ''

Invoke-FlutterCleanSafe -FlutterBat $paths.FlutterBat
& $paths.FlutterBat pub get
if ($LASTEXITCODE -ne 0) { Read-Host 'Press Enter'; exit $LASTEXITCODE }

& $paths.FlutterBat run -d chrome `
    --dart-define-from-file=$envFile

Read-Host 'Press Enter to close'
