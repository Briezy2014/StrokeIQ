@echo off
setlocal EnableDelayedExpansion
title SwimIQ + Elite Video Lab
cd /d "%~dp0"

echo.
echo ============================================
echo   START SwimIQ WITH Elite Video Lab
echo ============================================
echo.
echo This one file:
echo   1. Updates the app
echo   2. Starts the Elite analysis server
echo   3. Waits until it answers on 127.0.0.1:8080
echo   4. Launches SwimIQ in Chrome
echo.
echo Keep BOTH windows open while you analyze.
echo.

echo [1/4] Updating folder...
git fetch origin cursor/elite-video-on-dashboard-b7ef 2>nul
git checkout -f cursor/elite-video-on-dashboard-b7ef 2>nul
git reset --hard origin/cursor/elite-video-on-dashboard-b7ef 2>nul
echo.

echo [2/4] Starting / checking Elite analysis server...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0swimiq\scripts\start-elite-and-wait.ps1"
if errorlevel 1 (
  echo.
  echo [FAIL] Elite server is not ready. Fix the Elite window errors first.
  echo Then double-click this file again.
  echo.
  pause
  exit /b 1
)

echo.
echo [3/4] Elite is up. Launching SwimIQ Chrome...
echo [4/4] Use the Elite Video Lab tab, then Confirm ^& Analyze.
echo.
call "%~dp0swimiq\LAUNCH-CHROME.bat"
exit /b %ERRORLEVEL%
