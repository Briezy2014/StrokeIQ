@echo off
REM ============================================================
REM  SwimIQ — ONE-CLICK Chrome preview
REM  Double-click THIS file in the swimiq folder.
REM ============================================================
title SwimIQ Launch Chrome
cd /d "%~dp0"

echo.
echo ========================================
echo  SwimIQ - LAUNCH CHROME
echo ========================================
echo  Folder: %CD%
echo.

if not exist "%~dp0scripts\launch-chrome-tonight.ps1" (
  echo ERROR: Missing scripts\launch-chrome-tonight.ps1
  echo.
  echo Run these in PowerShell first:
  echo   cd "%~dp0"
  echo   git pull origin cursor/windows-chrome-spaces-fix-17e8
  echo.
  echo Then double-click this file again.
  echo.
  pause
  exit /b 1
)

echo Starting launcher...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\launch-chrome-tonight.ps1"
set ERR=%ERRORLEVEL%

echo.
if %ERR% neq 0 (
  echo ========================================
  echo  LAUNCH FAILED - error code %ERR%
  echo ========================================
  echo.
  echo If you see Kara Williams / C:\Users\Kara errors:
  echo   1. Double-click FIX-KARA-PATHS.bat first
  echo   2. Close ALL PowerShell and VS Code
  echo   3. Double-click LAUNCH-CHROME.bat again
  echo.
) else (
  echo Chrome session ended.
  echo.
)

pause
exit /b %ERR%
