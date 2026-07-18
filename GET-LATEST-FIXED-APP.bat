@echo off
title SwimIQ - Download latest fixed files
cd /d "%~dp0"

echo.
echo ============================================
echo   Download latest SwimIQ fixed files
echo   Folder: %CD%
echo ============================================
echo.

if not exist ".git" (
  echo [FAIL] This is not the StrokeIQ git folder.
  echo Open Desktop\StrokeIQ and run this file there.
  pause
  exit /b 1
)

echo Updating from GitHub...
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
echo ============================================
echo   File check after update
echo ============================================
set "MISSING=0"

if exist "CLICK-ME-FIRST.bat" (echo [OK] CLICK-ME-FIRST.bat) else (echo [BAD] CLICK-ME-FIRST.bat & set MISSING=1)
if exist "FIX-STORAGE.bat" (echo [OK] FIX-STORAGE.bat) else (echo [BAD] FIX-STORAGE.bat & set MISSING=1)
if exist "FIX-ELITE-STORAGE-NOW.bat" (echo [OK] FIX-ELITE-STORAGE-NOW.bat) else (echo [BAD] FIX-ELITE-STORAGE-NOW.bat & set MISSING=1)
if exist "PUBLISH-SWIMIQAPP-COM.bat" (echo [OK] PUBLISH-SWIMIQAPP-COM.bat) else (echo [BAD] PUBLISH-SWIMIQAPP-COM.bat & set MISSING=1)
if exist "START-SWIMIQ-WITH-ELITE.bat" (echo [OK] START-SWIMIQ-WITH-ELITE.bat) else (echo [BAD] START-SWIMIQ-WITH-ELITE.bat & set MISSING=1)
if exist "swimiq\scripts\zip-web-godaddy.ps1" (echo [OK] zip-web-godaddy.ps1) else (echo [BAD] zip-web-godaddy.ps1 & set MISSING=1)
if exist "swimiq\scripts\kill-elite-port.ps1" (echo [OK] kill-elite-port.ps1) else (echo [BAD] kill-elite-port.ps1 & set MISSING=1)

echo.
if "%MISSING%"=="1" (
  echo [FAIL] Some files are still missing. Internet/git problem.
  pause
  exit /b 1
)

echo ============================================
echo NEXT - pick ONE:
echo.
echo   A) Elite analysis / storage error:
echo      Double-click   FIX-STORAGE.bat
echo.
echo   B) Put Flutter app on swimiqapp.com:
echo      Double-click   PUBLISH-SWIMIQAPP-COM.bat
echo ============================================
echo.
echo Opening this folder so you can see FIX-STORAGE.bat ...
explorer.exe "%CD%"
pause
exit /b 0
