@echo off
setlocal
title SwimIQ - correct app only
cd /d "%~dp0"

echo.
echo ============================================
echo   SwimIQ - open the CORRECT app
echo   (Elite branch with pool/rope/passport)
echo ============================================
echo.
echo This fixes: wrong dashboard, Elite ads,
echo locked AI, missing Export/Print.
echo.

if not exist ".git" (
  echo [FAIL] Put this file in your Desktop\StrokeIQ folder.
  pause
  exit /b 1
)

echo Closing old Chrome SwimIQ tabs is recommended.
echo.
echo Switching to the Elite dashboard branch...
git fetch origin
git merge --abort >nul 2>&1
git checkout -f cursor/elite-video-on-dashboard-b7ef
if errorlevel 1 (
  echo [FAIL] Could not switch branch.
  pause
  exit /b 1
)
git reset --hard origin/cursor/elite-video-on-dashboard-b7ef
if errorlevel 1 (
  echo [FAIL] Could not update from GitHub.
  pause
  exit /b 1
)

if not exist "swimiq\lib\widgets\swimiq_rope_climb_card.dart" (
  echo [FAIL] Rope climb file missing - wrong folder.
  pause
  exit /b 1
)

echo [OK] Correct branch loaded.
echo.
cd /d "%~dp0swimiq"
call flutter pub get
if errorlevel 1 (
  echo [FAIL] flutter pub get failed.
  pause
  exit /b 1
)

echo.
echo Launching Chrome...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0swimiq\run-chrome.ps1"
if errorlevel 1 (
  echo.
  echo run-chrome.ps1 failed - trying LAUNCH-CHROME.bat...
  call "%~dp0swimiq\LAUNCH-CHROME.bat"
)

echo.
echo After login:
echo   - Dashboard should show pool/rope climb
echo   - NO black Elite upgrade ad
echo   - Passport has Export PDF + Print
echo   - demo@swimiqapp.com can run AI
echo.
pause
