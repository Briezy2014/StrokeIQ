@echo off
title SwimIQ Build Google Play AAB
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0SWIMIQ-BUILD-AAB-NOW.ps1"
