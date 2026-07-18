# Starts Elite analysis server (if needed) and waits until /health answers.
$ErrorActionPreference = 'Stop'

$ApiBase = 'http://127.0.0.1:8080'
$HealthUrl = "$ApiBase/health"
# This file lives at: <repo>/swimiq/scripts/start-elite-and-wait.ps1
$SwimIqDir = Split-Path $PSScriptRoot -Parent
$RepoRoot = Split-Path $SwimIqDir -Parent
$EliteBat = Join-Path $SwimIqDir 'START-ELITE-ANALYSIS-SERVER.bat'
$VideoDir = Join-Path $RepoRoot 'services\video_analysis'

function Test-EliteHealth {
    try {
        $r = Invoke-WebRequest -UseBasicParsing -Uri $HealthUrl -TimeoutSec 3
        if ($r.StatusCode -ne 200) { return $false }
        return ($r.Content -match 'engine_version')
    } catch {
        return $false
    }
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
Write-Host ''

Refresh-PathFromRegistry

if (Test-EliteHealth) {
    Write-Host '[OK] Elite server already running.' -ForegroundColor Green
    try {
        $body = (Invoke-WebRequest -UseBasicParsing -Uri $HealthUrl -TimeoutSec 3).Content
        Write-Host $body
        if ($body -notmatch '"ffmpeg_available"\s*:\s*true') {
            Write-Host ''
            Write-Host '[WARN] Server is up but FFmpeg is not detected.' -ForegroundColor Yellow
            Write-Host 'Close Elite server windows, then run RESTART-ELITE-AFTER-FFMPEG.bat' -ForegroundColor Yellow
        }
    } catch {}
    exit 0
}

if (-not (Test-Path -LiteralPath $EliteBat)) {
    Write-Host "[FAIL] Missing $EliteBat" -ForegroundColor Red
    exit 1
}

Write-Host 'Elite server not running. Starting it in a new window...' -ForegroundColor Yellow
Start-Process -FilePath 'cmd.exe' -ArgumentList '/k', "`"$EliteBat`"" -WorkingDirectory (Split-Path $EliteBat -Parent)

$deadline = (Get-Date).AddSeconds(420)
Write-Host 'Waiting for http://127.0.0.1:8080/health (up to 7 minutes for first install)...'
while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 2
    if (Test-EliteHealth) {
        Write-Host ''
        Write-Host '[OK] Elite server is ready.' -ForegroundColor Green
        try {
            $body = (Invoke-WebRequest -UseBasicParsing -Uri $HealthUrl -TimeoutSec 3).Content
            Write-Host $body
        } catch {}
        Start-Process $HealthUrl
        exit 0
    }
    Write-Host -NoNewline '.'
}

Write-Host ''
Write-Host '[FAIL] Elite server did not become healthy in time.' -ForegroundColor Red
Write-Host 'Look at the Elite server window for errors.' -ForegroundColor Red
Write-Host "Video dir: $VideoDir"
exit 1
