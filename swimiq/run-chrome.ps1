# Backward-compatible wrapper
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
& (Join-Path $root 'launch-chrome.ps1')
