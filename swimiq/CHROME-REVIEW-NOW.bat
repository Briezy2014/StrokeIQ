@echo off
title SwimIQ Chrome Review (no git pull)
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\launch-chrome-review.ps1"
