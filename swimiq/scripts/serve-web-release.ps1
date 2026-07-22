# Serve Flutter build and open a browser. Server runs in a SEPARATE window.
# Closing this script must NOT kill the website server.
param(
    [Parameter(Mandatory = $true)][string]$WebDir,
    [Parameter(Mandatory = $true)][int]$Port,
    [string]$ChromeExe = ''
)

$ErrorActionPreference = 'Continue'
$url = "http://127.0.0.1:$Port/"
$startServer = Join-Path $PSScriptRoot 'start-web-server-window.ps1'

if (-not (Test-Path -LiteralPath (Join-Path $WebDir 'index.html'))) {
    Write-Host "[FAIL] Missing index.html in $WebDir" -ForegroundColor Red
    exit 1
}
if (-not (Test-Path -LiteralPath (Join-Path $WebDir 'main.dart.js')) -and
    -not (Test-Path -LiteralPath (Join-Path $WebDir 'flutter_bootstrap.js'))) {
    Write-Host "[FAIL] Web build incomplete in $WebDir" -ForegroundColor Red
    exit 1
}

Write-Host 'Starting SwimIQ web server in its own window...' -ForegroundColor Cyan
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $startServer -WebDir $WebDir -Port $Port
if ($LASTEXITCODE -ne 0) {
    Write-Host '[FAIL] Could not start web server.' -ForegroundColor Red
    exit 1
}

function Open-SwimIqBrowser([string]$TargetUrl, [string]$PreferredChrome) {
    $chromeCandidates = @()
    if ($PreferredChrome) { $chromeCandidates += $PreferredChrome }
    $chromeCandidates += @(
        "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe",
        "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
        "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
    )
    foreach ($exe in $chromeCandidates) {
        if ($exe -and (Test-Path -LiteralPath $exe)) {
            try {
                Start-Process -FilePath $exe -ArgumentList @(
                    '--new-window', '--disable-http-cache', $TargetUrl
                ) -ErrorAction Stop
                Write-Host "[OK] Opened Chrome" -ForegroundColor Green
                return $true
            } catch {}
        }
    }
    foreach ($exe in @(
        "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
        "${env:ProgramFiles}\Microsoft\Edge\Application\msedge.exe"
    )) {
        if (Test-Path -LiteralPath $exe) {
            try {
                Start-Process -FilePath $exe -ArgumentList @('--new-window', $TargetUrl) -ErrorAction Stop
                Write-Host '[OK] Opened Edge' -ForegroundColor Green
                return $true
            } catch {}
        }
    }
    try {
        cmd.exe /c start "" "$TargetUrl"
        Write-Host '[OK] Opened default browser' -ForegroundColor Green
        return $true
    } catch {
        return $false
    }
}

Write-Host ''
Write-Host '############################################' -ForegroundColor Cyan
Write-Host ' OPENING BROWSER' -ForegroundColor Cyan
Write-Host " $url" -ForegroundColor White
Write-Host '############################################' -ForegroundColor Cyan
Write-Host ''

if (-not (Open-SwimIqBrowser -TargetUrl $url -PreferredChrome $ChromeExe)) {
    Write-Host '[WARN] Auto-open failed. Paste this into your browser:' -ForegroundColor Yellow
    Write-Host "  $url" -ForegroundColor White
}

$openBat = Join-Path (Split-Path $WebDir -Parent | Split-Path -Parent) 'OPEN-SWIMIQ-NOW.bat'
# Prefer repo-root opener if present; always write build-local opener too.
$localOpen = Join-Path $WebDir 'OPEN-SWIMIQ-IN-BROWSER.bat'
@(
    '@echo off',
    "start `"`" `"$url`"",
    'exit /b 0'
) | Set-Content -LiteralPath $localOpen -Encoding ascii

Write-Host ''
Write-Host 'IMPORTANT:' -ForegroundColor Yellow
Write-Host '  Keep the window titled:' -ForegroundColor Yellow
Write-Host '    SwimIQ WEB SERVER - DO NOT CLOSE' -ForegroundColor White
Write-Host '  If you close that window, the browser will say' -ForegroundColor Yellow
Write-Host '  "refused to connect".' -ForegroundColor Yellow
Write-Host ''
Write-Host "Backup open: $localOpen" -ForegroundColor Green
Write-Host "URL: $url" -ForegroundColor Green
Write-Host ''
# Do NOT Wait-Process on the server - it lives in its own window.
exit 0
