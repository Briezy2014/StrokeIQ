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

echo STEP A - Get latest sync-v11 code from GitHub (required)...
call :SyncDeployCodeFromGitHub
if errorlevel 1 (
  echo.
  echo [ERROR] Could not download sync-v11 server code.
  echo.
  echo TRY IN ORDER:
  echo   1. FIX-GIT-PULL.bat
  echo   2. RESTORE-SCRIPTS.bat
  echo   3. Run this file again
  echo.
  echo If git keeps failing, Step A can still work via direct GitHub download —
  echo check your internet connection and try again.
  pause
  exit /b 1
)
echo [OK] Local code is 2026-gemini-sync-v11 — ready to deploy
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
  echo.
  echo If the browser said "up to 20 personal access tokens":
  echo   1. Open https://supabase.com/dashboard/account/tokens
  echo   2. Delete old CLI tokens ^(keep 1-2 recent^)
  echo   3. Run this file again from Step 2
  echo   See KARA-FIX-SUPABASE-LOGIN.txt for full steps.
  start notepad "%~dp0KARA-FIX-SUPABASE-LOGIN.txt"
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
echo STEP 4 of 5 - Deploy sync-v11 video server to Supabase...
call %SUPABASE_CMD% functions deploy analyze-swim-video --project-ref %PROJECT_REF%
if errorlevel 1 (
  echo STEP 4 FAILED - check GEMINI_API_KEY in Supabase Edge Function secrets.
  pause
  exit /b 1
)
echo STEP 4 OK — waiting 15 seconds for server to update...
timeout /t 15 /nobreak >nul

echo.
echo STEP 5 of 5 - Verify version MUST be 2026-gemini-sync-v11 ...
call :SyncDeployCodeFromGitHub
if exist "%~dp0scripts\diagnose-gemini.js" (
  node "%~dp0scripts\diagnose-gemini.js"
  set DIAG=%ERRORLEVEL%
) else (
  echo diagnose-gemini.js missing — run RESTORE-SCRIPTS.bat
  set DIAG=1
)

if exist "%~dp0GEMINI-DIAGNOSIS.txt" start notepad "%~dp0GEMINI-DIAGNOSIS.txt"

findstr /C:"2026-gemini-sync-v11" "%~dp0GEMINI-DIAGNOSIS.txt" >nul 2>&1
if errorlevel 1 (
  echo.
  echo ============================================================
  echo   DEPLOY FAILED — STILL WRONG VERSION ON SERVER
  echo ============================================================
  echo.
  echo If you still see auto-model-v3 or stream-v8 in Notepad:
  echo   - Wrong Supabase login? Use the Google account for SwimIQ
  echo   - Run this ENTIRE file again from the top
  echo   - Or screenshot this window for support
  echo.
  pause
  exit /b 1
)

echo.
echo ============================================================
echo   SUCCESS - Server is sync-v11 (correct version)
echo ============================================================
echo.
echo NOW: KARA-CLICK-THIS.bat - Video tab - Analyze again
echo Use phone race clips up to ~100 MB on web (typical 15-60s clips).
echo Keep the tab open up to 2 minutes while Gemini runs.
echo.
pause
exit /b 0

:SyncDeployCodeFromGitHub
if exist "%~dp0scripts\sync-gemini-deploy-code.cmd" (
  call "%~dp0scripts\sync-gemini-deploy-code.cmd"
  exit /b %ERRORLEVEL%
)
if exist "%~dp0scripts\sync-gemini-deploy-code.ps1" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\sync-gemini-deploy-code.ps1" -SwimIqRoot "%~dp0"
  exit /b %ERRORLEVEL%
)
for /f "delims=" %%i in ('git rev-parse --show-toplevel 2^>nul') do set "GITROOT=%%i"
if not defined GITROOT exit /b 1
pushd "%GITROOT%"
if exist "swimiq\supabase\functions\analyze-swim-video\index.ts" (
  set "GPREFIX=swimiq/"
) else (
  set "GPREFIX="
)
git fetch origin %BRANCH% 2>nul
if errorlevel 1 (
  popd
  exit /b 1
)
git checkout origin/%BRANCH% -- %GPREFIX%supabase/functions/analyze-swim-video/ 2>nul
git checkout origin/%BRANCH% -- %GPREFIX%scripts/diagnose-gemini.js 2>nul
popd
findstr /C:"2026-gemini-sync-v11" "%~dp0supabase\functions\analyze-swim-video\index.ts" >nul 2>&1
if errorlevel 1 exit /b 1
exit /b 0

:EnsureVideoDbFixFiles
if exist "%~dp0scripts\sync-gemini-deploy-code.ps1" (
  git fetch origin %BRANCH% 2>nul
)
git fetch origin %BRANCH% 2>nul
for /f "delims=" %%i in ('git rev-parse --show-toplevel 2^>nul') do set "GITROOT=%%i"
if defined GITROOT if exist "%GITROOT%\swimiq\scripts" (
  git checkout origin/%BRANCH% -- swimiq/scripts/ensure-video-db-fix.ps1 swimiq/scripts/ensure-video-db-fix.cmd swimiq/scripts/sync-gemini-deploy-code.ps1 swimiq/scripts/sync-gemini-deploy-code.cmd swimiq/KARA-FIX-STEP-A.bat 2>nul
)
git checkout origin/%BRANCH% -- scripts/ensure-video-db-fix.ps1 scripts/ensure-video-db-fix.cmd scripts/sync-gemini-deploy-code.ps1 scripts/sync-gemini-deploy-code.cmd KARA-FIX-STEP-A.bat 2>nul
if exist "%~dp0scripts\ensure-video-db-fix.cmd" (
  call "%~dp0scripts\ensure-video-db-fix.cmd"
  exit /b 0
)
if exist "%~dp0scripts\ensure-video-db-fix.ps1" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\ensure-video-db-fix.ps1" -SwimIqRoot "%~dp0"
)
exit /b 0
