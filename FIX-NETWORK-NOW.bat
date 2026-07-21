@echo off
setlocal
title SwimIQ - Fix network for GitHub / pub.dev
cd /d "%~dp0"

echo.
echo ============================================
echo   SwimIQ network check
echo ============================================
echo.
echo Power Index, Dryland, and 100 MB video analysis
echo are already on GitHub. Your PC must reach:
echo   - github.com  (download code)
echo   - pub.dev     (build website zip)
echo.

echo [1/3] Opening github.com and pub.dev in Chrome...
start "" "https://github.com"
timeout /t 2 /nobreak >nul
start "" "https://pub.dev"
echo.

echo [2/3] Testing from this PC...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ok=$true; foreach ($u in @('https://github.com','https://pub.dev')) { try { $r=Invoke-WebRequest -Uri $u -UseBasicParsing -TimeoutSec 12; Write-Host ('[OK] ' + $u + '  status=' + $r.StatusCode) } catch { Write-Host ('[FAIL] ' + $u + '  ' + $_.Exception.Message); $ok=$false } }; if ($ok) { exit 0 } else { exit 1 }"
if errorlevel 1 goto :Blocked

echo.
echo [3/3] GitHub + pub.dev are reachable.
echo.
echo Next:
echo   1) GET-LATEST-FIXED-APP.bat
echo   2) PUBLISH-SWIMIQAPP-COM.bat  (need BUILD + ZIP DONE)
echo   3) Upload swimiq\build\swimiq-web-godaddy.zip to GoDaddy
echo   4) swimiq\KARA-GEMINI-FIX-NOW.bat  (100 MB video server)
echo.
pause
exit /b 0

:Blocked
echo.
echo ============================================
echo   NETWORK STILL BLOCKED
echo ============================================
echo.
echo Do this:
echo   A) Connect PC to your PHONE HOTSPOT
echo   B) Turn off VPN
echo   C) Re-run this file until both say [OK]
echo   D) Then run GET-LATEST-FIXED-APP.bat
echo.
echo Optional DNS (admin PowerShell):
echo   netsh interface ip set dns "Wi-Fi" static 8.8.8.8
echo   netsh interface ip add dns "Wi-Fi" 1.1.1.1 index=2
echo.
pause
exit /b 1
