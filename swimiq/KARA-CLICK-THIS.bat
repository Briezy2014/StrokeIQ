@echo off
title SwimIQ - Kara Click This
cd /d "%~dp0"
echo.
echo ========================================
echo  SwimIQ - Kara Click This
echo ========================================
echo.
echo Launching Chrome - wait 2-3 minutes...
echo.

if exist "%~dp0scripts\launch-chrome-kara.ps1" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\launch-chrome-kara.ps1"
  goto done
)
if exist "%~dp0SWIMIQ-CHROME-NOW.ps1" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0SWIMIQ-CHROME-NOW.ps1"
  goto done
)
if exist "%~dp0scripts\launch-chrome-tonight.ps1" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\launch-chrome-tonight.ps1"
  goto done
)

echo [ERROR] No launcher found.
echo Double-click RESTORE-SCRIPTS.bat first.

:done
echo.
echo Press any key to close...
pause >nul
