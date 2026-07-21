@echo off
setlocal EnableExtensions
title SwimIQ - DO THIS ONE THING

REM Go to this bat's folder. %CD% is safest with spaces (Kara Williams / OneDrive).
cd /d "%~dp0"
if errorlevel 1 (
  echo [FAIL] Could not open this folder.
  pause
  exit /b 1
)
set "REPO=%CD%"

echo.
echo ############################################################
echo #  SwimIQ website publish - ONE button                     #
echo ############################################################
echo.
echo Repo folder:
echo   %REPO%
echo.

if not exist "%REPO%\.git" (
  echo [FAIL] Wrong folder.
  echo Open Desktop\StrokeIQ and run DO-THIS-ONE-THING.bat there.
  pause
  exit /b 1
)

if not exist "%REPO%\swimiq\pubspec.yaml" (
  echo [FAIL] Missing swimiq\pubspec.yaml under:
  echo   %REPO%
  pause
  exit /b 1
)

echo [1/3] Downloading latest Dryland + Power Index files...
git -C "%REPO%" fetch origin cursor/dryland-power-index-b7ef
if errorlevel 1 (
  echo [FAIL] git fetch failed. Check Wi-Fi / open https://github.com
  pause
  exit /b 1
)

git -C "%REPO%" merge --abort >nul 2>&1
git -C "%REPO%" checkout -f cursor/dryland-power-index-b7ef
if errorlevel 1 (
  echo [FAIL] git checkout failed.
  pause
  exit /b 1
)

git -C "%REPO%" reset --hard origin/cursor/dryland-power-index-b7ef
if errorlevel 1 (
  echo [FAIL] git reset failed.
  pause
  exit /b 1
)
echo [OK] On cursor/dryland-power-index-b7ef
git -C "%REPO%" log -1 --oneline
echo.

echo [2/3] Building website zip (needs pub.dev Wi-Fi)...
echo If this fails, DO NOT upload any zip.
call "%REPO%\PUBLISH-SWIMIQAPP-COM.bat"
exit /b %ERRORLEVEL%
