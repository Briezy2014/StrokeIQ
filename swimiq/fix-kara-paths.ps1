# Forwards to scripts\kara-fix-windows-once.ps1 (full code lives there)
& (Join-Path $PSScriptRoot 'scripts\kara-fix-windows-once.ps1')
exit $LASTEXITCODE
