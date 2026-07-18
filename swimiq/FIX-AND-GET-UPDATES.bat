@echo off
title SwimIQ - FIX AND GET UPDATES
cd /d "%~dp0"

echo.
echo ========================================
echo  SwimIQ - FIX BLOCKED PULL AND UPDATE
echo ========================================
echo.

for /f "delims=" %%i in ('git rev-parse --show-toplevel 2^>nul') do set "GITROOT=%%i"
if not defined GITROOT (
  echo [ERROR] Git not found. Open the swimiq folder that has your project.
  pause
  exit /b 1
)

cd /d "%GITROOT%"
echo Git root: %GITROOT%
echo.

echo Step 1: Saving your local edits (stash) so pull can run...
git stash push -u -m "kara-auto-stash-before-updates"
if errorlevel 1 (
  echo [WARN] Stash had a problem - trying to continue anyway...
)

echo.
echo Step 2: Fetch updates branch...
git fetch origin cursor/dashboard-rope-schedule-fix-17e8
if errorlevel 1 (
  echo [ERROR] git fetch failed.
  pause
  exit /b 1
)

echo.
echo Step 3: Switch to updates branch...
git checkout cursor/dashboard-rope-schedule-fix-17e8
if errorlevel 1 (
  echo [ERROR] checkout failed. Trying hard reset of blocker files...
  git checkout -- swimiq/android/gradle.properties swimiq/android/settings.gradle 2>nul
  git checkout -- android/gradle.properties android/settings.gradle 2>nul
  git checkout -- swimiq/lib/core/subscription/subscription_billing_policy.dart 2>nul
  git checkout -- lib/core/subscription/subscription_billing_policy.dart 2>nul
  git stash push -u -m "kara-retry-stash"
  git checkout cursor/dashboard-rope-schedule-fix-17e8
  if errorlevel 1 (
    echo [ERROR] Still blocked. Screenshot this window and send to support.
    pause
    exit /b 1
  )
)

echo.
echo Step 4: Pull latest...
git pull origin cursor/dashboard-rope-schedule-fix-17e8
if errorlevel 1 (
  echo [ERROR] git pull failed.
  pause
  exit /b 1
)

echo.
echo ========================================
echo  SUCCESS - UPDATES DOWNLOADED
echo ========================================
git log -1 --oneline
echo.
echo Look in your swimiq folder for:
echo   KARA-SEE-UPDATES-NOW.bat
echo.
echo Close ALL Chrome, then double-click KARA-SEE-UPDATES-NOW.bat
echo Dashboard should show blue strip: Updates build...
echo.
pause
