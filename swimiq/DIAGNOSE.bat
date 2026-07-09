@echo off
title SwimIQ Diagnose
cd /d "%~dp0"
call "%~dp0scripts\ensure-logo-bats.cmd" 2>nul
echo.
echo === SwimIQ Diagnose ===
echo Folder: %CD%
echo.
echo --- START HERE (double-click this) ---
if exist "%~dp0START-HERE.bat" (echo [OK] START-HERE.bat) else (echo [MISSING] START-HERE.bat)
echo.
echo --- logo (drag 512x512 PNG onto this) ---
if exist "%~dp0DRAG-LOGO-HERE.bat" (echo [OK] DRAG-LOGO-HERE.bat) else (echo [MISSING] DRAG-LOGO-HERE.bat)
if exist "%~dp0COPY-LOGO.bat" (echo [OK] COPY-LOGO.bat) else (echo [MISSING] COPY-LOGO.bat)
if exist "%~dp0assets\branding\icon.png" (echo [OK] assets\branding\icon.png) else (echo [MISSING] assets\branding\icon.png)
if exist "%~dp0assets\branding\banner.png" (echo [OK] assets\branding\banner.png) else (echo [OPTIONAL] assets\branding\banner.png)
if exist "%~dp0assets\branding\mark.png" (echo [OK] assets\branding\mark.png) else (echo [OPTIONAL] assets\branding\mark.png)
echo.
echo --- one-click launchers (USE THESE) ---
if exist "%~dp0SWIMIQ-CHROME-NOW.bat" (echo [OK] SWIMIQ-CHROME-NOW.bat) else (echo [MISSING] SWIMIQ-CHROME-NOW.bat)
if exist "%~dp0SWIMIQ-CHROME-NOW.ps1" (echo [OK] SWIMIQ-CHROME-NOW.ps1) else (echo [MISSING] SWIMIQ-CHROME-NOW.ps1)
if exist "%~dp0SWIMIQ-BUILD-GODADDY-NOW.bat" (echo [OK] SWIMIQ-BUILD-GODADDY-NOW.bat) else (echo [MISSING] SWIMIQ-BUILD-GODADDY-NOW.bat)
if exist "%~dp0SWIMIQ-BUILD-GODADDY-NOW.ps1" (echo [OK] SWIMIQ-BUILD-GODADDY-NOW.ps1) else (echo [MISSING] SWIMIQ-BUILD-GODADDY-NOW.ps1)
echo.
echo --- scripts folder ---
if exist "%~dp0scripts\launch-chrome-tonight.ps1" (echo [OK] scripts\launch-chrome-tonight.ps1) else (echo [MISSING] scripts\launch-chrome-tonight.ps1)
if exist "%~dp0scripts\kara-fix-windows-once.ps1" (echo [OK] scripts\kara-fix-windows-once.ps1) else (echo [MISSING] scripts\kara-fix-windows-once.ps1)
if exist "%~dp0scripts\ensure-logo-bats.cmd" (echo [OK] scripts\ensure-logo-bats.cmd) else (echo [MISSING] scripts\ensure-logo-bats.cmd)
if exist "%~dp0scripts\build-web-godaddy.ps1" (echo [OK] scripts\build-web-godaddy.ps1) else (echo [MISSING] scripts\build-web-godaddy.ps1)
if exist "%~dp0scripts\set-supabase-stripe-secrets.ps1" (echo [OK] scripts\set-supabase-stripe-secrets.ps1) else (echo [MISSING] scripts\set-supabase-stripe-secrets.ps1)
if exist "%~dp0scripts\setup-short-path.bat" (echo [OK] scripts\setup-short-path.bat) else (echo [MISSING] scripts\setup-short-path.bat)
if exist "%~dp0TEST-OWNER-LOGIN.bat" (echo [OK] TEST-OWNER-LOGIN.bat) else (echo [MISSING] TEST-OWNER-LOGIN.bat)
echo.
echo --- config ---
if exist "%~dp0.env" (echo [OK] .env) else (echo [MISSING] .env)
if exist "S:\swimiq" (echo [OK] S:\swimiq mapped) else (echo [WARN] run FIX-KARA-PATHS.bat)
if exist "F:\bin\flutter.bat" (echo [OK] F:\bin flutter) else (echo [WARN] run FIX-KARA-PATHS.bat)
echo.
pause
