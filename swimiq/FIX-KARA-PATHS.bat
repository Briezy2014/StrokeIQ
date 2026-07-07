@echo off
REM ============================================================
REM  ONE-TIME FIX for "C:\Users\Kara is not recognized"
REM ============================================================
title SwimIQ Fix Kara Paths
cd /d "%~dp0"

echo.
echo ========================================
echo  SwimIQ - FIX KARA PATHS (one time)
echo ========================================
echo  Folder: %CD%
echo.

if not exist "%~dp0scripts\kara-fix-windows-once.ps1" (
  echo ERROR: Missing scripts\kara-fix-windows-once.ps1
  echo.
  echo Run in PowerShell:
  echo   cd "%~dp0"
  echo   git pull origin cursor/windows-chrome-spaces-fix-17e8
  echo.
  pause
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\kara-fix-windows-once.ps1"
set ERR=%ERRORLEVEL%

echo.
if %ERR% neq 0 (
  echo FIX FAILED - error code %ERR%
) else (
  echo FIX COMPLETE.
  echo Close ALL PowerShell windows and VS Code, then run LAUNCH-CHROME.bat
)
echo.
pause
exit /b %ERR%
