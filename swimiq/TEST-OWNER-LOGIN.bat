@echo off
title SwimIQ Test Owner Login
cd /d "%~dp0"
echo.
echo Tests owner@swimiqapp.com against YOUR Supabase project in .env
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\test-supabase-login.ps1"
echo.
pause
