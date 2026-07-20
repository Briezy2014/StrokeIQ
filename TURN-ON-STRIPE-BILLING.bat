@echo off
setlocal EnableExtensions
title SwimIQ - Turn on Stripe billing
cd /d "%~dp0"

echo.
echo ========================================
echo  SwimIQ - Turn on Stripe billing
echo ========================================
echo.
echo Local SwimIQ in the browser is fine to leave open.
echo This black window turns on Stripe checkout in the cloud.
echo.

if not exist "%~dp0swimiq\scripts\deploy-stripe-functions.mjs" (
  echo [ERROR] Missing deploy helper.
  echo Double-click GET-LATEST-FIXED-APP.bat first, then try again.
  pause
  exit /b 1
)

call "%~dp0swimiq\DEPLOY-STRIPE-NOW.cmd"
exit /b %ERRORLEVEL%
