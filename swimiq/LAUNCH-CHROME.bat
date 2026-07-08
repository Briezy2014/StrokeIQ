@echo off
title SwimIQ Launch Chrome
cd /d "%~dp0"
echo.
echo  SwimIQ - Launch Chrome
echo  Folder: %CD%
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0launch-chrome.ps1"
exit /b %ERRORLEVEL%
