@echo off
title SwimIQ Launch Chrome
cd /d "%~dp0"

echo.
echo ========================================
echo  SwimIQ - LAUNCH CHROME
echo ========================================
echo  Folder: %CD%
echo.

if not exist "%~dp0scripts\launch-chrome-tonight.ps1" (
  echo ERROR: Missing scripts\launch-chrome-tonight.ps1
  echo.
  echo Double-click RESTORE-SCRIPTS.bat first.
  echo.
  pause
  exit /b 1
)

echo Starting launcher...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\launch-chrome-tonight.ps1"
set ERR=%ERRORLEVEL%

echo.
if %ERR% neq 0 (
  echo ========================================
  echo  LAUNCH FAILED - error code %ERR%
  echo ========================================
  echo.
  echo 1. Double-click FIX-KARA-PATHS.bat
  echo 2. Close ALL PowerShell and VS Code
  echo 3. Double-click LAUNCH-CHROME.bat again
  echo.
) else (
  echo Chrome session ended.
  echo.
)

pause
exit /b %ERR%
