@echo off
title SwimIQ Fix Paths
cd /d "%~dp0"
echo.
echo  SwimIQ - Fix Kara Paths (run once)
echo  Folder: %CD%
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0fix-kara-paths.ps1"
exit /b %ERRORLEVEL%
