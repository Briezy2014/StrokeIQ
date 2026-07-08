@echo off
title SwimIQ Restore Scripts
cd /d "%~dp0"
echo.
echo Restoring scripts folder from GitHub...
echo.
git fetch origin cursor/windows-chrome-spaces-fix-17e8
git checkout origin/cursor/windows-chrome-spaces-fix-17e8 -- scripts/
git checkout origin/cursor/windows-chrome-spaces-fix-17e8 -- LAUNCH-CHROME.bat FIX-KARA-PATHS.bat DIAGNOSE.bat restore-scripts.ps1
if errorlevel 1 (
  echo.
  echo Git failed. Run restore-scripts.ps1 instead:
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0restore-scripts.ps1"
) else (
  echo.
  echo DONE. scripts folder restored.
  dir scripts
)
echo.
pause
