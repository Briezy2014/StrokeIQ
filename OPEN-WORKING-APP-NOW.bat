@echo off
setlocal
title SwimIQ WORKING APP - localhost only
cd /d "%~dp0"

echo.
echo ############################################################
echo #  WORKING APP - localhost only                           #
echo #  Close swimiqapp.com first                              #
echo ############################################################
echo.
echo The black workstation banner means OLD website.
echo This launcher opens the FIXED app on THIS PC.
echo.

start "" notepad "%CD%\YOU-ARE-ON-THE-OLD-WEBSITE.txt"

echo Updating files...
git -C "%CD%" fetch origin cursor/elite-video-on-dashboard-b7ef
if errorlevel 1 (
  echo [FAIL] git fetch failed. Check Wi-Fi.
  pause
  exit /b 1
)
git -C "%CD%" checkout -f cursor/elite-video-on-dashboard-b7ef
git -C "%CD%" reset --hard origin/cursor/elite-video-on-dashboard-b7ef

echo.
echo Starting Elite + Chrome localhost...
echo After Chrome opens, address bar MUST be 127.0.0.1 or localhost.
echo.
call "%CD%\FINAL-TRY-THIS-ONLY.bat"
exit /b %ERRORLEVEL%
