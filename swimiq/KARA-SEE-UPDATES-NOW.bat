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

echo.
echo Syncing to latest GitHub (fixes "local changes would be overwritten")...
call :ClearPullBlockers
git reset --hard origin/cursor/dashboard-rope-schedule-fix-17e8
if errorlevel 1 (
  echo [ERROR] Could not sync to GitHub. Try FIX-GIT-PULL.bat
  pause
  exit /b 1
)

call :EnsureVideoDbFixFiles

echo.
echo [OK] You are on the updates branch — latest code from GitHub.
git log -1 --oneline
echo.
if exist "FIX-VIDEO-DATABASE.bat" (
  echo [OK] FIX-VIDEO-DATABASE.bat is here.
  echo Video Delete or Analyze broken? Run FIX-VIDEO-DATABASE.bat once on Supabase website.
) else (
  echo [WARN] FIX-VIDEO-DATABASE.bat still missing - run RESTORE-SCRIPTS.bat
)
echo Then run KARA-GEMINI-FIX-NOW.bat — diagnosis must show stream-v5 NOT auto-model-v3
echo.
if not exist "assets\branding\icon.png" (
  echo [WARN] assets\branding\icon.png is missing.
  echo        Drag your brand icon onto COPY-LOGO.bat before testing login.
  echo.
)
echo Close ALL Chrome windows, then wait for Flutter to start...
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

:ClearPullBlockers
echo   Replacing local helper copies with GitHub versions...
git checkout -- "scripts\diagnose-gemini.js" 2>nul
git checkout -- "scripts/diagnose-gemini.js" 2>nul
git checkout -- "KARA-SEE-UPDATES-NOW.bat" 2>nul
git checkout -- "KARA-GEMINI-FIX-NOW.bat" 2>nul
del /f /q "FIX-VIDEO-DATABASE.bat" 2>nul
del /f /q "KARA-FIX-VIDEO-DATABASE.bat" 2>nul
del /f /q "KARA-PASTE-THIS-IN-SUPABASE.txt" 2>nul
del /f /q "supabase\fix_video_tables.sql" 2>nul
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
