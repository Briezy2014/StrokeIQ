@echo off
setlocal EnableExtensions
title SwimIQ - Deploy Best Times photo reader (cloud)
cd /d "%~dp0"

echo.
echo ========================================
echo  Deploy Best Times photo reader
echo ========================================
echo.
echo This fixes "Could not read best times from this photo"
echo on swimiqapp.com AND local web without relying only on Elite.
echo.
echo BEFORE running:
echo   1. Supabase - Edge Functions - Secrets must include GEMINI_API_KEY
echo   2. You will sign in to Supabase in the browser when asked
echo.
echo Deploys:
echo   - extract-best-times
echo   - analyze-swim-video  (adds photo extract fallback)
echo.
pause

call :find_supabase
if errorlevel 1 goto :no_cli

echo.
echo Using: %SB_CMD%
echo.

echo [0/3] Login + link project bryurwyeosbffvfpdbv ...
call %SB_CMD% login
if errorlevel 1 goto :fail
call %SB_CMD% link --project-ref bryurwyeosbffvfpdbv
if errorlevel 1 goto :fail

echo.
echo [1/3] Deploying extract-best-times ...
call %SB_CMD% functions deploy extract-best-times
if errorlevel 1 goto :fail

echo.
echo [2/3] Deploying analyze-swim-video (best-times fallback) ...
call %SB_CMD% functions deploy analyze-swim-video
if errorlevel 1 goto :fail

echo.
echo [OK] Cloud photo reader deployed.
echo Hard-refresh SwimIQ, then Upload best times again.
echo.
echo Optional local backup: keep START-SWIMIQ-WITH-ELITE.bat open
echo (needs GEMINI_API_KEY in services\video_analysis\.env).
pause
exit /b 0

:find_supabase
where supabase >nul 2>nul
if not errorlevel 1 (
  set "SB_CMD=supabase"
  exit /b 0
)
where npx >nul 2>nul
if not errorlevel 1 (
  set "SB_CMD=npx --yes supabase"
  exit /b 0
)
exit /b 1

:no_cli
echo.
echo [ERROR] Supabase CLI is not installed on this PC.
echo.
echo Easiest fix - install Node.js LTS, then reopen this window:
echo   1. https://nodejs.org  ^(install LTS^)
echo   2. Close this black window
echo   3. Double-click DEPLOY-EXTRACT-BEST-TIMES.bat again
echo.
echo Or in a NEW Command Prompt:
echo   npm install -g supabase
echo   then run this bat again.
echo.
pause
exit /b 1

:fail
echo.
echo [ERROR] Deploy failed.
echo   Make sure GEMINI_API_KEY is in Supabase Edge Function secrets.
echo   Then retry this bat.
pause
exit /b 1
