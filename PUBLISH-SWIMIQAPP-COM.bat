@echo off
title Publish Flutter app to swimiqapp.com
cd /d "%~dp0"
echo.
echo ============================================
echo   Publish REAL Flutter app to swimiqapp.com
echo ============================================
echo.
echo This replaces the OLD marketing website with SwimIQ login.
echo.
echo Updating code first (main)...
git fetch origin main
if errorlevel 1 (
  echo [FAIL] git fetch failed. Check Wi-Fi.
  pause
  exit /b 1
)
git checkout -f main
if errorlevel 1 (
  echo [FAIL] Could not checkout main.
  pause
  exit /b 1
)
git reset --hard origin/main
if errorlevel 1 (
  echo [FAIL] Could not reset to latest main.
  pause
  exit /b 1
)
echo.
echo [OK] On branch: main
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
echo If those are MISSING above, stop — Wi-Fi/GitHub pull failed.
echo Do NOT upload an old zip from UPLOAD-TO-GODADDY.
echo.
echo IMPORTANT: After the zip builds, upload the NEW zip only:
echo   swimiq\build\swimiq-web-godaddy.zip
echo.
if not exist "%~dp0swimiq\SWIMIQ-BUILD-GODADDY-NOW.bat" (
  echo [FAIL] Missing swimiq\SWIMIQ-BUILD-GODADDY-NOW.bat
  pause
  exit /b 1
)
call "%~dp0swimiq\SWIMIQ-BUILD-GODADDY-NOW.bat"
exit /b %ERRORLEVEL%
