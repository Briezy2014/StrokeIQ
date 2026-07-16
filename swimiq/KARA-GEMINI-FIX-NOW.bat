@echo off
title SwimIQ - KARA fix Gemini video (all steps)
cd /d "%~dp0"
set "SUPABASE_CMD=npx supabase"
set "BRANCH=cursor/dashboard-rope-schedule-fix-17e8"
set "PROJECT_REF=bryurwyeosbffvfpdpbv"

call :EnsureVideoDbFixFiles
if not exist "%~dp0FIX-VIDEO-DATABASE.bat" (
  echo.
  echo [ERROR] Could not create FIX-VIDEO-DATABASE.bat on this PC.
  echo Double-click RESTORE-SCRIPTS.bat, then run this file again.
  echo.
  pause
  exit /b 1
)

echo.
echo ============================================================
echo   KARA - Fix Gemini video analysis (run this whole file)
echo ============================================================
echo.
echo Folder: %CD%
echo.

echo STEP A - Get latest stream-v6 code from GitHub (required)...
call :SyncDeployCodeFromGitHub
if errorlevel 1 (
  echo.
  echo [ERROR] Could not download stream-v6 server code.
  echo   1. RESTORE-SCRIPTS.bat
  echo   2. FIX-GIT-PULL.bat
  echo   3. Run this file again
  pause
  exit /b 1
)
echo [OK] Local code is 2026-gemini-stream-v6 — ready to deploy
echo.

echo STEP 0 - Video database (Supabase website, once if not done)
echo   Opening KARA-PASTE-THIS-IN-SUPABASE.txt ...
start notepad "%~dp0KARA-PASTE-THIS-IN-SUPABASE.txt"
echo.
set /p SQLDONE="Already ran SQL in Supabase SQL Editor? (Y/N): "
if /i not "%SQLDONE%"=="Y" (
  echo Run SQL first, then double-click this file again.
  pause
  exit /b 0
)

echo.
echo NO Android Studio. NO new API key unless diagnosis says so.
echo.
pause

where node >nul 2>&1
if errorlevel 1 (
  echo STEP 1 FAILED: Node.js not installed — install from nodejs.org, restart PC.
  start https://nodejs.org
  pause
  exit /b 1
)

echo.
echo STEP 1 of 5 - Installing Supabase tools...
call npm install supabase --save-dev
if errorlevel 1 (
  echo STEP 1 FAILED.
  pause
  exit /b 1
)
echo STEP 1 OK

echo.
echo STEP 2 of 5 - Log in to Supabase (browser opens)...
echo Use the Google account for SwimIQ project %PROJECT_REF%
call %SUPABASE_CMD% login
if errorlevel 1 (
  echo STEP 2 FAILED.
  pause
  exit /b 1
)
echo STEP 2 OK

echo.
echo STEP 3 of 5 - Link SwimIQ project...
call %SUPABASE_CMD% link --project-ref %PROJECT_REF%
if errorlevel 1 (
  echo STEP 3 FAILED - wrong Supabase account?
  pause
  exit /b 1
)
echo STEP 3 OK

echo.
echo STEP 4 of 5 - Deploy stream-v6 video server to Supabase...
call %SUPABASE_CMD% functions deploy analyze-swim-video --project-ref %PROJECT_REF%
if errorlevel 1 (
  echo STEP 4 FAILED - check GEMINI_API_KEY in Supabase Edge Function secrets.
  pause
  exit /b 1
)
echo STEP 4 OK — waiting 15 seconds for server to update...
timeout /t 15 /nobreak >nul

echo.
echo STEP 5 of 5 - Verify version MUST be 2026-gemini-stream-v6 ...
call :SyncDeployCodeFromGitHub
if exist "%~dp0scripts\diagnose-gemini.js" (
  node "%~dp0scripts\diagnose-gemini.js"
  set DIAG=%ERRORLEVEL%
) else (
  echo diagnose-gemini.js missing — run RESTORE-SCRIPTS.bat
  set DIAG=1
)

if exist "%~dp0GEMINI-DIAGNOSIS.txt" start notepad "%~dp0GEMINI-DIAGNOSIS.txt"

findstr /C:"2026-gemini-stream-v6" "%~dp0GEMINI-DIAGNOSIS.txt" >nul 2>&1
if errorlevel 1 (
  echo.
  echo ============================================================
  echo   DEPLOY FAILED — STILL WRONG VERSION ON SERVER
  echo ============================================================
  echo.
  echo If you still see auto-model-v3 in Notepad:
  echo   - Wrong Supabase login? Use the Google account for SwimIQ
  echo   - Run this ENTIRE file again from the top
  echo   - Or screenshot this window for support
  echo.
  pause
  exit /b 1
)

echo.
echo ============================================================
echo   SUCCESS - Server is stream-v6 (correct version)
echo ============================================================
echo.
echo NOW: KARA-CLICK-THIS.bat - Video tab - Analyze again
echo Use clips under 25 MB / ~30 seconds on web.
echo.
pause
exit /b 0

:SyncDeployCodeFromGitHub
git fetch origin %BRANCH% 2>nul
if errorlevel 1 exit /b 1
git checkout origin/%BRANCH% -- supabase/functions/analyze-swim-video/ 2>nul
git checkout origin/%BRANCH% -- scripts/diagnose-gemini.js 2>nul
findstr /C:"2026-gemini-stream-v6" "%~dp0supabase\functions\analyze-swim-video\index.ts" >nul 2>&1
if errorlevel 1 exit /b 1
exit /b 0

:EnsureVideoDbFixFiles
git fetch origin %BRANCH% 2>nul
git checkout origin/%BRANCH% -- scripts/ensure-video-db-fix.ps1 scripts/ensure-video-db-fix.cmd 2>nul
if exist "%~dp0scripts\ensure-video-db-fix.cmd" (
  call "%~dp0scripts\ensure-video-db-fix.cmd"
  exit /b 0
)
if exist "%~dp0scripts\ensure-video-db-fix.ps1" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\ensure-video-db-fix.ps1" -SwimIqRoot "%~dp0"
)
exit /b 0
