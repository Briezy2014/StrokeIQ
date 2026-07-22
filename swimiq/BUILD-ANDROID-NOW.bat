@echo off
title SwimIQ Build Android for Play Store
cd /d "%~dp0"
echo.
echo ========================================
echo  SwimIQ - Build app-release.aab
echo ========================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\build-android-release.ps1"
echo.
pause
