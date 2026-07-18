@echo off
title SwimIQ - Kara Click This
cd /d "%~dp0"
echo.
echo ========================================
echo  SwimIQ - Kara Click This
echo ========================================
echo  (Same as LAUNCH-CHROME or SWIMIQ-CHROME-NOW)
echo ========================================
echo.

if exist "%~dp0LAUNCH-CHROME.bat" (
  call "%~dp0LAUNCH-CHROME.bat"
  exit /b %ERRORLEVEL%
)
if exist "%~dp0SWIMIQ-CHROME-NOW.bat" (
  call "%~dp0SWIMIQ-CHROME-NOW.bat"
  exit /b %ERRORLEVEL%
)
if exist "%~dp0scripts\launch-chrome-kara.ps1" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\launch-chrome-kara.ps1"
  goto done
)
if exist "%~dp0SWIMIQ-CHROME-NOW.ps1" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0SWIMIQ-CHROME-NOW.ps1"
  goto done
)

echo [ERROR] No launcher found. You should have LAUNCH-CHROME.bat or SWIMIQ-CHROME-NOW.bat
echo in this folder. Run: git pull

:done
echo.
pause
