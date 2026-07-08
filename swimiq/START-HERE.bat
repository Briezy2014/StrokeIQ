@echo off
title SwimIQ START HERE
cd /d "%~dp0"
echo.
echo ========================================
echo  SwimIQ - START HERE (Kara)
echo ========================================
echo.
echo Folder: %CD%
echo.
if not exist "%~dp0SWIMIQ-CHROME-NOW.ps1" (
  echo [MISSING] SWIMIQ-CHROME-NOW.ps1
  echo.
  echo Run in PowerShell:
  echo   cd "%CD%"
  echo   git pull origin cursor/windows-chrome-spaces-fix-17e8
  echo.
  echo Then double-click this file again.
  pause
  exit /b 1
)
echo [OK] Found SWIMIQ-CHROME-NOW.ps1
echo.
echo Opening Chrome preview - wait 1-2 minutes...
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0SWIMIQ-CHROME-NOW.ps1"
pause
