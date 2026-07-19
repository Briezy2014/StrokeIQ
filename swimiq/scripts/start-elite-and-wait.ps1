# Starts a FRESH Elite analysis server and waits until /health is fully ready.
# ASCII-only. Windows PowerShell 5.1 misreads UTF-8 dashes/ellipsis.
# Usage:
#   start-elite-and-wait.ps1              # start if needed
#   start-elite-and-wait.ps1 -CheckOnly   # never kill/restart; ping health only
#   start-elite-and-wait.ps1 -ForceRestart
param(
    [switch]$CheckOnly,
    [switch]$ForceRestart
)

$ErrorActionPreference = 'Continue'

$ApiBase = 'http://127.0.0.1:8080'
$HealthUrl = "$ApiBase/health"
$SwimIqDir = Split-Path $PSScriptRoot -Parent
$RepoRoot = Split-Path $SwimIqDir -Parent
$EliteBat = Join-Path $SwimIqDir 'START-ELITE-ANALYSIS-SERVER.bat'
$KillScript = Join-Path $PSScriptRoot 'kill-elite-port.ps1'
$EnsureScript = Join-Path $PSScriptRoot 'ensure-elite-local-env.ps1'
$VideoDir = Join-Path $RepoRoot 'services\video_analysis'
$FlutterEnv = Join-Path $SwimIqDir '.env'
$EliteEnv = Join-Path $VideoDir '.env'

function Get-EliteHealthBody {
    try {
        $r = Invoke-WebRequest -UseBasicParsing -Uri $HealthUrl -TimeoutSec 3
        if ($r.StatusCode -ne 200) { return $null }
        return $r.Content
    } catch {
        return $null
    }
}

function Test-EliteFullyReady([string]$body) {
    if ([string]::IsNullOrWhiteSpace($body)) { return $false }
    if ($body -notmatch 'engine_version') { return $false }
    if ($body -notmatch '"ffmpeg_available"\s*:\s*true') { return $false }
    if ($body -notmatch '"ffprobe_available"\s*:\s*true') { return $false }
    if ($body -notmatch '"storage_download_configured"\s*:\s*true') { return $false }
    return $true
}

function Get-EnvValue([string]$path, [string]$key) {
    if (-not (Test-Path -LiteralPath $path)) { return '' }
    $line = Get-Content -LiteralPath $path |
        Where-Object { $_ -match ("^\s*" + [regex]::Escape($key) + "\s*=") } |
        Select-Object -Last 1
    if (-not $line) { return '' }
    $v = ($line -replace ("^\s*" + [regex]::Escape($key) + "\s*="), '').Trim().Trim('"').Trim("'")
    if ($v.Contains('#')) {
        $v = ($v -split '#', 2)[0].Trim()
    }
    return $v
}

function Test-GeminiNeedsRestart {
    $flutterKey = Get-EnvValue $FlutterEnv 'GEMINI_API_KEY'
    $eliteKey = Get-EnvValue $EliteEnv 'GEMINI_API_KEY'
    if ([string]::IsNullOrWhiteSpace($flutterKey)) { return $false }
    if ($flutterKey -ne $eliteKey) { return $true }
    return $false
}

function Refresh-PathFromRegistry {
    $sys = ''
    $usr = ''
    try {
        $sys = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' -Name Path -ErrorAction SilentlyContinue).Path
    } catch {}
    try {
        $usr = (Get-ItemProperty -Path 'HKCU:\Environment' -Name Path -ErrorAction SilentlyContinue).Path
    } catch {}
    $parts = @()
    if ($sys) { $parts += $sys }
    if ($usr) { $parts += $usr }
    $wingetLinks = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links'
    if (Test-Path $wingetLinks) { $parts = @($wingetLinks) + $parts }
    $ffmpegBin = Join-Path $env:ProgramFiles 'ffmpeg\bin'
    if (Test-Path $ffmpegBin) { $parts = @($ffmpegBin) + $parts }
    $gyanBin = Join-Path $env:ProgramFiles 'Gyan\FFmpeg\bin'
    if (Test-Path $gyanBin) { $parts = @($gyanBin) + $parts }
    if ($parts.Count -gt 0) {
        $env:Path = ($parts -join ';')
    }
}

function Test-CommandOnPath([string]$name) {
    try {
        $cmd = Get-Command $name -ErrorAction SilentlyContinue
        return ($null -ne $cmd)
    } catch {
        return $false
    }
}

