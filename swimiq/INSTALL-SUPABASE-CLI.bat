@echo off
title SwimIQ - Install Supabase CLI (one time)
cd /d "%~dp0"
echo.
echo ========================================
echo  Install Supabase CLI for Windows
echo ========================================
echo.
echo You need this ONCE to deploy Gemini video analysis.
echo.
pause

where node >nul 2>&1
if errorlevel 1 (
  echo.
  echo Node.js was not found. Flutter/Chrome builds often include it.
  echo.
  echo OPTION A - Install Node.js 20+ from https://nodejs.org
  echo   Then double-click this file again.
  echo.
  echo OPTION B - Use Scoop instead (PowerShell as Administrator):
  echo   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
  echo   iwr -useb get.scoop.sh ^| iex
  echo   scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
  echo   scoop install supabase
  echo.
  pause
  exit /b 1
)

echo.
echo Installing Supabase CLI locally in this folder (safe, no global npm)...
call npm install supabase --save-dev
if errorlevel 1 (
  echo.
  echo [ERROR] npm install failed. Try updating Node.js to version 20 or newer.
  pause
  exit /b 1
)

echo.
echo Verifying...
call npx supabase --version
if errorlevel 1 (
  echo.
  echo [ERROR] Supabase CLI still not working. See docs/GEMINI_SETUP.md
  pause
  exit /b 1
)

echo.
echo ========================================
echo  SUCCESS - Supabase CLI is ready
echo ========================================
echo.
echo Next steps:
echo   1. Double-click DEPLOY-GEMINI-VIDEO.bat
echo   2. When asked, run: supabase login (browser opens)
echo   3. Re-run Analyze on a video in SwimIQ
echo.
pause
exit /b 0
