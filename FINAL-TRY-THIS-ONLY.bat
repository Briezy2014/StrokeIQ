@echo off
setlocal EnableDelayedExpansion
title SwimIQ FINAL TRY — analysis on this PC
cd /d "%~dp0"

echo.
echo ############################################################
echo #  FINAL TRY — Elite analysis on THIS computer            #
echo #  Do NOT use swimiqapp.com for this try                  #
echo ############################################################
echo.
echo Read FINAL-TRY-THIS-ONLY.txt if you want the printed steps.
echo.
echo Updating files from GitHub...
git -C "%CD%" fetch origin cursor/elite-video-on-dashboard-b7ef
if errorlevel 1 (
  echo [FAIL] Could not reach GitHub. Check Wi-Fi, then run again.
  pause
  exit /b 1
)
git -C "%CD%" checkout -f cursor/elite-video-on-dashboard-b7ef
git -C "%CD%" reset --hard origin/cursor/elite-video-on-dashboard-b7ef
if errorlevel 1 (
  echo [FAIL] Could not update this folder to the fixed branch.
  pause
  exit /b 1
)
echo [OK] On cursor/elite-video-on-dashboard-b7ef
echo.

if not exist "%CD%\swimiq\scripts\final-try-preflight.ps1" (
  echo [FAIL] Missing swimiq\scripts\final-try-preflight.ps1
  echo Run GET-LATEST-FIXED-APP.bat first.
  pause
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%CD%\swimiq\scripts\final-try-preflight.ps1"
if errorlevel 1 (
  echo.
  echo [FAIL] Preflight failed. Fix the FAIL lines above, then run this again.
  echo Full steps: FINAL-TRY-THIS-ONLY.txt
  echo.
  start "" notepad "%CD%\FINAL-TRY-THIS-ONLY.txt"
  pause
  exit /b 1
)

echo.
echo [OK] Elite is ready. Launching SwimIQ in Chrome...
echo Keep the Elite server window OPEN.
echo.
call "%CD%\swimiq\LAUNCH-CHROME.bat"
exit /b %ERRORLEVEL%
