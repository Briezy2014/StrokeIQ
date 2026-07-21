@echo off
setlocal EnableExtensions
title SwimIQ + Elite Video Lab
cd /d "%~dp0"

set "LOG=%CD%\elite-start.log"
set "ELITE_RC=0"
echo ===== SwimIQ start %DATE% %TIME% ===== > "%LOG%"

echo.
echo ############################################################
echo #  START SwimIQ WITH Elite                                #
echo #  This window STAYS OPEN so you can read errors          #
echo ############################################################
echo.
echo Log: %LOG%
echo.

echo [1/4] Updating folder from GitHub...
git -C "%CD%" fetch origin cursor/dryland-power-index-b7ef >> "%LOG%" 2>&1
if errorlevel 1 (
  echo [WARN] git fetch failed - using files already on disk.
) else (
  git -C "%CD%" checkout -f cursor/dryland-power-index-b7ef >> "%LOG%" 2>&1
  if not errorlevel 1 git -C "%CD%" reset --hard origin/cursor/dryland-power-index-b7ef >> "%LOG%" 2>&1
)
echo [OK] Ready.
echo.

echo [2/4] One GEMINI_API_KEY line only...
if exist "%CD%\swimiq\scripts\fix-one-gemini-key.ps1" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%CD%\swimiq\scripts\fix-one-gemini-key.ps1"
) else (
  echo [WARN] Key helper not found yet - continue.
)
echo.

if not exist "%CD%\swimiq\scripts\start-elite-and-wait.ps1" (
  echo [FAIL] Missing swimiq\scripts\start-elite-and-wait.ps1
  echo Run GET-LATEST-FIXED-APP.bat when Wi-Fi works, then try again.
  goto :Hold
)

echo [3/4] Starting Elite server ONCE (not in a loop)...
echo.
echo A second window will open: "Elite Video Lab - Analysis Server"
echo That window must STAY OPEN. Do not close it.
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%CD%\swimiq\scripts\start-elite-and-wait.ps1"
set "ELITE_RC=%ERRORLEVEL%"
echo Elite wait exit code %ELITE_RC%>> "%LOG%"
if "%ELITE_RC%"=="0" goto :Chrome
if "%ELITE_RC%"=="2" (
  echo.
  echo [FAIL] Supabase URL/anon key missing in swimiq\.env
  echo Edit that file, save, then run this bat once more.
  goto :Hold
)
if "%ELITE_RC%"=="3" (
  echo.
  echo [FAIL] FFmpeg is not installed / not on PATH.
  echo Install once:  winget install Gyan.FFmpeg
  echo Then close this window and run this bat once more.
  goto :Hold
)
echo.
echo [FAIL] Elite did not become ready. Exit code %ELITE_RC%
echo Look at the Elite Video Lab window for the real error.
echo Also open elite-start.log in Notepad.
goto :Hold

:Chrome
echo.
echo [4/4] Elite is up. Starting SwimIQ app (Chrome opens when ready)...
echo First compile can take 2-4 minutes. Wait for Chrome - do not rush.
echo Address must be 127.0.0.1  (not swimiqapp.com)
echo.
if not exist "%CD%\swimiq\LAUNCH-CHROME.bat" (
  echo [FAIL] Missing swimiq\LAUNCH-CHROME.bat
  goto :Hold
)
call "%CD%\swimiq\LAUNCH-CHROME.bat"
echo.
echo ############################################################
echo #  Keep these windows OPEN:                               #
echo #   1) Elite Video Lab - Analysis Server                  #
echo #   2) SwimIQ WEB SERVER - DO NOT CLOSE                   #
echo #  If browser says refused to connect:                    #
echo #     double-click OPEN-SWIMIQ-NOW.bat                    #
echo ############################################################
echo.

:Hold
echo.
echo --- Press any key to close THIS starter window ---
echo --- Leave Elite + WEB SERVER windows OPEN ---
echo Log: %LOG%
echo.
pause
exit /b %ELITE_RC%
