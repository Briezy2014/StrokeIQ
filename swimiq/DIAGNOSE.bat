@echo off
title SwimIQ Diagnose
cd /d "%~dp0"
echo.
echo === SwimIQ Diagnose ===
echo Folder: %CD%
echo.
echo --- scripts folder ---
if exist "%~dp0scripts\launch-chrome-tonight.ps1" (echo [OK] scripts\launch-chrome-tonight.ps1) else (echo [MISSING] scripts\launch-chrome-tonight.ps1)
if exist "%~dp0scripts\kara-fix-windows-once.ps1" (echo [OK] scripts\kara-fix-windows-once.ps1) else (echo [MISSING] scripts\kara-fix-windows-once.ps1)
if exist "%~dp0scripts\build-web-godaddy.ps1" (echo [OK] scripts\build-web-godaddy.ps1) else (echo [MISSING] scripts\build-web-godaddy.ps1)
if exist "%~dp0scripts\set-supabase-stripe-secrets.ps1" (echo [OK] scripts\set-supabase-stripe-secrets.ps1) else (echo [MISSING] scripts\set-supabase-stripe-secrets.ps1)
if exist "%~dp0scripts\setup-short-path.bat" (echo [OK] scripts\setup-short-path.bat) else (echo [MISSING] scripts\setup-short-path.bat)
echo.
echo --- config ---
if exist "%~dp0.env" (echo [OK] .env) else (echo [MISSING] .env)
if exist "S:\swimiq" (echo [OK] S:\swimiq mapped) else (echo [WARN] run FIX-KARA-PATHS.bat)
if exist "F:\bin\flutter.bat" (echo [OK] F:\bin flutter) else (echo [WARN] run FIX-KARA-PATHS.bat)
echo.
pause
