@echo off
setlocal EnableExtensions
title SwimIQ - Deploy Stripe billing
cd /d "%~dp0"

echo.
echo ========================================
echo  Stripe billing deploy (SwimIQ)
echo ========================================
echo.
echo This turns on Plans and billing checkout.
echo Project: bryurwyeosbffvfpdbv
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
  if not errorlevel 1 for /f "delims=" %%I in ('where npx.cmd') do set "NPX=%%I" & goto :have_npx
)
:have_npx
if not defined NPX (
  echo [ERROR] Install Node.js LTS from https://nodejs.org then run this again.
  pause
  exit /b 1
)

echo Using: "%NPX%"
echo.

echo [1/4] Login (browser may open) ...
call "%NPX%" --yes supabase login
if errorlevel 1 goto :fail

echo [2/4] Link project ...
call "%NPX%" --yes supabase link --project-ref bryurwyeosbffvfpdbv
if errorlevel 1 goto :fail

echo [3/4] Deploy create-stripe-checkout ...
call "%NPX%" --yes supabase functions deploy create-stripe-checkout
if errorlevel 1 goto :fail

echo [4/4] Deploy stripe-webhook ...
call "%NPX%" --yes supabase functions deploy stripe-webhook
if errorlevel 1 goto :fail

echo.
echo [OK] Stripe functions deployed.
echo.
echo NEXT - in Stripe website:
echo   Developers - Webhooks - Add endpoint
echo   URL:
echo   https://bryurwyeosbffvfpdbv.supabase.co/functions/v1/stripe-webhook
echo.
echo Then copy Signing secret into Supabase secret STRIPE_WEBHOOK_SECRET
echo.
pause
exit /b 0

:fail
echo.
echo [ERROR] Stopped. Tell the agent which step number failed.
pause
exit /b 1
