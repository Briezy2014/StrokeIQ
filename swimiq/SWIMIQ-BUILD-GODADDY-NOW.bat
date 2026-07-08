@echo off
title SwimIQ Build GoDaddy
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0SWIMIQ-BUILD-GODADDY-NOW.ps1"
