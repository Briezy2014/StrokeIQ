# Preflight for FINAL-TRY-THIS-ONLY.bat - clear PASS/FAIL gates only.
# ASCII-only on purpose. Windows PowerShell 5.1 misreads UTF-8 dashes as quotes.
$ErrorActionPreference = 'Stop'

function Write-Pass([string]$msg) { Write-Host "[PASS] $msg" -ForegroundColor Green }
function Write-Fail([string]$msg) { Write-Host "[FAIL] $msg" -ForegroundColor Red }
function Write-Info([string]$msg) { Write-Host "[INFO] $msg" -ForegroundColor Cyan }

$SwimIqDir = Split-Path $PSScriptRoot -Parent
$RepoRoot = Split-Path $SwimIqDir -Parent
$EnvFile = Join-Path $SwimIqDir '.env'
$EliteBat = Join-Path $SwimIqDir 'START-ELITE-ANALYSIS-SERVER.bat'
$WaitScript = Join-Path $PSScriptRoot 'start-elite-and-wait.ps1'
$LaunchBat = Join-Path $SwimIqDir 'LAUNCH-CHROME.bat'
$failed = $false

Write-Host ''
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ' FINAL TRY - preflight checks' -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ("Folder: {0}" -f $RepoRoot)
Write-Host ''

if (-not (Test-Path -LiteralPath (Join-Path $RepoRoot '.git'))) {
    Write-Fail 'This is not the StrokeIQ git folder. Open Desktop\StrokeIQ and run FINAL-TRY-THIS-ONLY.bat there.'
    exit 1
}
Write-Pass 'StrokeIQ git folder found'

if (-not (Test-Path -LiteralPath $EnvFile)) {
    Write-Fail ("Missing {0} - add SUPABASE_URL and SUPABASE_ANON_KEY, then run again." -f $EnvFile)
    if (Test-Path -LiteralPath (Join-Path $SwimIqDir '.env.example')) {
        Copy-Item (Join-Path $SwimIqDir '.env.example') $EnvFile -Force
        notepad $EnvFile
    }
    exit 1
}

$url = $null
$key = $null
Get-Content -LiteralPath $EnvFile | ForEach-Object {
    if ($_ -match '^\s*SUPABASE_URL\s*=\s*(.+)\s*$') { $url = $matches[1].Trim().Trim('"').Trim("'") }
    if ($_ -match '^\s*SUPABASE_ANON_KEY\s*=\s*(.+)\s*$') { $key = $matches[1].Trim().Trim('"').Trim("'") }
}
if (-not $url -or $url -match 'your-project' -or -not $key -or $key -match 'your-supabase|your_anon|paste_') {
    Write-Fail 'swimiq\.env does not have real Supabase URL + anon key.'
    notepad $EnvFile
    exit 1
}
Write-Pass 'swimiq\.env has Supabase URL + anon key'

# Refresh PATH so winget ffmpeg is visible in this session.
$sys = ''
$usr = ''
try { $sys = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' -Name Path -ErrorAction SilentlyContinue).Path } catch {}
try { $usr = (Get-ItemProperty -Path 'HKCU:\Environment' -Name Path -ErrorAction SilentlyContinue).Path } catch {}
$parts = @()
if ($sys) { $parts += $sys }
if ($usr) { $parts += $usr }
$wingetLinks = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links'
if (Test-Path $wingetLinks) { $parts = @($wingetLinks) + $parts }
foreach ($extra in @(
    (Join-Path $env:ProgramFiles 'ffmpeg\bin'),
    (Join-Path $env:ProgramFiles 'Gyan\FFmpeg\bin')
)) {
    if (Test-Path $extra) { $parts = @($extra) + $parts }
}
if ($parts.Count -gt 0) { $env:Path = ($parts -join ';') }

$ffmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue
$ffprobe = Get-Command ffprobe -ErrorAction SilentlyContinue
if (-not $ffmpeg -or -not $ffprobe) {
    Write-Fail 'FFmpeg / ffprobe not found on PATH.'
    Write-Host 'Install FFmpeg (winget install Gyan.FFmpeg), then run RESTART-ELITE-AFTER-FFMPEG.bat' -ForegroundColor Yellow
    $failed = $true
} else {
    Write-Pass ("FFmpeg found: {0}" -f $ffmpeg.Source)
}

if (-not (Test-Path -LiteralPath $EliteBat)) {
    Write-Fail ("Missing {0}" -f $EliteBat)
    $failed = $true
} else {
    Write-Pass 'Elite server starter found'
}

if (-not (Test-Path -LiteralPath $WaitScript)) {
    Write-Fail ("Missing {0}" -f $WaitScript)
    $failed = $true
}

if (-not (Test-Path -LiteralPath $LaunchBat)) {
    Write-Fail ("Missing {0}" -f $LaunchBat)
    $failed = $true
}

if ($failed) {
    Write-Host ''
    Write-Fail 'Preflight failed. Fix the FAIL lines above, then run FINAL-TRY-THIS-ONLY.bat again.'
    exit 1
}

Write-Host ''
Write-Info 'Do NOT open swimiqapp.com for this try. Use the Chrome window this script opens.'
Write-Host ''
Write-Info 'Starting Elite server and waiting for full /health ...'
& powershell -NoProfile -ExecutionPolicy Bypass -File $WaitScript
if ($LASTEXITCODE -ne 0) {
    Write-Fail 'Elite /health is not fully ready.'
    Write-Host 'Look at the Elite black window. Common fixes:' -ForegroundColor Yellow
    Write-Host '  - FIX-STORAGE.bat   (storage_download_configured must be true)' -ForegroundColor Yellow
    Write-Host '  - RESTART-ELITE-AFTER-FFMPEG.bat' -ForegroundColor Yellow
    exit 1
}

Write-Pass 'Elite /health is fully ready (ffmpeg + storage)'
Write-Host ''
Write-Info 'Next in Chrome (after it opens):'
Write-Host '  1) Sign in as briezy682014@gmail.com'
Write-Host '  2) Confirm address bar is localhost / 127.0.0.1'
Write-Host '  3) Elite tab -> upload one short clip'
Write-Host '  4) Run Elite Analysis / Confirm & Analyze'
Write-Host '  5) Keep Chrome + Elite windows open until results appear'
Write-Host ''
exit 0
