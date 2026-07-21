# SwimIQ - ONE FILE GoDaddy Flutter web build (Kara Williams / Windows)
$ErrorActionPreference = 'Stop'

$buildScript = Join-Path $PSScriptRoot 'scripts\build-web-godaddy.ps1'
$zipScript = Join-Path $PSScriptRoot 'scripts\zip-web-godaddy.ps1'

Write-Host ''
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ' SwimIQ - Publish Flutter to GoDaddy' -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ''
Write-Host 'This builds the REAL Flutter app (login, dashboard, passport).' -ForegroundColor Yellow
Write-Host 'It does NOT upload the old marketing website\ folder.' -ForegroundColor Yellow
Write-Host ''

& powershell -NoProfile -ExecutionPolicy Bypass -File $buildScript
if ($LASTEXITCODE -ne 0) {
    Write-Host 'BUILD FAILED.' -ForegroundColor Red
    Write-Host ''
    Write-Host '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!' -ForegroundColor Red
    Write-Host ' DO NOT UPLOAD ANY ZIP TO GODADDY' -ForegroundColor Red
    Write-Host ' The old zip was deleted so you cannot' -ForegroundColor Red
    Write-Host ' accidentally re-upload yesterday''s build.' -ForegroundColor Red
    Write-Host '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!' -ForegroundColor Red
    Write-Host ''
    Write-Host 'If you saw pub.dev / Failed host lookup:' -ForegroundColor Yellow
    Write-Host '  1) Open https://pub.dev in Chrome' -ForegroundColor Yellow
    Write-Host '  2) When it loads, run PUBLISH-SWIMIQAPP-COM.bat again' -ForegroundColor Yellow
    Read-Host 'Press Enter to close'
    exit $LASTEXITCODE
}

. (Join-Path $PSScriptRoot 'scripts\swimiq-windows-paths.ps1')
try {
    $paths = Initialize-SwimIqWindowsPaths -ScriptsRoot (Join-Path $PSScriptRoot 'scripts')
} catch {
    Write-Host ("ERROR: " + $_.Exception.Message) -ForegroundColor Red
    Read-Host 'Press Enter'
    exit 1
}

$webOut = Join-Path $paths.WorkDir 'build\web'
$zipPath = Join-Path $paths.WorkDir 'build\swimiq-web-godaddy.zip'
Write-Host ''
Write-Host 'Creating GoDaddy zip...' -ForegroundColor Cyan
& powershell -NoProfile -ExecutionPolicy Bypass -File $zipScript -WebDir $webOut -ZipPath $zipPath
$zipCode = $LASTEXITCODE
if ($zipCode -ne 0) {
    Write-Host 'ZIP FAILED - do not upload to GoDaddy yet.' -ForegroundColor Red
    Write-Host 'First run GET-LATEST-FIXED-APP.bat / CLICK-ME-FIRST.bat, then publish again.' -ForegroundColor Yellow
    Read-Host 'Press Enter to close'
    exit $zipCode
}

if (-not (Test-Path -LiteralPath $zipPath)) {
    Write-Host ('ZIP MISSING: ' + $zipPath) -ForegroundColor Red
    Read-Host 'Press Enter to close'
    exit 1
}

Write-Host ''
Write-Host '========================================' -ForegroundColor Green
Write-Host ' BUILD + ZIP DONE - next upload to GoDaddy' -ForegroundColor Green
Write-Host '========================================' -ForegroundColor Green
Write-Host ''
$marker = Join-Path $webOut 'SWIMIQ-FLUTTER-BUILD.txt'
if (Test-Path -LiteralPath $marker) {
    Write-Host 'BUILD STAMP (must match live site after upload):' -ForegroundColor Cyan
    Get-Content -LiteralPath $marker | ForEach-Object { Write-Host ('  ' + $_) -ForegroundColor Green }
    Write-Host ''
}
Write-Host '1. GoDaddy -> My Products -> swimiqapp.com -> Hosting -> File Manager' -ForegroundColor Cyan
Write-Host '2. Open public_html' -ForegroundColor Cyan
Write-Host '3. Upload ONE file:' -ForegroundColor Cyan
Write-Host ('   ' + $zipPath) -ForegroundColor Green
Write-Host '4. Right-click zip -> Extract -> overwrite everything' -ForegroundColor Cyan
Write-Host '5. Confirm public_html/SWIMIQ-FLUTTER-BUILD.txt shows TODAY commit' -ForegroundColor Cyan
Write-Host '6. Open https://swimiqapp.com/SWIMIQ-FLUTTER-BUILD.txt' -ForegroundColor Cyan
Write-Host '7. Hard refresh login page Ctrl+Shift+R (or Incognito)' -ForegroundColor Cyan
Write-Host ''
Write-Host 'PROOF live updated: that .txt file commit changes, and Video Lab accepts phone clips up to 100 MB (not 25/50 MB).' -ForegroundColor Yellow
Write-Host ''
try { explorer.exe /select,$zipPath } catch {}
Read-Host 'Press Enter to close'
