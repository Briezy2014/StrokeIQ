@echo off
title SwimIQ - Kara Click This
cd /d "%~dp0"
echo.
echo ========================================
echo  SwimIQ - Kara Click This
echo ========================================
echo.
echo Step 1: Fixing paths for Kara Williams...
echo.
if exist "%~dp0scripts\launch-chrome-kara.ps1" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\launch-chrome-kara.ps1"
  exit /b %ERRORLEVEL%
)
if exist "%~dp0SWIMIQ-CHROME-NOW.ps1" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0SWIMIQ-CHROME-NOW.ps1"
  exit /b %ERRORLEVEL%
)
if exist "%~dp0scripts\launch-chrome-tonight.ps1" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\launch-chrome-tonight.ps1"
  exit /b %ERRORLEVEL%
)
echo ERROR: No launcher found. Run RESTORE-SCRIPTS.bat
pause
exit /b 1
