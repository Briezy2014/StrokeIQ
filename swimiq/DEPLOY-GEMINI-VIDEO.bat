@echo off
title SwimIQ - Deploy Gemini Video Analysis (100 MB)
cd /d "%~dp0"
setlocal EnableExtensions

echo.
echo ========================================
echo  Deploy analyze-swim-video to Supabase
echo ========================================
echo.
echo This updates the SERVER so Analyze can
echo handle phone clips up to about 100 MB.
echo.
echo BEFORE YOU CONTINUE:
echo   1. Internet works
echo   2. You can log into the Supabase account
echo      that owns SwimIQ
echo   3. Supabase Secrets has GEMINI_API_KEY
echo.
echo Project: bryurwyeosbffvfpdpbv
echo.
pause

set "SUPABASE_CMD=npx --yes supabase"

where node >nul 2>&1
if errorlevel 1 (
  echo.
  echo [FAIL] Node.js is not installed.
  echo Install LTS from https://nodejs.org then run this again.
  start "" "https://nodejs.org"
  pause
  exit /b 1
)

echo.
echo [1/3] Supabase login (browser may open)...
%SUPABASE_CMD% login
if errorlevel 1 (
  echo [FAIL] Login failed.
  pause
  exit /b 1
)

echo.
echo [2/3] Link project...
%SUPABASE_CMD% link --project-ref bryurwyeosbffvfpdpbv
if errorlevel 1 (
  echo [FAIL] Link failed. Use the Supabase account that owns this project.
  pause
  exit /b 1
)

echo.
echo [3/3] Deploy analyze-swim-video...
%SUPABASE_CMD% functions deploy analyze-swim-video
if errorlevel 1 (
  echo [FAIL] Deploy failed.
  echo Confirm GEMINI_API_KEY exists under Supabase - Edge Functions - Secrets.
  pause
  exit /b 1
)

echo.
echo ========================================
echo  SERVER UPDATE SUCCESS
echo ========================================
echo.
echo NEXT:
echo   1. Rebuild website: PowerShell in S:\swimiq
echo      powershell -ExecutionPolicy Bypass -File .\scripts\build-web-godaddy.ps1
echo   2. Upload ALL of build\web to GoDaddy public_html
echo   3. Test Analyze on a short clip first
echo.
pause
exit /b 0
