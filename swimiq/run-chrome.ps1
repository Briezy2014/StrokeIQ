# SwimIQ — launch Flutter web in Chrome (handles Kara Williams / spaces / hooks)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$helpers = Join-Path $PSScriptRoot 'scripts\swimiq-windows-paths.ps1'
if (-not (Test-Path -LiteralPath $helpers)) {
    Write-Host "Missing $helpers" -ForegroundColor Red
    Write-Host 'Run FIX-KARA-PATHS.bat once, or see docs\WINDOWS_SETUP.md' -ForegroundColor Yellow
    exit 1
}

. $helpers

Write-Host "`nSwimIQ Flutter web launcher" -ForegroundColor Cyan

try {
    $paths = Initialize-SwimIqWindowsPaths -ScriptsRoot (Join-Path $PSScriptRoot 'scripts') -CleanDartTool
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host 'Run FIX-KARA-PATHS.bat once, then try again.' -ForegroundColor Yellow
    exit 1
}

Invoke-FlutterCleanSafe -FlutterBat $paths.FlutterBat

& $paths.FlutterBat pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& $paths.FlutterBat run -d chrome
exit $LASTEXITCODE
