# Backward-compatible wrapper — logic lives in ../launch-chrome.ps1
$root = Split-Path -Parent $PSScriptRoot
& (Join-Path $root 'launch-chrome.ps1')
exit $LASTEXITCODE
