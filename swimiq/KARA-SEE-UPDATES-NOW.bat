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

call :EnsureVideoDbFixFiles

echo.
echo [OK] You are on the updates branch.
git log -1 --oneline
echo.
if exist "FIX-VIDEO-DATABASE.bat" (
  echo [OK] FIX-VIDEO-DATABASE.bat is here.
  echo Video Delete or Analyze broken? Run FIX-VIDEO-DATABASE.bat once on Supabase website.
) else (
  echo [WARN] FIX-VIDEO-DATABASE.bat still missing - run RESTORE-SCRIPTS.bat
)
echo Then run KARA-GEMINI-FIX-NOW.bat
echo.
if not exist "assets\branding\icon.png" (
  echo [WARN] assets\branding\icon.png is missing.
  echo        Drag your brand icon onto COPY-LOGO.bat before testing login.
  echo.
)
echo Close ALL Chrome windows, then wait for Flutter to start...
echo Dashboard banner should show full SWIMIQ lockup + tagline.
echo Rope climb badge should show a drawn swimmer (not the app icon).
echo.

if exist "%~dp0scripts\launch-chrome-kara.ps1" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\launch-chrome-kara.ps1"
) else if exist "%~dp0SWIMIQ-CHROME-NOW.ps1" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0SWIMIQ-CHROME-NOW.ps1"
) else (
  echo Run: flutter clean ^&^& flutter pub get ^&^& flutter run -d chrome --dart-define-from-file=.env
)

pause
exit /b 0

:EnsureVideoDbFixFiles
if exist "%~dp0scripts\ensure-video-db-fix.cmd" (
  call "%~dp0scripts\ensure-video-db-fix.cmd"
  exit /b 0
)
if exist "%~dp0scripts\ensure-video-db-fix.ps1" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\ensure-video-db-fix.ps1" -SwimIqRoot "%~dp0"
)
exit /b 0
