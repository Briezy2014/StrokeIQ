@echo off
title SwimIQ - KARA fix Gemini video (all steps)
cd /d "%~dp0"
set "SUPABASE_CMD=npx supabase"

echo.
echo ============================================================
echo   KARA - Fix Gemini video analysis (run this whole file)
echo ============================================================
echo.
echo This makes Gemini WATCH uploaded swim videos.
echo You already added GEMINI_API_KEY in Supabase - good.
echo This file finishes the server update you still need.
echo.
pause

where node >nul 2>&1
if errorlevel 1 (
  echo.
  echo STEP 0 FAILED: Node.js not installed.
  echo Download from https://nodejs.org (green LTS button), install, restart PC.
  echo Then double-click this file again.
  pause
  exit /b 1
)

echo.
echo STEP 1 of 4 - Installing Supabase tools in this folder...
call npm install supabase --save-dev
if errorlevel 1 (
  echo STEP 1 FAILED.
  pause
  exit /b 1
)
echo STEP 1 OK

echo.
echo STEP 2 of 4 - Log in to Supabase (browser will open)...
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
echo NOW in SwimIQ:
echo   1. Video tab
echo   2. Tap ANALYZE on your clip again
echo   3. Wait 90 seconds
echo.
echo You should see: Gemini - frame-by-frame video analysis
echo Scores will match YOUR video, not generic fly coaching.
echo.
pause
