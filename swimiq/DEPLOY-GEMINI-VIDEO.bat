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
echo.
echo BEFORE running:
echo   1. Gemini API key in Supabase Secrets as GEMINI_API_KEY
echo   2. This script installs Supabase CLI automatically if needed
echo.
echo Project ref: bryurwyeosbffvfpdpbv
echo.
pause

call :resolve_cli
if errorlevel 1 exit /b 1

echo.
echo Step 1 - Log in to Supabase (browser may open)...
%SUPABASE_CMD% login
if errorlevel 1 (
  echo Login failed. Try again.
  pause
  exit /b 1
)

echo.
echo Step 2 - Link your SwimIQ project...
%SUPABASE_CMD% link --project-ref bryurwyeosbffvfpdpbv
if errorlevel 1 (
  echo Link failed. Use the Supabase account that owns this project.
  pause
  exit /b 1
)

echo.
echo Step 3 - Deploying analyze-swim-video...
%SUPABASE_CMD% functions deploy analyze-swim-video
if errorlevel 1 (
  echo Deploy failed. Confirm GEMINI_API_KEY is in Supabase Secrets.
  pause
  exit /b 1
)

echo.
echo ========================================
echo  SUCCESS
echo ========================================
echo.
echo In SwimIQ: Video tab - Analyze again - wait up to 90 seconds.
echo Look for: Gemini - frame-by-frame video analysis
echo.
pause
exit /b 0

:resolve_cli
where supabase >nul 2>&1
if not errorlevel 1 exit /b 0

where npx >nul 2>&1
if errorlevel 1 goto :need_node

call npx supabase --version >nul 2>&1
if not errorlevel 1 (
  set "SUPABASE_CMD=npx supabase"
  echo Using npx supabase
  exit /b 0
)

echo.
echo Installing Supabase CLI in this folder (one time)...
where node >nul 2>&1
if errorlevel 1 goto :need_node

call npm install supabase --save-dev
if errorlevel 1 (
  echo npm install failed.
  exit /b 1
)

set "SUPABASE_CMD=npx supabase"
call npx supabase --version
if errorlevel 1 (
  echo.
  echo Still could not run Supabase CLI.
  echo Open PowerShell in this folder and run:
  echo   npm install supabase --save-dev
  echo   npx supabase login
  echo   npx supabase link --project-ref bryurwyeosbffvfpdpbv
  echo   npx supabase functions deploy analyze-swim-video
  exit /b 1
)
echo CLI ready.
exit /b 0

:need_node
echo.
echo Node.js not found. Install from https://nodejs.org (LTS), then run this again.
echo.
echo OR after git pull, double-click KARA-INSTALL-SUPABASE.bat
exit /b 1
