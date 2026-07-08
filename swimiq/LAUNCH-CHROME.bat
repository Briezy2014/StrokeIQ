@echo off
title SwimIQ Launch Chrome
cd /d "%~dp0"
if exist "%~dp0SWIMIQ-CHROME-NOW.ps1" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0SWIMIQ-CHROME-NOW.ps1"
) else if exist "%~dp0scripts\launch-chrome-tonight.ps1" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\launch-chrome-tonight.ps1"
) else (
  echo.
  echo ERROR: No launcher found.
  echo Double-click RESTORE-SCRIPTS.bat or run:
  echo   git pull origin cursor/windows-chrome-spaces-fix-17e8
  echo.
)
pause
