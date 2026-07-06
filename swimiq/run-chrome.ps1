# SwimIQ — launch Flutter web in Chrome
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

Write-Host "`nSwimIQ Flutter web launcher" -ForegroundColor Cyan
Write-Host "Folder: $(Get-Location)`n"

flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "`nIf pub get failed and your path contains spaces (e.g. Kara Williams)," -ForegroundColor Yellow
    Write-Host "run scripts\setup-short-path.bat from the swimiq folder, then use drive S:`n" -ForegroundColor Yellow
    exit $LASTEXITCODE
}

flutter run -d chrome
