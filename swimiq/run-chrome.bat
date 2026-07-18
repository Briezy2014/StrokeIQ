@echo off
REM SwimIQ — launch Flutter web in Chrome (use this on Windows)
cd /d "%~dp0"
echo.
echo SwimIQ Flutter web launcher
echo Folder: %CD%
echo.

if exist "%~dp0scripts\swimiq-windows-paths.ps1" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run-chrome.ps1"
  if errorlevel 1 pause
  exit /b %ERRORLEVEL%
)

flutter pub get
if errorlevel 1 (
  echo.
  echo pub get failed. Your path has a space ^(Kara Williams^).
  echo 1. Double-click FIX-KARA-PATHS.bat once
  echo 2. Then double-click KARA-CLICK-THIS.bat
  echo See docs\WINDOWS_SETUP.md
  pause
  exit /b 1
)

flutter run -d chrome
if errorlevel 1 pause
