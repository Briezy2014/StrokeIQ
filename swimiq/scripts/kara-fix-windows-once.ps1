# SwimIQ one-time Windows path fix (Kara Williams)
$ErrorActionPreference = 'Stop'

try {
    $helpers = Join-Path $PSScriptRoot 'swimiq-windows-paths.ps1'
    if (-not (Test-Path -LiteralPath $helpers)) {
        throw "Missing file: $helpers`nDouble-click RESTORE-SCRIPTS.bat first."
    }

    . $helpers

    Write-Host ''
    Write-Host '========================================' -ForegroundColor Cyan
    Write-Host ' SwimIQ - Fix Windows Paths (once)' -ForegroundColor Cyan
    Write-Host '========================================' -ForegroundColor Cyan
    Write-Host ''

    $paths = Initialize-SwimIqWindowsPaths -ScriptsRoot $PSScriptRoot -CleanDartTool
    Invoke-FlutterCleanSafe -FlutterBat $paths.FlutterBat

    Write-Host ''
    Write-Host 'DONE. Paths now use C:\SwimIQWork (no spaces, no OneDrive S: drive).' -ForegroundColor Green
    Write-Host 'Next: double-click KARA-CLICK-THIS.bat' -ForegroundColor Green
    exit 0
} catch {
    Write-Host ''
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ''
    Write-Host 'If scripts are old: double-click RESTORE-SCRIPTS.bat first.' -ForegroundColor Yellow
    exit 1
}
