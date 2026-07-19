# Serve swimiq/build/web on 127.0.0.1 and open Chrome when ready.
# ASCII-only. Used by launch-chrome-kara.ps1.
# Uses no-cache headers so Chrome does not stick on a blank/white stale load.
param(
    [Parameter(Mandatory = $true)][string]$WebDir,
    [Parameter(Mandatory = $true)][int]$Port,
    [string]$ChromeExe = ''
)

$ErrorActionPreference = 'Continue'
$url = "http://127.0.0.1:$Port/"
$scriptDir = $PSScriptRoot
$pyServe = Join-Path $scriptDir 'serve_web_nocache.py'

if (-not (Test-Path -LiteralPath (Join-Path $WebDir 'index.html'))) {
    Write-Host "[FAIL] Missing index.html in $WebDir" -ForegroundColor Red
    exit 1
}
if (-not (Test-Path -LiteralPath (Join-Path $WebDir 'main.dart.js')) -and
    -not (Test-Path -LiteralPath (Join-Path $WebDir 'flutter_bootstrap.js'))) {
    Write-Host "[FAIL] Web build looks incomplete in $WebDir" -ForegroundColor Red
    exit 1
}

# Free the port if a zombie server is still holding it.
try {
    $owners = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty OwningProcess -Unique
    foreach ($procId in $owners) {
        if ($procId -and $procId -ne 0) {
            Write-Host "[OK] Stopping old process on port $Port (PID $procId)" -ForegroundColor Yellow
            Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue
        }
    }
} catch {}
Start-Sleep -Seconds 1

$serveExe = $null
$serveArgs = @()
$workDir = $WebDir
$useNoCache = $false

if (Test-Path -LiteralPath $pyServe) {
    if (Get-Command py -ErrorAction SilentlyContinue) {
        $serveExe = 'py'
        $serveArgs = @('-3', $pyServe, $WebDir, "$Port")
        $workDir = $scriptDir
        $useNoCache = $true
    } elseif (Get-Command python -ErrorAction SilentlyContinue) {
        $serveExe = 'python'
        $serveArgs = @($pyServe, $WebDir, "$Port")
        $workDir = $scriptDir
        $useNoCache = $true
    }
}

if (-not $serveExe) {
    if (Get-Command py -ErrorAction SilentlyContinue) {
        $serveExe = 'py'
        $serveArgs = @('-3', '-m', 'http.server', "$Port", '--bind', '127.0.0.1')
        $workDir = $WebDir
    } elseif (Get-Command python -ErrorAction SilentlyContinue) {
        $serveExe = 'python'
        $serveArgs = @('-m', 'http.server', "$Port", '--bind', '127.0.0.1')
        $workDir = $WebDir
    } else {
        Write-Host '[FAIL] Python not found to serve the app.' -ForegroundColor Red
        Write-Host "Open this folder in Chrome manually: $WebDir" -ForegroundColor Yellow
        exit 1
    }
}

if ($useNoCache) {
    Write-Host '[OK] Using no-cache web server (helps prevent white screen)' -ForegroundColor Green
}
Write-Host "[OK] Serving $WebDir" -ForegroundColor Green
Write-Host "[OK] URL $url" -ForegroundColor Green

$server = Start-Process -FilePath $serveExe -ArgumentList $serveArgs -WorkingDirectory $workDir -PassThru -WindowStyle Minimized
Start-Sleep -Seconds 2

$ready = $false
for ($i = 0; $i -lt 45; $i++) {
    try {
        $r = Invoke-WebRequest -UseBasicParsing -Uri $url -TimeoutSec 3
        if ($r.StatusCode -eq 200 -and ($r.Content -match 'flutter|SwimIQ|swimiq-boot')) {
            $jsOk = $false
            try {
                $js = Invoke-WebRequest -UseBasicParsing -Uri ($url + 'main.dart.js') -TimeoutSec 8
                if ($js.StatusCode -eq 200 -and $js.RawContentLength -gt 10000) { $jsOk = $true }
            } catch {}
            if (-not $jsOk) {
                try {
                    $boot = Invoke-WebRequest -UseBasicParsing -Uri ($url + 'flutter_bootstrap.js') -TimeoutSec 5
                    if ($boot.StatusCode -eq 200 -and $boot.RawContentLength -gt 200) { $jsOk = $true }
                } catch {}
            }
            if ($jsOk) {
                $ready = $true
                break
            }
        }
    } catch {}
    Start-Sleep -Seconds 1
}

if (-not $ready) {
    Write-Host '[FAIL] Local web server did not serve a complete app.' -ForegroundColor Red
    try { Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue } catch {}
    exit 1
}

Write-Host '[OK] App files ready. Opening Chrome...' -ForegroundColor Green
$chromeArgs = @(
    '--new-window',
    '--disable-http-cache',
    '--disk-cache-size=1',
    '--disable-application-cache',
    $url
)
if ($ChromeExe -and (Test-Path -LiteralPath $ChromeExe)) {
    Start-Process -FilePath $ChromeExe -ArgumentList $chromeArgs
} else {
    Start-Process $url
}

Write-Host ''
Write-Host 'SwimIQ is open. Leave this window running.' -ForegroundColor Yellow
Write-Host 'You should see a blue SwimIQ loading screen first - not a blank white page.' -ForegroundColor Yellow
Write-Host 'If it sticks on loading: Ctrl+Shift+R, or close Chrome and relaunch.' -ForegroundColor Yellow
Write-Host 'Close this window to stop the local website server.' -ForegroundColor Yellow
Write-Host ''
try {
    Wait-Process -Id $server.Id
} catch {}
exit 0
