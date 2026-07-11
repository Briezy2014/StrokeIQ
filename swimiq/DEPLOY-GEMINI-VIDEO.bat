@echo off
title SwimIQ - Deploy Gemini Video Analysis
cd /d "%~dp0"
echo.
echo ========================================
echo  Fix Video Lab AI (Gemini + large clips)
echo ========================================
echo.
echo This updates YOUR Supabase server so Gemini can watch uploaded videos.
echo Adding the API key in the browser is NOT enough - you must run this once.
echo.
echo BEFORE running:
echo   1. Google AI Studio - you created a Gemini API key (AIza...)
echo   2. Supabase Dashboard - Edge Functions - Secrets:
echo        Name: GEMINI_API_KEY
echo        Value: paste your AIza key
echo   3. Supabase CLI installed - see https://supabase.com/docs/guides/cli
echo.
echo Project ref: bryurwyeosbffvfpdpbv
echo.
pause

where supabase >nul 2>&1
if errorlevel 1 (
  echo.
  echo [ERROR] Supabase CLI not found.
  echo Install from: https://supabase.com/docs/guides/cli
  echo Then run: supabase login
  pause
  exit /b 1
)

echo.
echo Logging in / linking project (skip if already linked)...
supabase link --project-ref bryurwyeosbffvfpdpbv
if errorlevel 1 (
  echo.
  echo If link failed, run manually:
  echo   supabase login
  echo   supabase link --project-ref bryurwyeosbffvfpdpbv
  pause
  exit /b 1
)

echo.
echo Deploying analyze-swim-video...
supabase functions deploy analyze-swim-video
if errorlevel 1 goto :fail

echo.
echo ========================================
echo  SUCCESS
echo ========================================
echo.
echo Next in SwimIQ:
echo   1. Video tab - open the same clip
echo   2. Tap ANALYZE again (old results stay broken until you re-run)
echo   3. Wait up to 90 seconds for large videos
echo.
echo You should see: "Gemini - frame-by-frame video analysis"
echo NOT: "Notes-based estimate (Gemini unavailable)"
echo.
pause
exit /b 0

:fail
echo.
echo [ERROR] Deploy failed.
echo Try: supabase login
echo Then double-click this file again.
pause
exit /b 1
