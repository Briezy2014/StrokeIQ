@echo off
setlocal EnableExtensions
title SwimIQ + Elite Video Lab
cd /d "%~dp0"

echo.
echo ############################################################
echo #  START SwimIQ WITH Elite                                #
echo #  This is the file that starts analysis on THIS PC       #
echo ############################################################
echo.
echo This one file:
echo   1. Updates from GitHub
echo   2. Clears old Elite on port 8080
echo   3. Starts Elite black window (LEAVE IT OPEN)
echo   4. Waits until http://127.0.0.1:8080 answers
echo   5. Opens SwimIQ in Chrome on localhost
echo.
echo If you saw a black banner about 127.0.0.1:8080 - this fixes it.
echo.

echo [1/5] Updating folder from GitHub...
git -C "%CD%" fetch origin cursor/elite-video-on-dashboard-b7ef
if errorlevel 1 (
  echo [FAIL] git fetch failed. Check Wi-Fi, then run this file again.
  pause
  exit /b 1
)
git -C "%CD%" checkout -f cursor/elite-video-on-dashboard-b7ef
if errorlevel 1 (
  echo [FAIL] Could not checkout branch.
  pause
  exit /b 1
)
git -C "%CD%" reset --hard origin/cursor/elite-video-on-dashboard-b7ef
if errorlevel 1 (
  echo [FAIL] Could not update files.
  pause
  exit /b 1
)
echo [OK] Files updated.
echo.

if not exist "%CD%\swimiq\scripts\start-elite-and-wait.ps1" (
  echo [FAIL] Missing swimiq\scripts\start-elite-and-wait.ps1 after update.
  echo Run GET-LATEST-FIXED-APP.bat, then run this file again.
  pause
  exit /b 1
)

echo [2/5] Clearing old Elite on port 8080...
if exist "%CD%\swimiq\scripts\kill-elite-port.ps1" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%CD%\swimiq\scripts\kill-elite-port.ps1"
)
echo.

echo [3/5] Starting Elite server...
echo A NEW black window titled "Elite Video Lab" will open.
echo DO NOT CLOSE THAT WINDOW.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%CD%\swimiq\scripts\start-elite-and-wait.ps1"
if errorlevel 1 (
  echo.
  echo [FAIL] Elite is not answering on http://127.0.0.1:8080
  echo Look at the Elite black window for the error.
  echo.
  echo If storage keys missing: run FIX-STORAGE.bat then this file again.
  echo If FFmpeg missing: run RESTART-ELITE-AFTER-FFMPEG.bat then this file again.
  echo.
  pause
  exit /b 1
)

echo.
echo [4/5] Elite is up on 127.0.0.1:8080
echo [5/5] Opening Chrome on localhost (NOT swimiqapp.com)...
echo Keep BOTH windows open: Elite black window + Chrome.
echo.
if not exist "%CD%\swimiq\LAUNCH-CHROME.bat" (
  echo [FAIL] Missing swimiq\LAUNCH-CHROME.bat
  pause
  exit /b 1
)
call "%CD%\swimiq\LAUNCH-CHROME.bat"
exit /b %ERRORLEVEL%
