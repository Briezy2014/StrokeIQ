# Same as root TONIGHT-COACH-DEMO.ps1 — keep next to swimiq files.
$root = Split-Path -Parent $PSScriptRoot
$launcher = Join-Path $root 'TONIGHT-COACH-DEMO.ps1'
if (Test-Path -LiteralPath $launcher) {
  & powershell -NoProfile -ExecutionPolicy Bypass -File $launcher
  exit $LASTEXITCODE
}
# Running from inside swimiq already
$ErrorActionPreference = 'Continue'
Set-Location -LiteralPath $PSScriptRoot
$eliteWait = Join-Path $PSScriptRoot 'scripts\start-elite-and-wait.ps1'
$chrome = Join-Path $PSScriptRoot 'start_swimiq.ps1'
Write-Host 'TONIGHT coach demo from swimiq folder'
if (Test-Path $eliteWait) {
  & powershell -NoProfile -ExecutionPolicy Bypass -File $eliteWait
  if ($LASTEXITCODE -ne 0) { Read-Host 'Press Enter'; exit $LASTEXITCODE }
}
if (Test-Path $chrome) {
  & powershell -NoProfile -ExecutionPolicy Bypass -File $chrome
} else {
  Write-Host 'Missing start_swimiq.ps1'
  Read-Host 'Press Enter'
}
