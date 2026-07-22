@echo off
title SwimIQ - Fix Step A (download sync-v9)
cd /d "%~dp0"
set "BRANCH=cursor/dashboard-rope-schedule-fix-17e8"
set "INDEX=%~dp0supabase\functions\analyze-swim-video\index.ts"
set "DIAG=%~dp0scripts\diagnose-gemini.js"
set "BASE=https://raw.githubusercontent.com/Briezy2014/StrokeIQ/%BRANCH%/swimiq"

echo.
echo ============================================================
echo   Fix STEP A only - download sync-v9 server code
echo ============================================================
echo.
echo Folder: %CD%
echo.

if exist "%INDEX%" (
  findstr /C:"2026-gemini-sync-v9" "%INDEX%" >nul 2>&1
  if not errorlevel 1 (
    echo OK - sync-v9 already on this PC.
    goto success
  )
)

if exist "%~dp0scripts\sync-gemini-deploy-code.ps1" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\sync-gemini-deploy-code.ps1" -SwimIqRoot "%~dp0"
  if not errorlevel 1 goto verify
)

echo PowerShell sync failed or missing - trying direct GitHub download...
if not exist "%~dp0supabase\functions\analyze-swim-video" mkdir "%~dp0supabase\functions\analyze-swim-video"
if not exist "%~dp0scripts" mkdir "%~dp0scripts"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "Invoke-WebRequest -Uri '%BASE%/supabase/functions/analyze-swim-video/index.ts' -OutFile '%INDEX%' -UseBasicParsing; ^
   Invoke-WebRequest -Uri '%BASE%/scripts/diagnose-gemini.js' -OutFile '%DIAG%' -UseBasicParsing"

:verify
if not exist "%INDEX%" (
  echo ERROR - Could not create index.ts
  goto fail
)
findstr /C:"2026-gemini-sync-v9" "%INDEX%" >nul 2>&1
if errorlevel 1 (
  echo ERROR - Downloaded file but sync-v9 not found inside.
  echo Check internet, then run FIX-GIT-PULL.bat and try again.
  goto fail
)

:success
echo.
echo SUCCESS - sync-v9 code is on this PC.
echo Next: double-click KARA-GEMINI-FIX-NOW.bat
echo.
pause
exit /b 0

:fail
echo.
echo FAILED. Try in order:
echo   1. FIX-GIT-PULL.bat
echo   2. RESTORE-SCRIPTS.bat
echo   3. Run this file again
echo.
pause
exit /b 1
