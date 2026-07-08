@echo off
title SwimIQ - Kara Click This
cd /d "%~dp0swimiq"
if not exist "%~dp0swimiq\KARA-CLICK-THIS.bat" (
  echo.
  echo [ERROR] swimiq\KARA-CLICK-THIS.bat not found.
  echo.
  echo Run this in PowerShell first:
  echo   cd "%~dp0"
  echo   git pull origin main
  echo.
  pause
  exit /b 1
)
call "%~dp0swimiq\KARA-CLICK-THIS.bat"
