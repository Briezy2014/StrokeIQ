@echo off
setlocal EnableExtensions
title SwimIQ - Turn on Stripe billing
cd /d "%~dp0"

echo.
echo ========================================
echo  SwimIQ - Turn on Stripe billing
echo ========================================
echo.
echo This only turns on website plan checkout.
echo It is NOT about best times photos.
echo.

if not exist "%~dp0swimiq\DEPLOY-STRIPE-NOW.cmd" (
  echo [ERROR] Missing swimiq\DEPLOY-STRIPE-NOW.cmd
  echo.
  echo First double-click GET-STRIPE-BILLING.bat in this same folder.
  echo Then run TURN-ON-STRIPE-BILLING.bat again.
  echo.
  pause
  exit /b 1
)

call "%~dp0swimiq\DEPLOY-STRIPE-NOW.cmd"
exit /b %ERRORLEVEL%
