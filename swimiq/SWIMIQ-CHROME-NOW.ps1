# SwimIQ - ONE FILE Chrome launcher (Kara Williams / Windows)
# Double-click SWIMIQ-CHROME-NOW.bat or KARA-CLICK-THIS.bat
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'scripts\swimiq-windows-paths.ps1')

Write-Host ''
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ' SwimIQ - Chrome NOW' -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ''

try {
    $paths = Initialize-SwimIqWindowsPaths -ScriptsRoot (Join-Path $PSScriptRoot 'scripts') -CleanDartTool
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host 'Press Enter'; exit 1
}

$envFile = Join-Path $paths.WorkDir '.env'
if (-not (Test-Path -LiteralPath $envFile)) {
    $example = Join-Path $paths.WorkDir '.env.example'
    if (Test-Path -LiteralPath $example) { Copy-Item $example $envFile }
    Write-Host 'Created .env - paste Supabase keys, save, run again.' -ForegroundColor Yellow
    notepad $envFile
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
    Write-Host 'ERROR: .env needs real SUPABASE_URL and SUPABASE_ANON_KEY' -ForegroundColor Red
    notepad $envFile
    Read-Host 'Press Enter'; exit 1
}

Write-Host 'Cleaning old cache (fixes hook errors)...' -ForegroundColor Yellow
Invoke-FlutterCleanSafe -FlutterBat $paths.FlutterBat

Write-Host 'Starting Chrome - wait 2-3 minutes...' -ForegroundColor Cyan
& $paths.FlutterBat pub get
if ($LASTEXITCODE -ne 0) { Read-Host 'Press Enter'; exit $LASTEXITCODE }

& $paths.FlutterBat run -d chrome --dart-define=SUPABASE_URL=$url --dart-define=SUPABASE_ANON_KEY=$key
Read-Host 'Press Enter to close'
exit $LASTEXITCODE
