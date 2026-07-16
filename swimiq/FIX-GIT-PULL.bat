@echo off
title SwimIQ Fix Git Pull
cd /d "%~dp0"
set "BRANCH=cursor/dashboard-rope-schedule-fix-17e8"

echo.
echo ========================================
echo  SwimIQ - Fix Git Pull (merge errors)
echo ========================================
echo.
echo Use this when KARA-SEE-UPDATES-NOW says "local changes would be overwritten"
echo.

for /f "delims=" %%i in ('git rev-parse --show-toplevel 2^>nul') do set "GITROOT=%%i"
if not defined GITROOT (
  echo ERROR: Not a git folder. Open Desktop ^> StrokeIQ ^> swimiq
  pause
  exit /b 1
)

cd /d "%GITROOT%"
if exist "swimiq\KARA-SEE-UPDATES-NOW.bat" cd /d "%GITROOT%\swimiq"
echo Folder: %CD%
echo Branch: %BRANCH%
echo.

echo Step 1: Fetch latest from GitHub...
git fetch origin %BRANCH%
if errorlevel 1 (
  echo Fetch failed — check internet.
  pause
  exit /b 1
)

echo Step 2: Switch to updates branch...
git checkout %BRANCH%
if errorlevel 1 (
  echo Checkout failed.
  pause
  exit /b 1
)

echo Step 3: Clear files that block pull...
git checkout -- swimiq/scripts/diagnose-gemini.js 2>nul
git checkout -- scripts/diagnose-gemini.js 2>nul
git checkout -- swimiq/DIAGNOSE.bat 2>nul
git checkout -- DIAGNOSE.bat 2>nul
del /f /q swimiq\FIX-VIDEO-DATABASE.bat 2>nul
del /f /q FIX-VIDEO-DATABASE.bat 2>nul
del /f /q swimiq\KARA-FIX-VIDEO-DATABASE.bat 2>nul
del /f /q KARA-FIX-VIDEO-DATABASE.bat 2>nul
del /f /q swimiq\KARA-PASTE-THIS-IN-SUPABASE.txt 2>nul
del /f /q KARA-PASTE-THIS-IN-SUPABASE.txt 2>nul
del /f /q swimiq\supabase\fix_video_tables.sql 2>nul
del /f /q supabase\fix_video_tables.sql 2>nul
del /f /q swimiq\COPY-LOGO.bat 2>nul
del /f /q COPY-LOGO.bat 2>nul
del /f /q swimiq\DRAG-LOGO-HERE.bat 2>nul
del /f /q DRAG-LOGO-HERE.bat 2>nul

echo Step 4: Match GitHub exactly...
git reset --hard origin/%BRANCH%
if errorlevel 1 (
  echo.
  echo Still failed. Screenshot this window and send to support.
  pause
  exit /b 1
)

echo.
echo ========================================
echo  PULL DONE — you have the latest code
echo ========================================
echo.
git log -1 --oneline
echo.
echo Next:
echo   1. KARA-GEMINI-FIX-NOW.bat
echo   2. KARA-WHY-GEMINI-FAILS.bat — need version stream-v6
echo   3. KARA-CLICK-THIS.bat
echo.
pause