function Write-PartialHealthHint([string]$body) {
    if (-not $body) {
        Write-Host '  /health: no response yet' -ForegroundColor Yellow
        return
    }
    if ($body -match '"ffmpeg_available"\s*:\s*true') {
        Write-Host '  ffmpeg: OK' -ForegroundColor Green
    } else {
        Write-Host '  ffmpeg: MISSING - install FFmpeg, then run START-SWIMIQ-WITH-ELITE.bat again' -ForegroundColor Red
    }
    if ($body -match '"ffprobe_available"\s*:\s*true') {
        Write-Host '  ffprobe: OK' -ForegroundColor Green
    } else {
        Write-Host '  ffprobe: MISSING' -ForegroundColor Red
    }
    if ($body -match '"storage_download_configured"\s*:\s*true') {
        Write-Host '  storage keys: OK' -ForegroundColor Green
    } else {
        Write-Host '  storage keys: MISSING - put SUPABASE_URL + SUPABASE_ANON_KEY in swimiq\.env' -ForegroundColor Red
    }
}

Write-Host ''
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ' Elite analysis server check' -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
Write-Host "Health URL: $HealthUrl"
if ($CheckOnly) { Write-Host 'Mode: CheckOnly (will not restart Elite)' -ForegroundColor Yellow }
Write-Host ''

Refresh-PathFromRegistry

if (-not (Test-Path -LiteralPath $VideoDir)) {
    Write-Host "[FAIL] Missing video analysis folder:" -ForegroundColor Red
    Write-Host "       $VideoDir" -ForegroundColor Red
    Write-Host 'Run GET-LATEST-FIXED-APP.bat inside Desktop\StrokeIQ, then try again.' -ForegroundColor Yellow
    exit 1
}

$body = Get-EliteHealthBody
$needsKeyRestart = Test-GeminiNeedsRestart

if ($CheckOnly) {
    if (Test-EliteFullyReady $body) {
        Write-Host '[OK] Elite server already fully ready (ffmpeg + storage).' -ForegroundColor Green
        Write-Host $body
        exit 0
    }
    Write-Host '[FAIL] Elite is not fully ready (CheckOnly - not restarting).' -ForegroundColor Red
    Write-PartialHealthHint $body
    if ($body) { Write-Host $body }
    exit 1
}

if ((Test-EliteFullyReady $body) -and (-not $ForceRestart) -and (-not $needsKeyRestart)) {
    Write-Host '[OK] Elite server already fully ready (ffmpeg + storage).' -ForegroundColor Green
    Write-Host $body
    exit 0
}

if ($needsKeyRestart -and (Test-EliteFullyReady $body)) {
    Write-Host '[WARN] GEMINI_API_KEY in swimiq\.env differs from Elite .env - restarting Elite to load it.' -ForegroundColor Yellow
}

# Fail fast on FFmpeg so we do not wait 7 minutes for a known miss.
$hasFfmpeg = Test-CommandOnPath 'ffmpeg'
$hasFfprobe = Test-CommandOnPath 'ffprobe'
if (-not $hasFfmpeg -or -not $hasFfprobe) {
    Write-Host '[FAIL] FFmpeg is not on PATH yet (needed for Elite analysis).' -ForegroundColor Red
    if (-not $hasFfmpeg) { Write-Host '       Missing: ffmpeg' -ForegroundColor Yellow }
    if (-not $hasFfprobe) { Write-Host '       Missing: ffprobe' -ForegroundColor Yellow }
    Write-Host ''
    Write-Host 'Install once (Windows):' -ForegroundColor Cyan
    Write-Host '  winget install Gyan.FFmpeg' -ForegroundColor White
    Write-Host 'Then CLOSE this window and run START-SWIMIQ-WITH-ELITE.bat again.' -ForegroundColor Yellow
    Write-Host 'Or double-click RESTART-ELITE-AFTER-FFMPEG.bat after install.' -ForegroundColor Yellow
    exit 3
}
Write-Host '[OK] ffmpeg + ffprobe found on PATH.' -ForegroundColor Green

if ($body -and -not (Test-EliteFullyReady $body)) {
    Write-Host '[WARN] Something is on :8080 but it is NOT fully ready (likely OLD Elite code).' -ForegroundColor Yellow
    Write-PartialHealthHint $body
    Write-Host 'Killing it and starting a fresh Elite server...' -ForegroundColor Yellow
} elseif (-not $body) {
    Write-Host 'Elite server not running. Starting a fresh one...' -ForegroundColor Yellow
}

