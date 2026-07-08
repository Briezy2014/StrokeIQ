@echo off
title SwimIQ Create Keystore
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\create-android-keystore.ps1"
pause
