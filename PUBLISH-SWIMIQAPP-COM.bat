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
git log -1 --oneline
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
