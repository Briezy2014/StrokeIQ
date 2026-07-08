@echo off
title SwimIQ Diagnose
cd /d "%~dp0"
echo.
echo === SwimIQ Diagnose ===
echo Folder: %CD%
echo.

if exist "%~dp0launch-chrome.ps1" (echo [OK] launch-chrome.ps1) else (echo [MISSING] launch-chrome.ps1)
if exist "%~dp0fix-kara-paths.ps1" (echo [OK] fix-kara-paths.ps1) else (echo [MISSING] fix-kara-paths.ps1)
if exist "%~dp0.env" (echo [OK] .env) else (echo [MISSING] .env - create from .env.example)
if exist "S:\swimiq" (echo [OK] S:\swimiq) else (echo [WARN] S:\swimiq - run FIX-KARA-PATHS.bat)
if exist "F:\bin\flutter.bat" (echo [OK] F:\bin\flutter) else (echo [WARN] F:\bin - run FIX-KARA-PATHS.bat)

echo.
pause
