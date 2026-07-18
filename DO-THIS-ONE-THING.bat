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
echo #  SwimIQ website fix - ONE button                        #
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

echo [1/4] Downloading latest files...
git -C "%REPO%" fetch origin cursor/elite-video-on-dashboard-b7ef
if errorlevel 1 (
  echo [FAIL] git fetch failed. Check Wi-Fi.
  pause
  exit /b 1
)

git -C "%REPO%" merge --abort >nul 2>&1
git -C "%REPO%" checkout -f cursor/elite-video-on-dashboard-b7ef
if errorlevel 1 (
  echo [FAIL] git checkout failed.
  pause
  exit /b 1
)

git -C "%REPO%" reset --hard origin/cursor/elite-video-on-dashboard-b7ef
if errorlevel 1 (
  echo [FAIL] git reset failed.
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
set "SIMPLEZIP=%REPO%\swimiq\MAKE-ZIP-SIMPLE.bat"

echo Checking build script:
echo   %PS1%
echo.

if not exist "%PS1%" (
  echo [FAIL] Still missing build script after update:
  echo   %PS1%
  echo.
  echo Dir of swimiq:
  dir "%REPO%\swimiq\SWIMIQ-BUILD*" 
  pause
  exit /b 1
)

echo [2/4] Building website zip (5-10 minutes)...
echo Keep this window open.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%"
set "BUILD_ERR=%ERRORLEVEL%"

if not exist "%ZIP%" (
  echo.
  echo Zip missing after full build. Trying simple zip...
  if exist "%SIMPLEZIP%" (
    call "%SIMPLEZIP%"
  ) else if exist "%WEB%\main.dart.js" if exist "%ZIPPS1%" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%ZIPPS1%" -WebDir "%WEB%" -ZipPath "%ZIP%"
  )
)

if not exist "%ZIP%" (
  echo.
  echo [FAIL] Zip was not created.
  echo Expected:
  echo   %ZIP%
  echo Build exit code: %BUILD_ERR%
  echo Scroll up for the first red error.
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
echo #  In GoDaddy File Manager:                                #
echo #  public_html → Upload the highlighted ZIP → Extract      #
echo #  Then Incognito: https://swimiqapp.com                   #
echo ############################################################
echo.
pause
exit /b 0
