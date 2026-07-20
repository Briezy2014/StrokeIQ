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

set "SB="
where supabase >nul 2>nul
if not errorlevel 1 set "SB=supabase"

if not defined SB if exist "%ProgramFiles%\nodejs\npx.cmd" set "SB=npx.cmd"
if not defined SB if exist "%ProgramFiles(x86)%\nodejs\npx.cmd" set "SB=npx.cmd"
if not defined SB (
  where npx.cmd >nul 2>nul
  if not errorlevel 1 set "SB=npx.cmd"
)

if not defined SB goto :no_cli

echo.
if /i "%SB%"=="supabase" (
  echo Using: supabase
) else (
  echo Using: npx.cmd supabase  ^(Node.js^)
)
echo.

echo [0/3] Login + link project bryurwyeosbffvfpdbv ...
if /i "%SB%"=="supabase" (
  call supabase login
) else (
  call npx.cmd --yes supabase login
)
if errorlevel 1 goto :fail

if /i "%SB%"=="supabase" (
  call supabase link --project-ref bryurwyeosbffvfpdbv
) else (
  call npx.cmd --yes supabase link --project-ref bryurwyeosbffvfpdbv
)
if errorlevel 1 goto :fail

echo.
echo [1/3] Deploying extract-best-times ...
if /i "%SB%"=="supabase" (
  call supabase functions deploy extract-best-times
) else (
  call npx.cmd --yes supabase functions deploy extract-best-times
)
if errorlevel 1 goto :fail

echo.
echo [2/3] Deploying analyze-swim-video (best-times fallback) ...
if /i "%SB%"=="supabase" (
  call supabase functions deploy analyze-swim-video
) else (
  call npx.cmd --yes supabase functions deploy analyze-swim-video
)
if errorlevel 1 goto :fail

echo.
echo [OK] Cloud photo reader deployed.
echo Hard-refresh SwimIQ, then Upload best times again.
echo.
echo Optional local backup: keep START-SWIMIQ-WITH-ELITE.bat open
echo (needs GEMINI_API_KEY in services\video_analysis\.env).
pause
exit /b 0

:no_cli
echo.
echo [ERROR] Node.js / npx not found on this PC.
echo.
echo Install Node.js LTS, then close this window and double-click this bat again:
echo   https://nodejs.org
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
