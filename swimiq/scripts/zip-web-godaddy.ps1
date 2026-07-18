# Zip build\web for single-file GoDaddy upload (extract into public_html).
param(
    [string]$WebDir = '',
    [string]$ZipPath = ''
)

$ErrorActionPreference = 'Stop'

$swimiqRoot = Split-Path $PSScriptRoot -Parent
if ([string]::IsNullOrWhiteSpace($WebDir)) {
    $WebDir = Join-Path $swimiqRoot 'build\web'
}
if ([string]::IsNullOrWhiteSpace($ZipPath)) {
    $ZipPath = Join-Path $swimiqRoot 'build\swimiq-web-godaddy.zip'
}

if (-not (Test-Path (Join-Path $WebDir 'index.html'))) {
    Write-Host "ERROR: Missing $WebDir\index.html" -ForegroundColor Red
    Write-Host 'Run PUBLISH-SWIMIQAPP-COM.bat (or SWIMIQ-BUILD-GODADDY-NOW.bat) first.' -ForegroundColor Yellow
    exit 1
}

if (-not (Test-Path (Join-Path $WebDir 'main.dart.js'))) {
    Write-Host "ERROR: Missing $WebDir\main.dart.js — that means this is NOT the Flutter app." -ForegroundColor Red
    Write-Host 'Do not upload swimiq\website\ to GoDaddy. Build Flutter web first.' -ForegroundColor Yellow
    exit 1
}

$staging = Join-Path $env:TEMP "swimiq-godaddy-zip-$([guid]::NewGuid().ToString('N'))"
New-Item -ItemType Directory -Force -Path $staging | Out-Null

try {
    Copy-Item -Path (Join-Path $WebDir '*') -Destination $staging -Recurse -Force
    $zipParent = Split-Path $ZipPath -Parent
    if (-not (Test-Path $zipParent)) {
        New-Item -ItemType Directory -Force -Path $zipParent | Out-Null
    }
    if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }
    Compress-Archive -Path (Join-Path $staging '*') -DestinationPath $ZipPath -Force
} finally {
    Remove-Item $staging -Recurse -Force -ErrorAction SilentlyContinue
}

$sizeMb = [math]::Round((Get-Item $ZipPath).Length / 1MB, 1)
Write-Host ''
Write-Host "ZIP READY: $ZipPath ($sizeMb MB)" -ForegroundColor Green
Write-Host 'GoDaddy: public_html → Upload this ONE zip → Extract → overwrite → hard refresh.' -ForegroundColor Green
if (Test-Path (Join-Path $WebDir 'SWIMIQ-FLUTTER-BUILD.txt')) {
    Write-Host '[OK] Zip contains Flutter marker SWIMIQ-FLUTTER-BUILD.txt' -ForegroundColor Green
}
