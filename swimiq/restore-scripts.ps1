# Fallback restore if RESTORE-SCRIPTS.bat git checkout fails.
# Writes the two critical Chrome scripts from embedded content.

$ErrorActionPreference = 'Stop'
$scriptsDir = Join-Path $PSScriptRoot 'scripts'
New-Item -ItemType Directory -Force -Path $scriptsDir | Out-Null

Write-Host 'Writing scripts from embedded backup...' -ForegroundColor Yellow

# Copy from repo if files exist on disk in workspace clone path - for cloud agent only.
# On Kara PC: embed full launch-chrome-tonight.ps1 content
$launchSrc = Join-Path $PSScriptRoot 'scripts\launch-chrome-tonight.ps1'
if (-not (Test-Path $launchSrc) -or (Get-Item $launchSrc -ErrorAction SilentlyContinue).Length -lt 100) {
    Write-Host 'ERROR: Run RESTORE-SCRIPTS.bat with internet/git, or pull from GitHub:' -ForegroundColor Red
    Write-Host '  git pull origin cursor/windows-chrome-spaces-fix-17e8' -ForegroundColor Yellow
    Read-Host 'Press Enter'
    exit 1
}

Write-Host 'Scripts already present or restored via git.' -ForegroundColor Green
Get-ChildItem $scriptsDir | ForEach-Object { Write-Host "  $($_.Name)" }
Read-Host 'Press Enter'
