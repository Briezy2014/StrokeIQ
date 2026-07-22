@echo off
title Free SwimIQ Chrome port
cd /d "%~dp0"
echo Clearing old Flutter / Chrome localhost ports...
powershell -NoProfile -ExecutionPolicy Bypass -File "%CD%\swimiq\scripts\kill-flutter-web-port.ps1"
echo.
echo Done. Now double-click OPEN-WORKING-APP-NOW.bat
pause
exit /b 0
