@echo off
title SwimIQ Chrome Fix
cd /d "%~dp0"
echo.
echo ========================================
echo  SwimIQ Chrome Fix
echo ========================================
echo.
if not exist ".env" (
  echo ERROR: Missing .env in this folder.
  echo Copy .env.example to .env and add Supabase keys.
  pause
  exit /b 1
)
echo Step 1: Stop any old Chrome debug session first (press q in old terminal).
echo Step 2: Clean + rebuild web assets...
call flutter clean
call flutter pub get
if errorlevel 1 pause & exit /b 1
echo.
echo Step 3: Launch Chrome WITH Supabase keys from .env...
echo Wait 2-3 minutes...
call flutter run -d chrome --dart-define-from-file=.env
pause
