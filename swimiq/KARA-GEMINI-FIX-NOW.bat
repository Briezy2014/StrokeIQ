@echo off
title SwimIQ - KARA fix Gemini video (all steps)
cd /d "%~dp0"
set "SUPABASE_CMD=npx supabase"

echo.
echo ============================================================
echo   KARA - Fix Gemini video analysis (run this whole file)
echo ============================================================
echo.
echo Folder: %CD%
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
  echo STEP 0 FAILED: Node.js not installed.
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
echo STEP 4 of 4 - Deploy video analysis to your server...
call %SUPABASE_CMD% functions deploy analyze-swim-video
if errorlevel 1 (
  echo STEP 4 FAILED - is GEMINI_API_KEY in Supabase - Edge Functions - Secrets?
  pause
  exit /b 1
)

echo.
echo ============================================================
echo   SUCCESS - Server is updated
echo ============================================================
echo.
echo NOW:
echo   1. Double-click KARA-CLICK-THIS.bat (opens SwimIQ in Chrome)
echo   2. Video tab
echo   3. Tap Test video server - should say Video server ready
echo   4. Tap ANALYZE on your clip - wait 90 seconds
echo.
echo You should see: Gemini - frame-by-frame video analysis
echo Server now auto-picks the newest Gemini Flash model your API key allows.
echo You only need GEMINI_API_KEY in Supabase - NOT GEMINI_MODEL.
echo If errors continue: read KARA-FIX-GEMINI-QUOTA.txt
echo.
pause
