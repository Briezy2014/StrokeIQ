@echo off
title SwimIQ Fix Git Pull
cd /d "%~dp0"

echo.
echo ========================================
echo  SwimIQ - Fix Git Pull (merge errors)
echo ========================================
echo.

for /f "delims=" %%i in ('git rev-parse --show-toplevel 2^>nul') do set "GITROOT=%%i"
if not defined GITROOT (
  echo ERROR: Not a git folder. Open the folder that has .git
  pause
  exit /b 1
)

cd /d "%GITROOT%"
echo Git folder: %GITROOT%
echo.

echo Step 1: Drop local edits to DIAGNOSE.bat (use GitHub version)...
git checkout -- swimiq/DIAGNOSE.bat 2>nul
git checkout -- DIAGNOSE.bat 2>nul

echo Step 2: Remove duplicate logo bats so pull can replace them...
del /f /q swimiq\COPY-LOGO.bat 2>nul
del /f /q swimiq\DRAG-LOGO-HERE.bat 2>nul
del /f /q COPY-LOGO.bat 2>nul
del /f /q DRAG-LOGO-HERE.bat 2>nul

echo Step 3: Pull latest code...
git fetch origin cursor/windows-chrome-spaces-fix-17e8
git pull origin cursor/windows-chrome-spaces-fix-17e8
if errorlevel 1 (
  echo.
  echo Pull still failed. Try in PowerShell:
  echo   git stash push -u -m "kara-backup"
  echo   git pull origin cursor/windows-chrome-spaces-fix-17e8
  echo.
  pause
  exit /b 1
)

echo.
echo ========================================
echo  PULL DONE
echo ========================================
echo.
echo Next:
echo   1. Drag NEW logo onto SYNC-LOGO-NOW.bat
echo   2. Double-click LAUNCH-CHROME.bat
echo.
pause
