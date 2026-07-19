# Starts a FRESH Elite analysis server and waits until /health is fully ready.
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
    # Last matching line wins (people sometimes paste GEMINI_API_KEY twice).
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
    if ($parts.Count -gt 0) {
        $env:Path = ($parts -join ';')
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

$body = Get-EliteHealthBody
$needsKeyRestart = Test-GeminiNeedsRestart

if ($CheckOnly) {
    if (Test-EliteFullyReady $body) {
        Write-Host '[OK] Elite server already fully ready (ffmpeg + storage).' -ForegroundColor Green
        Write-Host $body
        exit 0
    }
    Write-Host '[FAIL] Elite is not fully ready (CheckOnly — not restarting).' -ForegroundColor Red
    if ($body) { Write-Host $body }
    exit 1
}

if ((Test-EliteFullyReady $body) -and (-not $ForceRestart) -and (-not $needsKeyRestart)) {
    Write-Host '[OK] Elite server already fully ready (ffmpeg + storage).' -ForegroundColor Green
    Write-Host $body
    exit 0
}

if ($needsKeyRestart -and (Test-EliteFullyReady $body)) {
    Write-Host '[WARN] GEMINI_API_KEY in swimiq\.env differs from Elite .env — restarting Elite to load it.' -ForegroundColor Yellow
}

if ($body -and -not (Test-EliteFullyReady $body)) {
    Write-Host '[WARN] Something is on :8080 but it is NOT fully ready (likely OLD Elite code).' -ForegroundColor Yellow
    Write-Host $body
    Write-Host 'Killing it and starting a fresh Elite server...' -ForegroundColor Yellow
} elseif (-not $body) {
    Write-Host 'Elite server not running. Starting a fresh one...' -ForegroundColor Yellow
}

# Refresh Elite .env from Flutter before start (keys, intervals, etc.).
if (Test-Path -LiteralPath $EnsureScript) {
    Write-Host 'Refreshing services\video_analysis\.env from swimiq\.env ...' -ForegroundColor Cyan
    & powershell -NoProfile -ExecutionPolicy Bypass -File $EnsureScript $VideoDir
    if ($LASTEXITCODE -eq 2) {
        Write-Host '[FAIL] Elite .env missing Supabase URL/anon key.' -ForegroundColor Red
        exit 2
    }
}

if (Test-Path -LiteralPath $KillScript) {
    & powershell -NoProfile -ExecutionPolicy Bypass -File $KillScript
}

if (-not (Test-Path -LiteralPath $EliteBat)) {
    Write-Host "[FAIL] Missing $EliteBat" -ForegroundColor Red
    exit 1
}

Write-Host ''
Write-Host '>>> Opening Elite black window. DO NOT CLOSE IT. <<<' -ForegroundColor Yellow
# Child Elite bat must NOT kill port 8080 again (that fought the new server).
$env:SWIMIQ_SKIP_PORT_KILL = '1'
$eliteProc = Start-Process -FilePath 'cmd.exe' `
    -ArgumentList '/k', "`"$EliteBat`"" `
    -WorkingDirectory (Split-Path $EliteBat -Parent) `
    -PassThru

$deadline = (Get-Date).AddSeconds(420)
$startedAt = Get-Date
Write-Host 'Waiting for full Elite health (up to 7 minutes)...'
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
    if ($eliteProc -and $eliteProc.HasExited -and ((Get-Date) - $startedAt).TotalSeconds -gt 20) {
        $partial = Get-EliteHealthBody
        if (-not (Test-EliteFullyReady $partial)) {
            Write-Host ''
            Write-Host '[FAIL] Elite window closed or crashed before becoming ready.' -ForegroundColor Red
            Write-Host 'Run START-SWIMIQ-WITH-ELITE.bat again and leave the Elite window open.' -ForegroundColor Yellow
            if ($partial) { Write-Host $partial }
            exit 1
        }
    }
    Write-Host -NoNewline '.'
}

Write-Host ''
Write-Host '[FAIL] Elite server did not become fully ready in time.' -ForegroundColor Red
Write-Host 'Look at the Elite server window for errors. Do not close it.' -ForegroundColor Red
$body = Get-EliteHealthBody
if ($body) { Write-Host $body } else { Write-Host '(no response on /health yet)' }
Write-Host "Video dir: $VideoDir"
Write-Host 'Need BOTH: ffmpeg_available:true AND storage_download_configured:true'
Write-Host 'Then run: START-SWIMIQ-WITH-ELITE.bat'
exit 1
