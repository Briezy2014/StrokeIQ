@echo off
setlocal EnableExtensions
title SwimIQ - Get Stripe billing files
cd /d "%~dp0"

echo.
echo ========================================
echo  Download Stripe billing turn-on files
echo ========================================
echo.
echo Folder: %CD%
echo.

if not exist ".git" (
  echo [FAIL] Open Desktop\StrokeIQ and run this file there.
  pause
  exit /b 1
)

echo Updating Stripe files from GitHub...
git fetch origin
if errorlevel 1 (
  echo [FAIL] Could not reach GitHub. Check Wi-Fi.
  pause
  exit /b 1
)

git checkout origin/cursor/best-times-extract-reliable-b7ef -- ^
  "STRIPE-BILLING-STEPS.txt" ^
  "TURN-ON-STRIPE-BILLING.bat" ^
  "GET-STRIPE-BILLING.bat" ^
  "swimiq/DEPLOY-STRIPE-NOW.cmd" ^
  "swimiq/DEPLOY-STRIPE-CHECKOUT.bat"
if errorlevel 1 (
  echo [FAIL] Could not download Stripe files.
  pause
  exit /b 1
)

echo.
echo [OK] Stripe billing files are ready.
echo.
echo NEXT: open STRIPE-BILLING-STEPS.txt and do Step 2.
echo.
if exist "%CD%\STRIPE-BILLING-STEPS.txt" start "" notepad "%CD%\STRIPE-BILLING-STEPS.txt"
pause
exit /b 0
