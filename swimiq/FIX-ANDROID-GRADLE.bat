@echo off
title SwimIQ Fix Gradle
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\fix-android-gradle.ps1"
pause
