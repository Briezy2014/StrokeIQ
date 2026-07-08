@echo off
title SwimIQ Fix Paths
cd /d "%~dp0"
echo.
echo  SwimIQ - Fix Kara Paths (once)
echo  Folder: %CD%
echo.
if not exist "%~dp0scripts\kara-fix-windows-once.ps1" (
  echo ERROR: Missing scripts\kara-fix-windows-once.ps1
  echo Run: git pull origin cursor/windows-chrome-spaces-fix-17e8
  pause
  exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\kara-fix-windows-once.ps1"
exit /b %ERRORLEVEL%
