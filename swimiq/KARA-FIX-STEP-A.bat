@echo off
title SwimIQ - Fix Step A (download stream-v6)
cd /d "%~dp0"
echo.
echo ============================================================
echo   Fix STEP A only — download stream-v6 server code
echo ============================================================
echo.
echo Folder: %CD%
echo.
if exist "%~dp0scripts\sync-gemini-deploy-code.cmd" (
  call "%~dp0scripts\sync-gemini-deploy-code.cmd"
) else if exist "%~dp0scripts\sync-gemini-deploy-code.ps1" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\sync-gemini-deploy-code.ps1" -SwimIqRoot "%~dp0"
) else (
  echo [ERROR] sync-gemini-deploy-code.ps1 missing.
  echo Run RESTORE-SCRIPTS.bat or FIX-GIT-PULL.bat first.
  pause
  exit /b 1
)
if errorlevel 1 (
  echo.
  echo FAILED. Try in order:
  echo   1. FIX-GIT-PULL.bat
  echo   2. RESTORE-SCRIPTS.bat
  echo   3. Run this file again
  pause
  exit /b 1
)
echo.
echo SUCCESS — stream-v6 code is on this PC.
echo Next: double-click KARA-GEMINI-FIX-NOW.bat
echo.
pause
