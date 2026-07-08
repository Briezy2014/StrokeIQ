# SwimIQ one-time Windows path fix (Kara Williams)
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'swimiq-windows-paths.ps1')

Write-Host ''
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ' SwimIQ - Fix Windows Paths (once)' -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ''

try {
    $paths = Initialize-SwimIqWindowsPaths -ScriptsRoot $PSScriptRoot -CleanDartTool
    & $paths.FlutterBat clean 2>$null | Out-Null
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host 'Press Enter to close'
    exit 1
}

Write-Host ''
Write-Host 'DONE. Paths now use C:\SwimIQWork (no spaces, no OneDrive S: drive).' -ForegroundColor Green
Write-Host 'Close VS Code, then double-click KARA-CLICK-THIS.bat' -ForegroundColor Green
Read-Host 'Press Enter to close'
