@echo off
title SwimIQ - Deploy Stripe Checkout to Supabase
cd /d "%~dp0"
echo.
echo ========================================
echo  Deploy Stripe billing Edge Functions
echo ========================================
echo.
echo Project: bryurwyeosbffvfpdbv (check supabase link)
echo.
echo BEFORE running this:
echo   1. Stripe Dashboard - create 6 test prices (see docs/STRIPE_SETUP.md)
echo   2. Supabase Dashboard - Edge Functions - Secrets:
echo        STRIPE_SECRET_KEY, STRIPE_PRICE_* (6), STRIPE_WEBHOOK_SECRET
echo   3. supabase link --project-ref YOUR_REF
echo.
pause

supabase functions deploy create-stripe-checkout
if errorlevel 1 goto :fail

supabase functions deploy stripe-webhook
if errorlevel 1 goto :fail

echo.
echo [OK] Functions deployed. Add Stripe webhook endpoint:
echo   https://YOUR_PROJECT.supabase.co/functions/v1/stripe-webhook
echo.
echo Test checkout from swimiqapp.com or localhost after Kara update.
pause
exit /b 0

:fail
echo.
echo [ERROR] Deploy failed. Install Supabase CLI and run: supabase login
pause
exit /b 1
