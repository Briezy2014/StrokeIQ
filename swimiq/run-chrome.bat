@echo off
REM SwimIQ — launch Flutter web in Chrome (bypasses PowerShell script policy)
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run-chrome.ps1"
if errorlevel 1 pause
