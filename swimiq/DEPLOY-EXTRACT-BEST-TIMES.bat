@echo off
title SwimIQ - Deploy extract-best-times Edge Function
cd /d "%~dp0"
echo.
echo ========================================
echo  Deploy Best Times photo reader (cloud)
echo ========================================
echo.
echo This lets Upload best times work WITHOUT local Elite.
echo.
echo BEFORE running:
echo   1. Supabase - Edge Functions - Secrets must include GEMINI_API_KEY
echo   2. supabase login + link to project bryurwyeosbffvfpdbv
echo.
pause

supabase functions deploy extract-best-times
if errorlevel 1 goto :fail

echo.
echo [OK] extract-best-times deployed.
echo Retry Upload best times in SwimIQ (hard refresh first).
pause
exit /b 0

:fail
echo.
echo [ERROR] Deploy failed.
echo   supabase login
echo   supabase link --project-ref bryurwyeosbffvfpdbv
echo   supabase functions deploy extract-best-times
pause
exit /b 1
