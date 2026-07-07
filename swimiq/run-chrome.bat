@echo off
REM SwimIQ — launch Flutter web in Chrome (handles Kara Williams / path spaces)
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File "%~dp0run-chrome.ps1"
if errorlevel 1 pause
