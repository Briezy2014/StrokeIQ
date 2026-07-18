@echo off
setlocal
title SwimIQ - Fix login logo
cd /d "%~dp0"

echo.
echo ============================================
echo   Fix login logo (stop triangle placeholder)
echo ============================================
echo.

if not exist ".git" (
  echo [FAIL] Run this from Desktop\StrokeIQ
  pause
  exit /b 1
)

echo Updating files...
git fetch origin cursor/elite-video-on-dashboard-b7ef
git checkout -f cursor/elite-video-on-dashboard-b7ef
git reset --hard origin/cursor/elite-video-on-dashboard-b7ef

echo.
echo Checking brand file...
if exist "swimiq\assets\branding\icon.png" (
  echo [OK] swimiq\assets\branding\icon.png found
) else (
  echo [FAIL] icon.png missing.
  echo If Aspyn has a newer PNG, drag it onto:
  echo   Desktop\StrokeIQ\swimiq\COPY-LOGO.bat
  pause
  exit /b 1
)

echo.
echo Closing Chrome SwimIQ windows is recommended.
echo Then restart the app with:
echo   START-SWIMIQ-WITH-ELITE.bat
echo or:
echo   swimiq\KARA-SEE-UPDATES-NOW.bat
echo.
echo You should see Aspyn's SWIMIQ lockup (blue A + name), NOT a blue triangle.
echo.
pause
exit /b 0
