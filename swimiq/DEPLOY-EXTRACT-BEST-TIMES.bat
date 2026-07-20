@echo off
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
echo   2. supabase login + link to project bryurwyeosbffvfpdbv
echo.
echo Deploys:
echo   - extract-best-times
echo   - analyze-swim-video  (adds photo extract fallback)
echo.
pause

echo.
echo [1/2] Deploying extract-best-times ...
supabase functions deploy extract-best-times
if errorlevel 1 goto :fail

echo.
echo [2/2] Deploying analyze-swim-video (best-times fallback) ...
supabase functions deploy analyze-swim-video
if errorlevel 1 goto :fail

echo.
echo [OK] Cloud photo reader deployed.
echo Hard-refresh SwimIQ, then Upload best times again.
echo.
echo Optional local backup: keep START-SWIMIQ-WITH-ELITE.bat open
echo (needs GEMINI_API_KEY in services\video_analysis\.env).
pause
exit /b 0

:fail
echo.
echo [ERROR] Deploy failed.
echo   supabase login
echo   supabase link --project-ref bryurwyeosbffvfpdbv
echo   supabase functions deploy extract-best-times
echo   supabase functions deploy analyze-swim-video
pause
exit /b 1
