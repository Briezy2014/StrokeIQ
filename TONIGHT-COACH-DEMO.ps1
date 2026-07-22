# TONIGHT — run SwimIQ + Elite on THIS PC (not swimiqapp.com)
# Right-click → Run with PowerShell
# Works even when GoDaddy / GitHub / .bat files are missing.

$ErrorActionPreference = 'Continue'
Write-Host ''
Write-Host '============================================'
Write-Host '  TONIGHT coach demo — LOCAL Elite'
Write-Host '  (not the public website)'
Write-Host '============================================'
Write-Host ''

$candidates = @(
  (Join-Path $PSScriptRoot 'swimiq'),
  (Join-Path $PSScriptRoot 'StrokeIQ\swimiq'),
  (Join-Path $env:USERPROFILE 'Desktop\StrokeIQ\swimiq'),
  (Join-Path $env:USERPROFILE 'Desktop\StrokeIQ\StrokeIQ\swimiq')
)
if ($env:OneDrive) {
  $candidates += @(
    (Join-Path $env:OneDrive 'Desktop\StrokeIQ\swimiq'),
    (Join-Path $env:OneDrive 'Desktop\StrokeIQ\StrokeIQ\swimiq')
  )
}

$swimiq = $null
foreach ($c in $candidates) {
  if ($c -and (Test-Path -LiteralPath (Join-Path $c 'pubspec.yaml'))) {
    $swimiq = $c
    break
  }
}

if (-not $swimiq) {
  Write-Host 'Could not find swimiq\pubspec.yaml on this PC.' -ForegroundColor Red
  Write-Host 'Open Desktop\StrokeIQ\swimiq in File Explorer and run this script from there.'
  Read-Host 'Press Enter to close'
  exit 1
}

Write-Host "Using: $swimiq"
Set-Location -LiteralPath $swimiq

$eliteWait = Join-Path $swimiq 'scripts\start-elite-and-wait.ps1'
$chrome = Join-Path $swimiq 'start_swimiq.ps1'
if (-not (Test-Path -LiteralPath $chrome)) {
  $chrome = Join-Path $swimiq 'SWIMIQ-CHROME-NOW.ps1'
}
if (-not (Test-Path -LiteralPath $chrome)) {
  $chrome = Join-Path $swimiq 'scripts\launch-chrome-kara.ps1'
}

if (Test-Path -LiteralPath $eliteWait) {
  Write-Host '[1/2] Starting Elite analysis server (leave that window open)...'
  & powershell -NoProfile -ExecutionPolicy Bypass -File $eliteWait
  if ($LASTEXITCODE -ne 0) {
    Write-Host "Elite did not become ready (exit $LASTEXITCODE)." -ForegroundColor Yellow
    Write-Host 'If FFmpeg is missing, run: winget install Gyan.FFmpeg'
    Write-Host 'Then run this script again.'
    Read-Host 'Press Enter to close'
    exit $LASTEXITCODE
  }
} else {
  Write-Host '[WARN] Elite wait script missing — trying Chrome anyway.' -ForegroundColor Yellow
}

Write-Host '[2/2] Opening SwimIQ in Chrome on THIS PC (127.0.0.1)...'
Write-Host 'Wait for compile (2-4 minutes). Address must be 127.0.0.1 — NOT swimiqapp.com'
if (Test-Path -LiteralPath $chrome) {
  & powershell -NoProfile -ExecutionPolicy Bypass -File $chrome
} else {
  Write-Host 'No Chrome launcher found in swimiq. Open start_swimiq.ps1 manually.' -ForegroundColor Red
  Read-Host 'Press Enter to close'
  exit 1
}

Write-Host ''
Write-Host 'When Chrome opens: Video Lab → Denison 50 Fly → Run AI Swim Analysis'
Write-Host 'Keep the Elite server window open the whole time.'
Write-Host ''
