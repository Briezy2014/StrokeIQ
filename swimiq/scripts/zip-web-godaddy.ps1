# Zip build\web for single-file GoDaddy upload (extract into public_html).
param(
    [string]$WebDir = (Join-Path $PSScriptRoot 'build\web'),
    [string]$ZipPath = (Join-Path $PSScriptRoot 'build\swimiq-web-godaddy.zip')
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path (Join-Path $WebDir 'index.html'))) {
    Write-Host "ERROR: Missing $WebDir\index.html" -ForegroundColor Red
    Write-Host 'Run SWIMIQ-BUILD-GODADDY-NOW.bat first.' -ForegroundColor Yellow
    exit 1
}

if (-not (Test-Path (Join-Path $WebDir 'main.dart.js'))) {
    Write-Host "ERROR: Missing $WebDir\main.dart.js" -ForegroundColor Red
    Write-Host 'Run SWIMIQ-BUILD-GODADDY-NOW.bat first.' -ForegroundColor Yellow
    exit 1
}

$staging = Join-Path $env:TEMP "swimiq-godaddy-zip-$([guid]::NewGuid().ToString('N'))"
New-Item -ItemType Directory -Force -Path $staging | Out-Null

try {
    Copy-Item -Path (Join-Path $WebDir '*') -Destination $staging -Recurse -Force
    if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }
    Compress-Archive -Path (Join-Path $staging '*') -DestinationPath $ZipPath -Force
} finally {
    Remove-Item $staging -Recurse -Force -ErrorAction SilentlyContinue
}

$sizeMb = [math]::Round((Get-Item $ZipPath).Length / 1MB, 1)
Write-Host ''
Write-Host "ZIP READY: $ZipPath ($sizeMb MB)" -ForegroundColor Green
Write-Host 'Upload this ONE file to GoDaddy public_html, then Extract.' -ForegroundColor Green