# Refresh Elite .env from Flutter before start (keys, intervals, etc.).
if (-not (Test-Path -LiteralPath $EnsureScript)) {
    Write-Host "[FAIL] Missing $EnsureScript" -ForegroundColor Red
    exit 1
}
Write-Host 'Refreshing services\video_analysis\.env from swimiq\.env ...' -ForegroundColor Cyan
# Nested powershell -File so "exit" inside ensure does not kill this parent script.
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $EnsureScript $VideoDir
$ensureCode = $LASTEXITCODE
if ($ensureCode -ne 0) {
    Write-Host "[FAIL] ensure-elite-local-env.ps1 exited with code $ensureCode" -ForegroundColor Red
    if ($ensureCode -eq 2) {
        Write-Host 'Elite .env still missing Supabase URL/anon key after edit.' -ForegroundColor Red
        Write-Host 'Put them in Desktop\StrokeIQ\swimiq\.env then run START-SWIMIQ-WITH-ELITE.bat once.' -ForegroundColor Yellow
    }
    exit $ensureCode
}

if (Test-Path -LiteralPath $KillScript) {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $KillScript
    if ($LASTEXITCODE -ne 0) {
        Write-Host '[FAIL] Could not free port 8080. Close any other Elite window, then retry.' -ForegroundColor Red
        exit 1
    }
}

if (-not (Test-Path -LiteralPath $EliteBat)) {
    Write-Host "[FAIL] Missing $EliteBat" -ForegroundColor Red
    exit 1
}

Write-Host ''
Write-Host '>>> Opening Elite black window. DO NOT CLOSE IT. <<<' -ForegroundColor Yellow
# Child Elite bat must NOT kill port 8080 again (that fought the new server).
$env:SWIMIQ_SKIP_PORT_KILL = '1'
# Start the .bat directly so paths with spaces (Kara Williams / OneDrive) work on PS 5.1.
$eliteWd = Split-Path $EliteBat -Parent
try {
    $eliteProc = Start-Process -FilePath $EliteBat -WorkingDirectory $eliteWd -PassThru
} catch {
    Write-Host "[FAIL] Could not start Elite bat: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Path: $EliteBat" -ForegroundColor Yellow
    exit 1
}

$deadline = (Get-Date).AddSeconds(240)
$startedAt = Get-Date
$lastHintAt = Get-Date
Write-Host 'Waiting for full Elite health (up to 4 minutes)...'
Write-Host 'You should see a window titled: Elite Video Lab - Analysis Server'
while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 2
    $body = Get-EliteHealthBody
    if (Test-EliteFullyReady $body) {
        Write-Host ''
        Write-Host '[OK] Elite server is fully ready.' -ForegroundColor Green
        Write-Host $body
        try { Start-Process $HealthUrl } catch {}
        exit 0
    }
    if ($eliteProc -and $eliteProc.HasExited -and ((Get-Date) - $startedAt).TotalSeconds -gt 15) {
        $partial = Get-EliteHealthBody
        if (-not (Test-EliteFullyReady $partial)) {
            Write-Host ''
            Write-Host '[FAIL] Elite window closed or crashed before becoming ready.' -ForegroundColor Red
            Write-Host 'Read the Elite Video Lab window text (that is the real error).' -ForegroundColor Yellow
            Write-Host 'Common causes: Python missing, pip/offline packages, or bad .env.' -ForegroundColor Yellow
            Write-PartialHealthHint $partial
            if ($partial) { Write-Host $partial }
            exit 1
        }
    }
    if (((Get-Date) - $lastHintAt).TotalSeconds -ge 30) {
        Write-Host ''
        Write-PartialHealthHint $body
        $lastHintAt = Get-Date
    }
    Write-Host -NoNewline '.'
}

Write-Host ''
Write-Host '[FAIL] Elite server did not become fully ready in time.' -ForegroundColor Red
Write-Host 'Look at the Elite server window for errors. Do not close it.' -ForegroundColor Red
$body = Get-EliteHealthBody
Write-PartialHealthHint $body
if ($body) { Write-Host $body } else { Write-Host '(no response on /health yet)' }
Write-Host "Video dir: $VideoDir"
Write-Host 'Then run: START-SWIMIQ-WITH-ELITE.bat'
exit 1
