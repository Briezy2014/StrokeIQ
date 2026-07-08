@echo off
title SwimIQ Build Android APK
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0SWIMIQ-BUILD-ANDROID-NOW.ps1"
