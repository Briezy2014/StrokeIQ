@echo off
setlocal EnableExtensions
title SwimIQ - Deploy Stripe Checkout to Supabase
cd /d "%~dp0"

echo.
echo ========================================
echo  Deploy Stripe billing Edge Functions
echo ========================================
echo.
echo Project: bryurwyeosbffvfpdbv
echo.
echo BEFORE running this:
echo   1. Stripe Dashboard - create 6 test prices (see docs\STRIPE_SETUP.md)
echo   2. Supabase Dashboard - Edge Functions - Secrets:
echo        STRIPE_SECRET_KEY, STRIPE_PRICE_* (6), STRIPE_WEBHOOK_SECRET
echo.
pause

call :find_supabase
if errorlevel 1 goto :no_cli

echo.
echo Using: %SB_CMD%
echo.

echo [0/3] Login + link project ...
call %SB_CMD% login
if errorlevel 1 goto :fail
call %SB_CMD% link --project-ref bryurwyeosbffvfpdbv
if errorlevel 1 goto :fail

echo.
echo [1/3] Deploying create-stripe-checkout ...
call %SB_CMD% functions deploy create-stripe-checkout
if errorlevel 1 goto :fail

echo.
echo [2/3] Deploying stripe-webhook ...
call %SB_CMD% functions deploy stripe-webhook
if errorlevel 1 goto :fail

echo.
echo [OK] Functions deployed. Add Stripe webhook endpoint:
echo   https://bryurwyeosbffvfpdbv.supabase.co/functions/v1/stripe-webhook
echo.
echo Then paste the Signing secret (whsec_...) as STRIPE_WEBHOOK_SECRET
echo in Supabase Edge Function secrets.
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
echo   3. Double-click DEPLOY-STRIPE-CHECKOUT.bat again
echo.
echo Or in a NEW Command Prompt:
echo   npm install -g supabase
echo   then run this bat again.
echo.
pause
exit /b 1

:fail
echo.
echo [ERROR] Deploy failed. Check login/link and secrets, then retry.
pause
exit /b 1
