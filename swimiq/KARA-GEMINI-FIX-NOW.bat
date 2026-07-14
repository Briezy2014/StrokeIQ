@echo off
title SwimIQ - KARA fix Gemini video (all steps)
cd /d "%~dp0"
set "SUPABASE_CMD=npx supabase"

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
echo STEP 0 FIRST - Video database (Supabase website, 2 minutes)
echo   Delete broken? Analyze not saving? You MUST run the SQL once.
echo.
echo Opening KARA-PASTE-THIS-IN-SUPABASE.txt in Notepad...
echo   1. Copy from ---- START SQL ---- through ---- END SQL ----
echo   2. Supabase.com - your project - SQL Editor - paste - RUN
echo   3. Should say Success, then come back here.
echo.
start notepad "%~dp0KARA-PASTE-THIS-IN-SUPABASE.txt"
echo.
set /p SQLDONE="Did you run the SQL in Supabase and see Success? (Y/N): "
if /i not "%SQLDONE%"=="Y" (
  echo.
  echo OK - run the SQL first, then double-click this file again.
  echo You can also double-click FIX-VIDEO-DATABASE.bat anytime.
  pause
  exit /b 0
)

echo.
echo NO Command Prompt skills needed - just read and press keys.
echo NO Android Studio needed.
echo.
echo This makes Gemini WATCH uploaded swim videos.
echo You already added GEMINI_API_KEY in Supabase - good.
echo This file finishes the server update you still need.
echo.
echo If Kara Williams space errors happen: run FIX-KARA-PATHS.bat first.
echo.
pause

where node >nul 2>&1
if errorlevel 1 (
  echo.
  echo STEP 1 FAILED: Node.js not installed.
  echo.
  echo 1. Opening nodejs.org ...
  start https://nodejs.org
  echo 2. Download green LTS, install, RESTART PC.
  echo 3. Double-click KARA-DO-VIDEO-AI-NOW.bat or this file again.
  echo.
  pause
  exit /b 1
)

echo.
echo STEP 1 of 4 - Installing Supabase tools in this folder...
echo (Wait 1-2 minutes - do not close this window)
call npm install supabase --save-dev
if errorlevel 1 (
  echo STEP 1 FAILED.
  pause
  exit /b 1
)
echo STEP 1 OK

echo.
echo STEP 2 of 4 - Log in to Supabase (browser will open)...
echo Sign in with the Google account for YOUR SwimIQ Supabase project.
call %SUPABASE_CMD% login
if errorlevel 1 (
  echo STEP 2 FAILED - sign in with the Google account for your Supabase project.
  pause
  exit /b 1
)
echo STEP 2 OK

echo.
echo STEP 3 of 4 - Link SwimIQ project...
call %SUPABASE_CMD% link --project-ref bryurwyeosbffvfpdpbv
if errorlevel 1 (
  echo STEP 3 FAILED - wrong Supabase account?
  pause
  exit /b 1
)
echo STEP 3 OK

echo.
echo STEP 4 of 5 - Deploy video analysis to your server...
call %SUPABASE_CMD% functions deploy analyze-swim-video
if errorlevel 1 (
  echo STEP 4 FAILED - is GEMINI_API_KEY in Supabase - Edge Functions - Secrets?
  pause
  exit /b 1
)

echo.
echo STEP 5 of 5 - Verify server version (must be 2026-gemini-stream-v5)...
where node >nul 2>&1
if not errorlevel 1 (
  if exist "%~dp0scripts\diagnose-gemini.js" (
    node "%~dp0scripts\diagnose-gemini.js"
    echo.
    echo Read GEMINI-DIAGNOSIS.txt — if version is OLD, run this bat again.
    if exist "%~dp0GEMINI-DIAGNOSIS.txt" start notepad "%~dp0GEMINI-DIAGNOSIS.txt"
  ) else (
    echo diagnose-gemini.js missing — run RESTORE-SCRIPTS.bat then this file again.
  )
) else (
  echo Node.js needed to verify deploy — install from nodejs.org if unsure.
)

echo.
echo ============================================================
echo   SUCCESS - Server deploy finished
echo ============================================================
echo.
echo NOW:
echo   1. Double-click KARA-CLICK-THIS.bat (opens SwimIQ in Chrome)
echo   2. Video tab
echo   3. Tap ANALYZE on your clip - wait 90 seconds
echo   4. Delete is at the BOTTOM of each video card (red button)
echo.
echo You should see: Gemini - frame-by-frame video analysis
echo Server now auto-picks the newest Gemini Flash model your API key allows.
echo You only need GEMINI_API_KEY in Supabase - NOT GEMINI_MODEL.
echo If errors continue: read KARA-FIX-GEMINI-QUOTA.txt
echo.
pause
exit /b 0

:EnsureVideoDbFixFiles
git fetch origin cursor/dashboard-rope-schedule-fix-17e8 2>nul
git checkout origin/cursor/dashboard-rope-schedule-fix-17e8 -- scripts/ensure-video-db-fix.ps1 scripts/ensure-video-db-fix.cmd 2>nul
if exist "%~dp0scripts\ensure-video-db-fix.cmd" (
  call "%~dp0scripts\ensure-video-db-fix.cmd"
  exit /b 0
)
if exist "%~dp0scripts\ensure-video-db-fix.ps1" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\ensure-video-db-fix.ps1" -SwimIqRoot "%~dp0"
  exit /b 0
)
exit /b 1
