@echo off
title SwimIQ - Download latest fixed files
cd /d "%~dp0"

echo.
echo ============================================
echo   Download latest SwimIQ fixed files
echo   Folder: %CD%
echo ============================================
echo.
echo This updates YOUR Desktop\StrokeIQ folder from GitHub.
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
echo Checking important files...
if exist "FIX-ELITE-STORAGE-NOW.bat" (
  echo [OK] FIX-ELITE-STORAGE-NOW.bat
) else (
  echo [BAD] Missing FIX-ELITE-STORAGE-NOW.bat
)
if exist "FIX-STORAGE.bat" (
  echo [OK] FIX-STORAGE.bat
) else (
  echo [BAD] Missing FIX-STORAGE.bat
)
if exist "PUBLISH-SWIMIQAPP-COM.bat" (
  echo [OK] PUBLISH-SWIMIQAPP-COM.bat
) else (
  echo [BAD] Missing PUBLISH-SWIMIQAPP-COM.bat
)
if exist "START-SWIMIQ-WITH-ELITE.bat" (
  echo [OK] START-SWIMIQ-WITH-ELITE.bat
) else (
  echo [BAD] Missing START-SWIMIQ-WITH-ELITE.bat
)

echo.
echo ============================================
echo NEXT — pick ONE:
echo.
echo   Elite analysis broken / storage error:
echo     Double-click  FIX-STORAGE.bat
echo.
echo   Put real Flutter app on swimiqapp.com:
echo     Double-click  PUBLISH-SWIMIQAPP-COM.bat
echo ============================================
echo.
pause
