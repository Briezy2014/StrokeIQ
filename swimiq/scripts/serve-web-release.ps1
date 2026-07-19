# Serve swimiq/build/web on 127.0.0.1 and open Chrome when ready.
# ASCII-only. Used by launch-chrome-kara.ps1.
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
    } elseif (Get-Command python -ErrorAction SilentlyContinue) {
        $serveExe = 'python'
        $serveArgs = @('-m', 'http.server', "$Port", '--bind', '127.0.0.1')
    } else {
        Write-Host '[FAIL] Python not found to serve the app.' -ForegroundColor Red
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
for ($i = 0; $i -lt 30; $i++) {
    try {
        $r = Invoke-WebRequest -UseBasicParsing -Uri $url -TimeoutSec 3
        if ($r.StatusCode -eq 200 -and ($r.Content -match 'flutter|SwimIQ|swimiq-boot')) {
            $ready = $true
            break
        }
    } catch {}
    Start-Sleep -Seconds 1
}

if (-not $ready) {
    Write-Host '[WARN] Health check slow - opening browser anyway.' -ForegroundColor Yellow
}

function Open-SwimIqBrowser([string]$TargetUrl, [string]$PreferredChrome) {
    $opened = $false

    $chromeCandidates = @()
    if ($PreferredChrome) { $chromeCandidates += $PreferredChrome }
    $chromeCandidates += @(
        "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe",
        "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
        "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
    )

    foreach ($exe in $chromeCandidates) {
        if (-not $exe) { continue }
        if (-not (Test-Path -LiteralPath $exe)) { continue }
        try {
            Start-Process -FilePath $exe -ArgumentList @(
                '--new-window',
                '--disable-http-cache',
                '--disk-cache-size=1',
                $TargetUrl
            ) -ErrorAction Stop
            Write-Host "[OK] Opened Chrome: $exe" -ForegroundColor Green
            return $true
        } catch {
            Write-Host "[WARN] Chrome launch failed: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }

    $edge = @(
        "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
        "${env:ProgramFiles}\Microsoft\Edge\Application\msedge.exe"
    )
    foreach ($exe in $edge) {
        if (-not (Test-Path -LiteralPath $exe)) { continue }
        try {
            Start-Process -FilePath $exe -ArgumentList @('--new-window', $TargetUrl) -ErrorAction Stop
            Write-Host "[OK] Opened Edge: $exe" -ForegroundColor Green
            return $true
        } catch {}
    }

    try {
        Start-Process $TargetUrl -ErrorAction Stop
        Write-Host '[OK] Opened default browser via Start-Process' -ForegroundColor Green
        $opened = $true
    } catch {}

    if (-not $opened) {
        try {
            cmd.exe /c start "" "$TargetUrl"
            Write-Host '[OK] Opened browser via cmd start' -ForegroundColor Green
            $opened = $true
        } catch {}
    }

    return $opened
}

Write-Host ''
Write-Host '############################################' -ForegroundColor Cyan
Write-Host ' OPENING BROWSER NOW' -ForegroundColor Cyan
Write-Host " $url" -ForegroundColor White
Write-Host '############################################' -ForegroundColor Cyan
Write-Host ''

$browserOk = Open-SwimIqBrowser -TargetUrl $url -PreferredChrome $ChromeExe
if (-not $browserOk) {
    Write-Host '[FAIL] Could not auto-open a browser.' -ForegroundColor Red
}

# Always leave a one-click opener next to the build for Kara.
$openBat = Join-Path $WebDir 'OPEN-SWIMIQ-IN-BROWSER.bat'
@(
    '@echo off',
    "start `"`" `"$url`"",
    'exit /b 0'
) | Set-Content -LiteralPath $openBat -Encoding ascii
Write-Host "[OK] Backup opener: $openBat" -ForegroundColor Green
Write-Host 'If no window appeared: double-click OPEN-SWIMIQ-IN-BROWSER.bat' -ForegroundColor Yellow
Write-Host 'Or paste this into Chrome address bar:' -ForegroundColor Yellow
Write-Host "  $url" -ForegroundColor White
Write-Host ''
Write-Host 'Leave THIS window running (it is the website server).' -ForegroundColor Yellow
Write-Host 'Expect a blue SwimIQ loading screen first.' -ForegroundColor Yellow
Write-Host ''

try {
    Wait-Process -Id $server.Id
} catch {}
exit 0
