@echo off
title SwimIQ Launch Chrome
cd /d "%~dp0"
if exist "%~dp0SWIMIQ-CHROME-NOW.ps1" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0SWIMIQ-CHROME-NOW.ps1"
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\launch-chrome-tonight.ps1"
)
pause
