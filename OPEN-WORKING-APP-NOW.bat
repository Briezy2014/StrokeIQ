@echo off
setlocal EnableExtensions
title SwimIQ WORKING APP - localhost only
cd /d "%~dp0"

echo.
echo ############################################################
echo #  WORKING APP - localhost only                           #
echo #  Close swimiqapp.com first                              #
echo ############################################################
echo.
echo This starts Elite analysis on THIS PC, then opens Chrome.
echo If you see a black banner about 127.0.0.1:8080, run
echo FIX-ANALYSIS-NOW.bat instead.
echo.

echo [1/3] Updating files from GitHub...
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

if not exist "%CD%\swimiq\.env" (
  echo [FAIL] Missing swimiq\.env
  if exist "%CD%\swimiq\.env.example" copy /Y "%CD%\swimiq\.env.example" "%CD%\swimiq\.env" >nul
)

echo [2/3] Coaching key check (optional - does NOT block analysis)...
if exist "%CD%\swimiq\scripts\check-gemini-key.ps1" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%CD%\swimiq\scripts\check-gemini-key.ps1"
  if errorlevel 1 (
    echo [WARN] GEMINI_API_KEY missing in swimiq\.env
    echo       Analysis will still run. Coaching tips need the key later.
  ) else (
    echo [OK] GEMINI_API_KEY found in swimiq\.env
  )
) else (
  echo [WARN] check-gemini-key.ps1 missing - skipping
)
echo.

echo [3/3] Starting Elite server FIRST (required for Analyze)...
echo A black Elite window must stay OPEN.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%CD%\swimiq\scripts\start-elite-and-wait.ps1"
if errorlevel 1 (
  echo.
  echo [FAIL] Elite is not answering on http://127.0.0.1:8080
  echo.
  echo Do this:
  echo   1. Look at the Elite black window for errors
  echo   2. Double-click FIX-ANALYSIS-NOW.bat
  echo.
  if exist "%CD%\FIX-ANALYSIS-NOW.bat" (
    echo Opening FIX-ANALYSIS-NOW.bat next...
    pause
    call "%CD%\FIX-ANALYSIS-NOW.bat"
    exit /b %ERRORLEVEL%
  )
  pause
  exit /b 1
)

echo.
echo [OK] Elite is up. Opening Chrome on localhost...
echo Address bar MUST be 127.0.0.1 or localhost - NOT swimiqapp.com
echo Keep the Elite black window OPEN while you analyze.
echo.
call "%CD%\swimiq\LAUNCH-CHROME.bat"
exit /b %ERRORLEVEL%
