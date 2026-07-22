# FIND StrokeIQ on this PC — paste into PowerShell, press Enter
# It prints every swimiq\pubspec.yaml it finds.

$ErrorActionPreference = 'SilentlyContinue'
Write-Host 'Searching Desktop + OneDrive for swimiq\pubspec.yaml ...' -ForegroundColor Cyan
$roots = @(
  "$env:USERPROFILE\Desktop",
  "$env:USERPROFILE\OneDrive\Desktop",
  "$env:OneDrive\Desktop",
  "$env:USERPROFILE\Documents",
  "$env:USERPROFILE\OneDrive",
  'C:\SwimIQWork',
  'D:\',
  'C:\'
) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -Unique

$hits = @()
foreach ($r in $roots) {
  Write-Host "  scanning $r ..."
  $hits += Get-ChildItem -Path $r -Filter 'pubspec.yaml' -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.DirectoryName -match '\\swimiq$' -or (Test-Path (Join-Path $_.DirectoryName 'lib\main.dart')) } |
    Select-Object -ExpandProperty FullName
}

$hits = $hits | Select-Object -Unique
if (-not $hits -or $hits.Count -eq 0) {
  Write-Host ''
  Write-Host 'NONE FOUND.' -ForegroundColor Red
  Write-Host 'In File Explorer, search This PC for:  pubspec.yaml'
  Write-Host 'Open that folder and tell me the full path shown in the address bar.'
} else {
  Write-Host ''
  Write-Host 'FOUND:' -ForegroundColor Green
  $hits | ForEach-Object { Write-Host "  $_" }
  Write-Host ''
  Write-Host 'Copy the folder path ABOVE pubspec.yaml (the swimiq folder).'
}
Read-Host 'Press Enter'
