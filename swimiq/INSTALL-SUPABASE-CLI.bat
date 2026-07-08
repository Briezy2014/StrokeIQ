@echo off
title SwimIQ - Install Supabase CLI
cd /d "%~dp0"
echo.
echo ========================================
echo  SwimIQ - Install Supabase CLI
echo ========================================
echo.
echo NOTE: You do NOT need this to run SwimIQ in Chrome.
echo       Use KARA-CLICK-THIS.bat for the app.
echo.
echo This is only for deploying AI video / Stripe backend.
echo.

where node >nul 2>&1
if %ERRORLEVEL% EQU 0 (
  echo Found Node.js - installing Supabase CLI in this project...
  echo.
  call npm install supabase --save-dev
  if errorlevel 1 goto failed
  echo.
  echo [OK] Installed. Use:
  echo   npx supabase login
  echo   npx supabase link --project-ref YOUR_PROJECT_REF
  echo.
  echo See docs\SUPABASE_CLI_WINDOWS.md
  goto done
)

echo Node.js not found.
echo.
echo Option A - Install Node.js from https://nodejs.org then run this bat again.
echo Option B - Install via Scoop - see docs\SUPABASE_CLI_WINDOWS.md
echo.
goto done

:failed
echo.
echo [ERROR] npm install failed.
echo See docs\SUPABASE_CLI_WINDOWS.md

:done
echo.
pause
