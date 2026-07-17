@echo off
title SwimIQ - Download latest fixed files
cd /d "%~dp0"

echo.
echo ============================================
echo   Download latest SwimIQ fixed files
echo   Folder: %CD%
echo ============================================
echo.
echo This updates YOUR Desktop\StrokeIQ folder from GitHub
echo so START-ELITE-ANALYSIS-SERVER.bat appears.
echo.

if not exist ".git" (
  echo [FAIL] This is not the StrokeIQ git folder.
  echo Open Desktop\StrokeIQ and run this file there.
  pause
  exit /b 1
)

git fetch origin
if errorlevel 1 (
  echo [FAIL] git fetch failed. Check internet.
  pause
  exit /b 1
)

git merge --abort >nul 2>&1
git checkout -f cursor/elite-video-on-dashboard-b7ef
git reset --hard origin/cursor/elite-video-on-dashboard-b7ef
if errorlevel 1 (
  echo [FAIL] Could not update files.
  pause
  exit /b 1
)

echo.
echo Checking for Elite server starter...
if exist "START-ELITE-ANALYSIS-SERVER.bat" (
  echo [OK] Found: START-ELITE-ANALYSIS-SERVER.bat
) else (
  echo [BAD] Still missing START-ELITE-ANALYSIS-SERVER.bat
)
if exist "swimiq\START-ELITE-ANALYSIS-SERVER.bat" (
  echo [OK] Found: swimiq\START-ELITE-ANALYSIS-SERVER.bat
) else (
  echo [BAD] Still missing swimiq\START-ELITE-ANALYSIS-SERVER.bat
)
if exist "swimiq\LAUNCH-CHROME.bat" (
  echo [OK] Found: swimiq\LAUNCH-CHROME.bat
) else (
  echo [BAD] Missing swimiq\LAUNCH-CHROME.bat
)

echo.
echo ============================================
echo NEXT — two double-clicks:
echo   1. START-ELITE-ANALYSIS-SERVER.bat  ^(leave open^)
echo   2. swimiq\LAUNCH-CHROME.bat
echo ============================================
echo.
pause
