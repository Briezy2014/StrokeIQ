@echo off
title SwimIQ - GET ALL UPDATES
cd /d "%~dp0"

echo.
echo ========================================
echo  SwimIQ - GET ALL UPDATES
echo ========================================
echo.
echo This folder: %CD%
echo.

for /f "delims=" %%i in ('git rev-parse --show-toplevel 2^>nul') do set "GITROOT=%%i"
if not defined GITROOT (
  echo [ERROR] Git not found here.
  echo Open the folder that contains your SwimIQ project and .git
  echo Usually: S:\swimiq  OR the parent StrokeIQ folder
  pause
  exit /b 1
)

cd /d "%GITROOT%"
echo Git root: %GITROOT%
echo.
echo Pulling branch: cursor/dashboard-rope-schedule-fix-17e8
echo (All dashboard, passport, video, banner, and membership updates)
echo.

git fetch origin cursor/dashboard-rope-schedule-fix-17e8
if errorlevel 1 (
  echo [ERROR] git fetch failed. Check internet and GitHub login.
  pause
  exit /b 1
)

git checkout cursor/dashboard-rope-schedule-fix-17e8
if errorlevel 1 (
  echo [ERROR] git checkout failed.
  pause
  exit /b 1
)

git pull origin cursor/dashboard-rope-schedule-fix-17e8
if errorlevel 1 (
  echo [ERROR] git pull failed.
  echo Try: git stash push -u -m "kara-backup"
  echo Then run this file again.
  pause
  exit /b 1
)

echo.
echo ========================================
echo  UPDATES DOWNLOADED
echo ========================================
echo.
git log -1 --oneline
echo.
echo Files you should now see in swimiq folder:
echo   KARA-SEE-UPDATES-NOW.bat
echo   GET-UPDATES-NOW.bat
echo   LAUNCH-CHROME.bat
echo.
echo NEXT:
echo   1. Close ALL Chrome windows
echo   2. Double-click KARA-SEE-UPDATES-NOW.bat
echo      OR LAUNCH-CHROME.bat
echo   3. Dashboard must show blue strip:
echo      Updates build - dashboard, passport, video, banner
echo.
pause
