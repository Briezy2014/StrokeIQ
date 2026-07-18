@echo off
title SwimIQ Fix Paths
cd /d "%~dp0swimiq"
if not exist "%~dp0swimiq\FIX-KARA-PATHS.bat" (
  echo.
  echo [ERROR] swimiq\FIX-KARA-PATHS.bat not found.
  echo.
  echo Run this in PowerShell first:
  echo   cd "%~dp0"
  echo   git pull origin main
  echo.
  pause
  exit /b 1
)
call "%~dp0swimiq\FIX-KARA-PATHS.bat"
