@echo off
title SwimIQ Launch Chrome
cd /d "%~dp0"
call "%~dp0scripts\ensure-logo-bats.cmd" 2>nul
if exist "%~dp0scripts\launch-chrome-kara.ps1" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\launch-chrome-kara.ps1"
) else if exist "%~dp0SWIMIQ-CHROME-NOW.ps1" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0SWIMIQ-CHROME-NOW.ps1"
) else if exist "%~dp0scripts\launch-chrome-tonight.ps1" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\launch-chrome-tonight.ps1"
) else (
  echo.
  echo ERROR: No launcher found.
  echo Double-click KARA-SEE-UPDATES-NOW.bat first to pull updates.
  echo.
)
pause
