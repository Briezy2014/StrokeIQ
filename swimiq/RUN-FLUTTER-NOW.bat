@echo off
title SwimIQ - Run Flutter (Elite already up)
cd /d "%~dp0"
echo.
echo Elite window must STAY OPEN.
echo No new API key needed.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0RUN-FLUTTER-NOW.ps1"
echo.
pause
