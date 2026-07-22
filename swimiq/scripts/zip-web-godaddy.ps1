# Zip build\web for single-file GoDaddy upload (extract into public_html).
# Windows PowerShell 5.x safe: no fancy quotes, no ($var word) inside double quotes.
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

$zipParent = Split-Path $ZipPath -Parent
if (-not (Test-Path -LiteralPath $zipParent)) {
    New-Item -ItemType Directory -Force -Path $zipParent | Out-Null
}
if (Test-Path -LiteralPath $ZipPath) {
    Remove-Item -LiteralPath $ZipPath -Force
}

$staging = Join-Path $env:TEMP ('swimiq-godaddy-zip-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $staging | Out-Null

try {
    Copy-Item -Path (Join-Path $WebDir '*') -Destination $staging -Recurse -Force

    # Prefer .NET zip (more reliable than Compress-Archive on long Flutter trees).
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory(
        $staging,
        $ZipPath,
        [System.IO.Compression.CompressionLevel]::Optimal,
        $false
    )
} catch {
    Write-Host ('WARN: .NET zip failed (' + $_.Exception.Message + '). Trying Compress-Archive...') -ForegroundColor Yellow
    if (Test-Path -LiteralPath $ZipPath) {
        Remove-Item -LiteralPath $ZipPath -Force -ErrorAction SilentlyContinue
    }
    Compress-Archive -Path (Join-Path $staging '*') -DestinationPath $ZipPath -Force
} finally {
    Remove-Item -LiteralPath $staging -Recurse -Force -ErrorAction SilentlyContinue
}

if (-not (Test-Path -LiteralPath $ZipPath)) {
    Write-Host 'ERROR: Zip file was not created.' -ForegroundColor Red
    exit 1
}

$bytes = (Get-Item -LiteralPath $ZipPath).Length
$sizeMb = [math]::Round($bytes / 1MB, 1)
Write-Host ''
Write-Host ('ZIP READY: ' + $ZipPath) -ForegroundColor Green
Write-Host ('ZIP SIZE: ' + $sizeMb + ' MB') -ForegroundColor Green
Write-Host 'GoDaddy: public_html -> Upload this ONE zip -> Extract -> overwrite -> hard refresh.' -ForegroundColor Green
$marker = Join-Path $WebDir 'SWIMIQ-FLUTTER-BUILD.txt'
if (Test-Path -LiteralPath $marker) {
    Write-Host '[OK] Zip contains Flutter marker SWIMIQ-FLUTTER-BUILD.txt' -ForegroundColor Green
}
exit 0
