# Backward-compatible wrapper — logic lives in ../fix-kara-paths.ps1
$root = Split-Path -Parent $PSScriptRoot
& (Join-Path $root 'fix-kara-paths.ps1')
exit $LASTEXITCODE
