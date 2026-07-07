@echo off
REM ============================================================
REM  SwimIQ — ONE-CLICK Chrome preview (Kara / Windows / spaces)
REM  Double-click this file. Do not run flutter run manually.
REM ============================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\launch-chrome-tonight.ps1"
if errorlevel 1 (
  echo.
  echo Something failed. Read the red/yellow messages above.
  pause
)
