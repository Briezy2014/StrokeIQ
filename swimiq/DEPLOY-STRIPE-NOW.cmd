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
echo When asked, paste a Supabase access token.
echo Browser will open the token page for you.
echo.
pause

where node >nul 2>nul
if errorlevel 1 (
  if exist "%ProgramFiles%\nodejs\node.exe" set "PATH=%ProgramFiles%\nodejs;%PATH%"
)
where node >nul 2>nul
if errorlevel 1 (
  echo [ERROR] Install Node.js LTS from https://nodejs.org
  pause
  exit /b 1
)

echo.
node "%~dp0scripts\deploy-stripe-functions.mjs"
set "ERR=%ERRORLEVEL%"
if not "%ERR%"=="0" (
  echo.
  echo [ERROR] Stopped. Send a photo of this window.
  pause
  exit /b %ERR%
)
echo.
pause
exit /b 0
