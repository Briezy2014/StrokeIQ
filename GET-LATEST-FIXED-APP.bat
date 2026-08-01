@echo off
setlocal
title SwimIQ - Get latest from GitHub
cd /d "%~dp0"

echo.
echo ============================================
echo   SwimIQ — get latest from GitHub (main)
echo   Folder: %CD%
echo ============================================
echo.
echo NOTE: An old zip in UPLOAD-TO-GODADDY is NOT
echo the latest app. We always pull GitHub first.
echo For coaches, build fresh with PUBLISH-SWIMIQAPP-COM.bat
echo.

if not exist ".git" goto :NoGit

echo Checking GitHub connection...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "try { $r = Invoke-WebRequest -Uri 'https://github.com' -UseBasicParsing -TimeoutSec 12; if ($r.StatusCode -ge 200 -and $r.StatusCode -lt 500) { exit 0 } else { exit 1 } } catch { exit 1 }"
if errorlevel 1 goto :NetworkFail

echo Updating from GitHub (main)...
git fetch origin
if errorlevel 1 goto :FetchFail

git merge --abort >nul 2>&1
git checkout -f main
if errorlevel 1 goto :UpdateFail
git reset --hard origin/main
if errorlevel 1 goto :UpdateFail

echo.
echo ============================================
echo   LATEST CODE ON THIS PC (must see these)
echo ============================================
git log -8 --oneline
echo.
echo You should see recent lines like:
echo   - Dryland Coach header contrast (#117)
echo   - demo recruiting times honest (#116)
echo   - Passport Share / export UI (#115)
echo   - Stripe unlock / project ref (#114)
echo   - Aspyn Briez coach demo (#113)
echo.
echo ============================================
echo   NEXT STEP FOR GODADDY
echo ============================================
echo.
echo Do NOT upload UPLOAD-TO-GODADDY\*.zip unless you
echo know it was built TODAY from this pull.
echo.
echo Double-click this instead (builds a NEW zip):
echo   PUBLISH-SWIMIQAPP-COM.bat
echo.
echo That creates:
echo   swimiq\build\swimiq-web-godaddy.zip
echo.
pause
exit /b 0

:NoGit
echo [FAIL] This is not the StrokeIQ git folder.
echo Open Desktop\StrokeIQ and run this file there.
pause
exit /b 1

:NetworkFail
echo.
echo ============================================
echo   Cannot reach GitHub right now
echo ============================================
echo.
echo Use phone hotspot, then run this again.
echo Do NOT upload an old UPLOAD-TO-GODADDY zip —
echo it may be missing Aspyn / Passport / Dryland fixes.
echo.
pause
exit /b 1

:FetchFail
echo [FAIL] git fetch failed. Check Wi-Fi / GitHub login.
pause
exit /b 1

:UpdateFail
echo [FAIL] Could not update files from GitHub.
echo Try FIX-GIT-PULL.bat, then run this again.
pause
exit /b 1
