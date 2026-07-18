# Zip build\web for single-file GoDaddy upload (extract into public_html).
# ASCII-only strings — Windows PowerShell 5.x breaks on fancy quotes / ($sizeMb MB).
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

$indexPath = Join-Path $WebDir 'index.html'
$mainJsPath = Join-Path $WebDir 'main.dart.js'

if (-not (Test-Path -LiteralPath $indexPath)) {
    Write-Host ('ERROR: Missing ' + $indexPath) -ForegroundColor Red
    Write-Host 'Run PUBLISH-SWIMIQAPP-COM.bat first.' -ForegroundColor Yellow
    exit 1
}

if (-not (Test-Path -LiteralPath $mainJsPath)) {
    Write-Host ('ERROR: Missing ' + $mainJsPath) -ForegroundColor Red
    Write-Host 'That means this is NOT the Flutter app. Do not upload website\ alone.' -ForegroundColor Yellow
    exit 1
}

$staging = Join-Path $env:TEMP ('swimiq-godaddy-zip-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $staging | Out-Null

try {
    Copy-Item -Path (Join-Path $WebDir '*') -Destination $staging -Recurse -Force
    $zipParent = Split-Path $ZipPath -Parent
    if (-not (Test-Path -LiteralPath $zipParent)) {
        New-Item -ItemType Directory -Force -Path $zipParent | Out-Null
    }
    if (Test-Path -LiteralPath $ZipPath) {
        Remove-Item -LiteralPath $ZipPath -Force
    }
    Compress-Archive -Path (Join-Path $staging '*') -DestinationPath $ZipPath -Force
} finally {
    Remove-Item -LiteralPath $staging -Recurse -Force -ErrorAction SilentlyContinue
}

if (-not (Test-Path -LiteralPath $ZipPath)) {
    Write-Host 'ERROR: Zip file was not created.' -ForegroundColor Red
    exit 1
}

$sizeMb = [math]::Round((Get-Item -LiteralPath $ZipPath).Length / 1MB, 1)
Write-Host ''
Write-Host ('ZIP READY: ' + $ZipPath + ' (' + $sizeMb + ' MB)') -ForegroundColor Green
Write-Host 'GoDaddy: public_html -> Upload this ONE zip -> Extract -> overwrite -> hard refresh.' -ForegroundColor Green
$marker = Join-Path $WebDir 'SWIMIQ-FLUTTER-BUILD.txt'
if (Test-Path -LiteralPath $marker) {
    Write-Host '[OK] Zip contains Flutter marker SWIMIQ-FLUTTER-BUILD.txt' -ForegroundColor Green
}
exit 0
