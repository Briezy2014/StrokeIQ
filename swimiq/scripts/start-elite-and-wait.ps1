# Starts a FRESH Elite analysis server and waits until /health is fully ready.
$ErrorActionPreference = 'Stop'

$ApiBase = 'http://127.0.0.1:8080'
$HealthUrl = "$ApiBase/health"
$SwimIqDir = Split-Path $PSScriptRoot -Parent
$RepoRoot = Split-Path $SwimIqDir -Parent
$EliteBat = Join-Path $SwimIqDir 'START-ELITE-ANALYSIS-SERVER.bat'
$KillScript = Join-Path $PSScriptRoot 'kill-elite-port.ps1'
$VideoDir = Join-Path $RepoRoot 'services\video_analysis'

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
    # Must include the new field set to true — rejects stale Elite processes.
    if ($body -notmatch '"storage_download_configured"\s*:\s*true') { return $false }
    return $true
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

$body = Get-EliteHealthBody
if (Test-EliteFullyReady $body) {
    Write-Host '[OK] Elite server already fully ready (ffmpeg + storage).' -ForegroundColor Green
    Write-Host $body
    exit 0
}

if ($body) {
    Write-Host '[WARN] Something is on :8080 but it is NOT fully ready (likely OLD Elite code).' -ForegroundColor Yellow
    Write-Host $body
    Write-Host 'Killing it and starting a fresh Elite server...' -ForegroundColor Yellow
} else {
    Write-Host 'Elite server not running. Starting a fresh one...' -ForegroundColor Yellow
}

if (Test-Path -LiteralPath $KillScript) {
    & powershell -NoProfile -ExecutionPolicy Bypass -File $KillScript
}

if (-not (Test-Path -LiteralPath $EliteBat)) {
    Write-Host "[FAIL] Missing $EliteBat" -ForegroundColor Red
    exit 1
}

Start-Process -FilePath 'cmd.exe' -ArgumentList '/k', "`"$EliteBat`"" -WorkingDirectory (Split-Path $EliteBat -Parent)

$deadline = (Get-Date).AddSeconds(420)
Write-Host 'Waiting for full Elite health (up to 7 minutes)...'
while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 2
    $body = Get-EliteHealthBody
    if (Test-EliteFullyReady $body) {
        Write-Host ''
        Write-Host '[OK] Elite server is fully ready.' -ForegroundColor Green
        Write-Host $body
        Start-Process $HealthUrl
        exit 0
    }
    Write-Host -NoNewline '.'
}

Write-Host ''
Write-Host '[FAIL] Elite server did not become fully ready in time.' -ForegroundColor Red
Write-Host 'Look at the Elite server window for errors.' -ForegroundColor Red
$body = Get-EliteHealthBody
if ($body) { Write-Host $body }
Write-Host "Video dir: $VideoDir"
Write-Host 'Need BOTH: ffmpeg_available:true AND storage_download_configured:true'
exit 1
