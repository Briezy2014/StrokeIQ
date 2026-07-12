@echo off
title SwimIQ - Deploy Gemini Video Analysis
cd /d "%~dp0"
set "SUPABASE_CMD=supabase"

echo.
echo ========================================
echo  Fix Video Lab AI (Gemini + large clips)
echo ========================================
echo.
echo This updates YOUR Supabase server so Gemini can watch uploaded videos.
echo Adding the API key in the browser is NOT enough - you must run this once.
echo.
echo BEFORE running:
echo   1. Google AI Studio - Gemini API key (AIza...)
echo   2. Supabase Dashboard - Edge Functions - Secrets:
echo        Name: GEMINI_API_KEY  Value: your AIza key
echo   3. Supabase CLI - if deploy failed before, run INSTALL-SUPABASE-CLI.bat first
echo.
echo Project ref: bryurwyeosbffvfpdpbv
echo.
pause

where supabase >nul 2>&1
if errorlevel 1 (
  where npx >nul 2>&1
  if errorlevel 1 goto :no_cli
  call npx supabase --version >nul 2>&1
  if errorlevel 1 goto :no_cli
  set "SUPABASE_CMD=npx supabase"
  echo.
  echo Using local CLI via npx supabase
)

echo.
echo Step 1 - Log in to Supabase (browser may open)...
%SUPABASE_CMD% login
if errorlevel 1 (
  echo.
  echo Login failed. Run INSTALL-SUPABASE-CLI.bat then try again.
  pause
  exit /b 1
)

echo.
echo Step 2 - Link your SwimIQ project...
%SUPABASE_CMD% link --project-ref bryurwyeosbffvfpdpbv
if errorlevel 1 (
  echo.
  echo Link failed. Check you are logged into the correct Supabase account.
  pause
  exit /b 1
)

echo.
echo Step 3 - Deploying analyze-swim-video...
%SUPABASE_CMD% functions deploy analyze-swim-video
if errorlevel 1 goto :fail

echo.
echo ========================================
echo  SUCCESS
echo ========================================
echo.
echo Next in SwimIQ:
echo   1. Video tab - open your clip
echo   2. Tap ANALYZE again (wait up to 90 seconds)
echo.
echo You should see: Gemini - frame-by-frame video analysis
echo NOT: Notes-based estimate (Gemini unavailable)
echo.
pause
exit /b 0

:no_cli
echo.
echo [ERROR] Supabase CLI not found.
echo.
echo FIX: Double-click INSTALL-SUPABASE-CLI.bat in this folder first.
echo      Then run this file again.
echo.
pause
exit /b 1

:fail
echo.
echo [ERROR] Deploy failed.
echo   - Run INSTALL-SUPABASE-CLI.bat if you have not yet
echo   - Run supabase login
echo   - Confirm GEMINI_API_KEY is in Supabase Secrets
echo.
pause
exit /b 1
