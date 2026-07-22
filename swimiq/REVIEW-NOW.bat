@echo off
title SwimIQ Chrome Review
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\launch-chrome-review.ps1"
