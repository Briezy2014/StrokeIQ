@echo off
title SwimIQ Launch Chrome
cd /d "%~dp0"
echo.
echo  SwimIQ - Launch Chrome
echo  Folder: %CD%
echo.
if not exist "%~dp0scripts\launch-chrome-tonight.ps1" (
  echo ERROR: Missing scripts\launch-chrome-tonight.ps1
  echo Run: git pull origin cursor/windows-chrome-spaces-fix-17e8
  pause
  exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\launch-chrome-tonight.ps1"
exit /b %ERRORLEVEL%
