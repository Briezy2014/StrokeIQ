# Serve swimiq/build/web on 127.0.0.1 and open Chrome when ready.
# ASCII-only. Used by launch-chrome-kara.ps1 for a blank-page-safe path.
param(
    [Parameter(Mandatory = $true)][string]$WebDir,
    [Parameter(Mandatory = $true)][int]$Port,
    [string]$ChromeExe = ''
)

$ErrorActionPreference = 'Continue'
$url = "http://127.0.0.1:$Port/"

if (-not (Test-Path -LiteralPath (Join-Path $WebDir 'index.html'))) {
    Write-Host "[FAIL] Missing index.html in $WebDir" -ForegroundColor Red
    exit 1
}
if (-not (Test-Path -LiteralPath (Join-Path $WebDir 'main.dart.js')) -and
    -not (Test-Path -LiteralPath (Join-Path $WebDir 'flutter_bootstrap.js'))) {
    Write-Host "[FAIL] Web build looks incomplete in $WebDir" -ForegroundColor Red
    exit 1
}

$py = $null
foreach ($c in @('py -3', 'python', 'python3')) {
    try {
        $parts = $c -split ' '
        & $parts[0] $($parts[1]) --version >$null 2>&1
        if ($LASTEXITCODE -eq 0 -or $-) { $py = $c; break }
    } catch {}
}
# Simpler python probe
if (-not $py) {
    if (Get-Command py -ErrorAction SilentlyContinue) { $py = 'py' }
    elseif (Get-Command python -ErrorAction SilentlyContinue) { $py = 'python' }
}

if (-not $py) {
    Write-Host '[FAIL] Python not found to serve the app.' -ForegroundColor Red
    Write-Host "Open this folder in Chrome manually after install: $WebDir" -ForegroundColor Yellow
    exit 1
}

Set-Location -LiteralPath $WebDir
Write-Host "[OK] Serving $WebDir" -ForegroundColor Green
Write-Host "[OK] URL $url" -ForegroundColor Green

if ($py -eq 'py') {
    $serveArgs = @('-3', '-m', 'http.server', "$Port", '--bind', '127.0.0.1')
    $serveExe = 'py'
} else {
    $serveArgs = @('-m', 'http.server', "$Port", '--bind', '127.0.0.1')
    $serveExe = $py
}

$server = Start-Process -FilePath $serveExe -ArgumentList $serveArgs -WorkingDirectory $WebDir -PassThru -WindowStyle Minimized
Start-Sleep -Seconds 2

$ready = $false
for ($i = 0; $i -lt 30; $i++) {
    try {
        $r = Invoke-WebRequest -UseBasicParsing -Uri $url -TimeoutSec 3
        if ($r.StatusCode -eq 200 -and ($r.Content -match 'flutter|SwimIQ')) {
            $ready = $true
            break
        }
    } catch {}
    Start-Sleep -Seconds 1
}

if (-not $ready) {
    Write-Host '[FAIL] Local web server did not respond.' -ForegroundColor Red
    try { Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue } catch {}
    exit 1
}

Write-Host '[OK] App files ready. Opening Chrome...' -ForegroundColor Green
if ($ChromeExe -and (Test-Path -LiteralPath $ChromeExe)) {
    Start-Process -FilePath $ChromeExe -ArgumentList @('--new-window', '--disable-http-cache', $url)
} else {
    Start-Process $url
}

Write-Host ''
Write-Host 'SwimIQ is open. Leave this window running.' -ForegroundColor Yellow
Write-Host 'Close this window to stop the local website server.' -ForegroundColor Yellow
Write-Host ''
try {
    Wait-Process -Id $server.Id
} catch {}
exit 0
