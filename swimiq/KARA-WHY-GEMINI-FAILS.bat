@echo off
title SwimIQ - WHY GEMINI FAILS
cd /d "%~dp0"
set "OUT=%~dp0GEMINI-DIAGNOSIS.txt"
echo.
echo ============================================================
echo   KARA - Find out WHY video AI is broken
echo ============================================================
echo.
echo Writes GEMINI-DIAGNOSIS.txt - opens in Notepad when done.
echo MUST show version 2026-gemini-stream-v5 (NOT auto-model-v3).
echo Uses Node.js (NOT PowerShell - no more red script errors).
echo.
pause

where node >nul 2>&1
if errorlevel 1 (
  echo.
  echo NODE.JS NOT INSTALLED
  echo.
  echo 1. Opening nodejs.org ...
  start https://nodejs.org
  echo 2. Install LTS, restart PC, run this file again.
  echo.
  (
    echo ERROR: Node.js required for diagnosis.
    echo Install from https://nodejs.org then run KARA-WHY-GEMINI-FAILS.bat again.
  ) > "%OUT%"
  start notepad "%OUT%"
  pause
  exit /b 1
)

if not exist "%~dp0scripts\diagnose-gemini.js" (
  echo.
  echo [ERROR] Missing scripts\diagnose-gemini.js
  echo Double-click RESTORE-SCRIPTS.bat first.
  pause
  exit /b 1
)

echo Updating diagnosis script from GitHub...
git fetch origin cursor/dashboard-rope-schedule-fix-17e8 2>nul
git checkout origin/cursor/dashboard-rope-schedule-fix-17e8 -- scripts/diagnose-gemini.js 2>nul

node "%~dp0scripts\diagnose-gemini.js"
set ERR=%ERRORLEVEL%

echo.
if %ERR% EQU 0 (
  echo DONE - opening GEMINI-DIAGNOSIS.txt
) else (
  echo Had errors - read GEMINI-DIAGNOSIS.txt anyway.
)
if exist "%OUT%" start notepad "%OUT%"
pause
exit /b %ERR%
