@echo off
title SwimIQ Generate Android Keystore
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0GENERATE-ANDROID-KEYSTORE.ps1"
