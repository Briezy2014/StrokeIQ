@echo off
setlocal EnableExtensions
title SwimIQ - Deploy Stripe billing
cd /d "%~dp0"

set "PROJECT_REF=bryurwyeosbffvfpdbv"

echo.
echo ========================================
echo  Stripe billing deploy (SwimIQ)
echo ========================================
echo.
echo This turns on Plans and billing checkout.
echo Project: %PROJECT_REF%
echo.
echo You already need in Supabase secrets:
echo   STRIPE_SECRET_KEY
echo   STRIPE_PRICE_BASIC_MONTHLY ... ELITE_ANNUAL (6 prices)
echo.
pause

set "NPX="
if exist "%ProgramFiles%\nodejs\npx.cmd" set "NPX=%ProgramFiles%\nodejs\npx.cmd"
if not defined NPX if exist "%ProgramFiles(x86)%\nodejs\npx.cmd" set "NPX=%ProgramFiles(x86)%\nodejs\npx.cmd"
if not defined NPX (
  where npx.cmd >nul 2>nul
  if not errorlevel 1 for /f "delims=" %%I in ('where npx.cmd') do (
    set "NPX=%%I"
    goto :have_npx
  )
)
:have_npx
if not defined NPX (
  echo [ERROR] Install Node.js LTS from https://nodejs.org then run this again.
  pause
  exit /b 1
)

echo Using: "%NPX%"
echo.

echo [1/3] Login (skip if already logged in) ...
call "%NPX%" --yes supabase login
if errorlevel 1 goto :fail

echo [2/3] Deploy create-stripe-checkout ...
call "%NPX%" --yes supabase functions deploy create-stripe-checkout --project-ref %PROJECT_REF% --use-api
if errorlevel 1 goto :fail

echo [3/3] Deploy stripe-webhook ...
call "%NPX%" --yes supabase functions deploy stripe-webhook --project-ref %PROJECT_REF% --use-api
if errorlevel 1 goto :fail

echo.
echo [OK] Stripe functions deployed.
echo.
echo NEXT - in Stripe website:
echo   Developers - Webhooks - Add endpoint
echo   URL:
echo   https://%PROJECT_REF%.supabase.co/functions/v1/stripe-webhook
echo.
echo Then paste Signing secret (whsec_...) as STRIPE_WEBHOOK_SECRET
echo in Supabase Edge Function secrets.
echo.
pause
exit /b 0

:fail
echo.
echo [ERROR] Stopped. Tell the agent which step number failed.
pause
exit /b 1
