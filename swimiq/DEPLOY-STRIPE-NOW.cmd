@echo off
setlocal EnableExtensions
title SwimIQ - Deploy Stripe billing
cd /d "%~dp0"

echo.
echo ========================================
echo  Stripe billing deploy (SwimIQ)
echo ========================================
echo.
echo Project: bryurwyeosbffvfpdbv
echo.
echo You already need in Supabase secrets:
echo   STRIPE_SECRET_KEY
echo   STRIPE_PRICE_* (6 prices)
echo.
pause

where node >nul 2>nul
if errorlevel 1 (
  if exist "%ProgramFiles%\nodejs\node.exe" goto :have_node_path
  echo [ERROR] Node.js not found. Install LTS from https://nodejs.org
  pause
  exit /b 1
)
goto :run

:have_node_path
set "PATH=%ProgramFiles%\nodejs;%PATH%"

:run
echo Running Node deploy helper...
echo.
node "%~dp0scripts\deploy-stripe-functions.mjs"
set "ERR=%ERRORLEVEL%"
if not "%ERR%"=="0" (
  echo.
  echo [ERROR] Stopped. Tell the agent which step number failed.
  pause
  exit /b %ERR%
)
echo.
pause
exit /b 0
