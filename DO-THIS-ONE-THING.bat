@echo off
setlocal EnableExtensions
title SwimIQ - DO THIS ONE THING
cd /d "%~dp0"
set "REPO=%~dp0"
if "%REPO:~-1%"=="\" set "REPO=%REPO:~0,-1%"

echo.
echo ############################################################
echo #  SwimIQ website fix - ONE button                        #
echo #  Must run from: Desktop\StrokeIQ                        #
echo ############################################################
echo.
echo Repo folder:
echo   %REPO%
echo.

if not exist "%REPO%\.git" (
  echo [FAIL] Wrong folder. Open Desktop\StrokeIQ and double-click this file there.
  pause
  exit /b 1
)

echo [1/4] Downloading latest files...
git -C "%REPO%" fetch origin cursor/elite-video-on-dashboard-b7ef
if errorlevel 1 (
  echo [FAIL] git fetch failed. Check Wi-Fi, then run this again.
  pause
  exit /b 1
)
git -C "%REPO%" merge --abort >nul 2>&1
git -C "%REPO%" checkout -f cursor/elite-video-on-dashboard-b7ef
git -C "%REPO%" reset --hard origin/cursor/elite-video-on-dashboard-b7ef
if errorlevel 1 (
  echo [FAIL] Could not update files.
  pause
  exit /b 1
)
echo [OK] Files updated.
echo.

set "PS1=%REPO%\swimiq\SWIMIQ-BUILD-GODADDY-NOW.ps1"
set "ZIP=%REPO%\swimiq\build\swimiq-web-godaddy.zip"
set "ZIPPS1=%REPO%\swimiq\scripts\zip-web-godaddy.ps1"
set "WEB=%REPO%\swimiq\build\web"
set "STEPS=%REPO%\UPLOAD-THIS-ZIP-TO-GODADDY.txt"

if not exist "%PS1%" (
  echo [FAIL] Missing:
  echo   %PS1%
  pause
  exit /b 1
)

echo [2/4] Building website zip (5-10 minutes)...
echo Keep this window open.
echo.
echo Running:
echo   %PS1%
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%"
set "BUILD_ERR=%ERRORLEVEL%"

if not exist "%ZIP%" (
  echo.
  echo Zip missing after build. Trying zip-only from existing web build...
  if exist "%WEB%\main.dart.js" if exist "%ZIPPS1%" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%ZIPPS1%" -WebDir "%WEB%" -ZipPath "%ZIP%"
  )
)

if not exist "%ZIP%" (
  echo.
  echo [FAIL] Zip was not created.
  echo Expected:
  echo   %ZIP%
  echo.
  echo Build exit code: %BUILD_ERR%
  echo Scroll up for the red error above.
  pause
  exit /b 1
)

echo.
echo [3/4] ZIP READY:
echo   %ZIP%
echo.
explorer.exe /select,"%ZIP%"

echo [4/4] Opening upload steps + GoDaddy...
if exist "%STEPS%" start "" notepad "%STEPS%"
start "" "https://account.godaddy.com/products"

echo.
echo ############################################################
echo #  Upload the highlighted ZIP into public_html            #
echo #  Then Extract / overwrite                               #
echo #  Then Incognito: https://swimiqapp.com                  #
echo ############################################################
echo.
pause
exit /b 0
