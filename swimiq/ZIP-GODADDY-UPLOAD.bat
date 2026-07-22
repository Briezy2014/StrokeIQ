@echo off
title SwimIQ Zip for GoDaddy Upload
cd /d "%~dp0"
echo.
echo ========================================
echo  SwimIQ - ZIP for GoDaddy (one file)
echo ========================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\zip-web-godaddy.ps1"
echo.
pause
