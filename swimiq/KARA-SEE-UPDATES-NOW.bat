@echo off
title SwimIQ - SEE UPDATES NOW
cd /d "%~dp0"
echo.
echo ========================================
echo  SwimIQ - PULL ALL UPDATES AND RUN
echo ========================================
echo.
echo Branch: cursor/dashboard-rope-schedule-fix-17e8
echo (NOT main — all your updates are on this branch)
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
  pause
  exit /b 1
)

echo.
echo [OK] You are on the updates branch.
git log -1 --oneline
echo.
echo Close ALL Chrome windows, then wait for Flutter to start...
echo Dashboard should show: "Updates build — dashboard, passport, video, banner"
echo.

if exist "%~dp0scripts\launch-chrome-kara.ps1" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\launch-chrome-kara.ps1"
) else if exist "%~dp0SWIMIQ-CHROME-NOW.ps1" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0SWIMIQ-CHROME-NOW.ps1"
) else (
  echo Run: flutter clean ^&^& flutter pub get ^&^& flutter run -d chrome --dart-define-from-file=.env
)

pause
