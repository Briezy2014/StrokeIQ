@echo off
setlocal EnableExtensions
title FIX ANALYSIS NOW - start Elite server
cd /d "%~dp0"

echo.
echo ############################################################
echo #  FIX ANALYSIS NOW                                        #
echo #  This starts the Elite server on THIS PC                 #
echo ############################################################
echo.
echo The black banner means Elite is NOT running on port 8080.
echo This file starts it. Leave the Elite black window OPEN.
echo.
echo Updating files...
git -C "%CD%" fetch origin cursor/elite-video-on-dashboard-b7ef
if errorlevel 1 (
  echo [FAIL] git fetch failed. Check Wi-Fi.
  pause
  exit /b 1
)
git -C "%CD%" checkout -f cursor/elite-video-on-dashboard-b7ef
git -C "%CD%" reset --hard origin/cursor/elite-video-on-dashboard-b7ef
if errorlevel 1 (
  echo [FAIL] Could not update files.
  pause
  exit /b 1
)
echo [OK] Files updated.
echo.

echo Clearing old Elite process on port 8080...
if exist "%CD%\swimiq\scripts\kill-elite-port.ps1" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%CD%\swimiq\scripts\kill-elite-port.ps1"
)
echo.

echo Starting Elite and waiting until http://127.0.0.1:8080/health answers...
echo A NEW black window titled "Elite Video Lab" will open.
echo DO NOT CLOSE THAT WINDOW.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%CD%\swimiq\scripts\start-elite-and-wait.ps1"
if errorlevel 1 (
  echo.
  echo [FAIL] Elite did not start.
  echo Look at the Elite black window for the red error.
  echo Common fixes:
  echo   - Keep that Elite window open
  echo   - Run FIX-STORAGE.bat if storage keys are missing
  echo   - Run RESTART-ELITE-AFTER-FFMPEG.bat if FFmpeg is missing
  echo.
  pause
  exit /b 1
)

echo.
echo [OK] Elite is answering on 127.0.0.1:8080
echo.
echo Now opening SwimIQ in Chrome (localhost only)...
echo Keep BOTH windows open: Elite black window + Chrome.
echo.
call "%CD%\swimiq\LAUNCH-CHROME.bat"
exit /b %ERRORLEVEL%
