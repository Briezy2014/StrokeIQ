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
echo Updating code first...
git fetch origin cursor/elite-video-on-dashboard-b7ef 2>nul
git checkout -f cursor/elite-video-on-dashboard-b7ef 2>nul
git reset --hard origin/cursor/elite-video-on-dashboard-b7ef 2>nul
echo.
if not exist "%~dp0swimiq\SWIMIQ-BUILD-GODADDY-NOW.bat" (
  echo [FAIL] Missing swimiq\SWIMIQ-BUILD-GODADDY-NOW.bat
  pause
  exit /b 1
)
call "%~dp0swimiq\SWIMIQ-BUILD-GODADDY-NOW.bat"
exit /b %ERRORLEVEL%
