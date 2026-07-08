@echo off
title SwimIQ Chrome NOW
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0SWIMIQ-CHROME-NOW.ps1"
pause
