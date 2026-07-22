# Start SwimIQ Flutter web server in its OWN window that must stay open.
# ASCII-only.
param(
    [Parameter(Mandatory = $true)][string]$WebDir,
    [Parameter(Mandatory = $true)][int]$Port
)

$ErrorActionPreference = 'Continue'
$scriptDir = $PSScriptRoot
$pyServe = Join-Path $scriptDir 'serve_web_nocache.py'
$url = "http://127.0.0.1:$Port/"

if (-not (Test-Path -LiteralPath (Join-Path $WebDir 'index.html'))) {
    Write-Host "[FAIL] Missing index.html in $WebDir" -ForegroundColor Red
    exit 1
}

try {
    $listening = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
    if ($listening) {
        try {
            $probe = Invoke-WebRequest -UseBasicParsing -Uri $url -TimeoutSec 3
            if ($probe.StatusCode -eq 200) {
                Write-Host "[OK] Port $Port already serving $url" -ForegroundColor Green
                exit 0
            }
        } catch {}
    }
} catch {}

$pyCmd = $null
$pyPrefix = @()
if (Get-Command py -ErrorAction SilentlyContinue) {
    $pyCmd = 'py'
    $pyPrefix = @('-3')
} elseif (Get-Command python -ErrorAction SilentlyContinue) {
    $pyCmd = 'python'
    $pyPrefix = @()
} else {
    Write-Host '[FAIL] Python not found. Install Python, then try again.' -ForegroundColor Red
    exit 1
}

$runner = Join-Path $env:TEMP ("swimiq-web-server-{0}.cmd" -f $Port)
if (Test-Path -LiteralPath $pyServe) {
    $lines = @(
        '@echo off',
        'title SwimIQ WEB SERVER - DO NOT CLOSE',
        "cd /d `"$scriptDir`"",
        'echo.',
        'echo ============================================',
        'echo   SwimIQ WEB SERVER',
        'echo   DO NOT CLOSE THIS WINDOW',
        "echo   URL: $url",
        'echo ============================================',
        'echo.',
        ($pyCmd + ' ' + (($pyPrefix + @('"' + $pyServe + '"', '"' + $WebDir + '"', "$Port")) -join ' ')),
        'echo.',
        'echo Server stopped. Closing this kills SwimIQ in the browser.',
        'pause'
    )
} else {
    $lines = @(
        '@echo off',
        'title SwimIQ WEB SERVER - DO NOT CLOSE',
        "cd /d `"$WebDir`"",
        'echo.',
        'echo ============================================',
        'echo   SwimIQ WEB SERVER',
        'echo   DO NOT CLOSE THIS WINDOW',
        "echo   URL: $url",
        'echo ============================================',
        'echo.',
        ($pyCmd + ' ' + (($pyPrefix + @('-m', 'http.server', "$Port", '--bind', '127.0.0.1')) -join ' ')),
        'echo.',
        'echo Server stopped. Closing this kills SwimIQ in the browser.',
        'pause'
    )
}

Set-Content -LiteralPath $runner -Value $lines -Encoding ascii
Start-Process -FilePath $runner | Out-Null

$ready = $false
for ($i = 0; $i -lt 45; $i++) {
    Start-Sleep -Seconds 1
    try {
        $r = Invoke-WebRequest -UseBasicParsing -Uri $url -TimeoutSec 2
        if ($r.StatusCode -eq 200) {
            $ready = $true
            break
        }
    } catch {}
}

if (-not $ready) {
    Write-Host "[FAIL] Web server did not answer at $url" -ForegroundColor Red
    Write-Host 'Look for a window titled: SwimIQ WEB SERVER - DO NOT CLOSE' -ForegroundColor Yellow
    exit 1
}

Write-Host "[OK] Web server running at $url" -ForegroundColor Green
Write-Host 'Leave "SwimIQ WEB SERVER - DO NOT CLOSE" open.' -ForegroundColor Yellow
exit 0
