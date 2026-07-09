# Upload ONLY delete-account.html to GoDaddy (no Flutter rebuild needed)
# Use when Play Console needs the data-deletion URL live right away.

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path $PSScriptRoot -Parent
$src = Join-Path $projectRoot "web\delete-account.html"
$outDir = Join-Path $projectRoot "build\legal-upload"
$dest = Join-Path $outDir "delete-account.html"

if (-not (Test-Path $src)) {
    throw "Missing $src — run git pull first."
}

New-Item -ItemType Directory -Force -Path $outDir | Out-Null
Copy-Item $src $dest -Force

Write-Host ""
Write-Host "Ready to upload:" -ForegroundColor Green
Write-Host "  $dest" -ForegroundColor Green
Write-Host ""
Write-Host "GoDaddy → File Manager → public_html → Upload delete-account.html" -ForegroundColor Cyan
Write-Host "Also upload .htaccess from web\.htaccess if /delete-account (no .html) should work." -ForegroundColor Cyan
Write-Host "Test: https://swimiqapp.com/delete-account.html" -ForegroundColor Cyan
Write-Host ""
