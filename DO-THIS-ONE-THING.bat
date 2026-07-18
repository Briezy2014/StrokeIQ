@echo off
setlocal EnableDelayedExpansion
title SwimIQ - DO THIS ONE THING
cd /d "%~dp0"

echo.
echo ############################################################
echo #  SwimIQ website fix - ONE button                        #
echo #  Folder must be: Desktop\StrokeIQ                       #
echo ############################################################
echo.
echo Current folder:
echo   %CD%
echo.

if not exist ".git" (
  echo [FAIL] Wrong folder. Open Desktop\StrokeIQ and run this file THERE.
  pause
  exit /b 1
)

echo [1/4] Downloading latest files...
git fetch origin cursor/elite-video-on-dashboard-b7ef
if errorlevel 1 (
  echo [FAIL] git fetch failed. Check Wi-Fi, then run this again.
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
echo [OK] Files updated.
echo.

echo [2/4] Building website zip (can take 5-10 minutes)...
echo Keep this window open. Do not close it.
echo.
if not exist "swimiq\SWIMIQ-BUILD-GODADDY-NOW.bat" (
  echo [FAIL] Missing swimiq\SWIMIQ-BUILD-GODADDY-NOW.bat
  pause
  exit /b 1
)
call "swimiq\SWIMIQ-BUILD-GODADDY-NOW.bat"
set BUILD_ERR=%ERRORLEVEL%

set "ZIP=%CD%\swimiq\build\swimiq-web-godaddy.zip"
if not exist "%ZIP%" (
  echo.
  echo Build finished but zip missing. Trying zip-only step...
  call "swimiq\MAKE-GODADDY-ZIP-NOW.bat"
)

if not exist "%ZIP%" (
  echo.
  echo [FAIL] Still no zip at:
  echo   %ZIP%
  echo.
  echo Scroll up in this window for the real error.
  pause
  exit /b 1
)

echo.
echo [3/4] ZIP READY:
echo   %ZIP%
echo.
echo Opening that file in File Explorer now...
explorer.exe /select,"%ZIP%"

echo.
echo [4/4] Opening upload steps + GoDaddy...
start "" notepad "%CD%\UPLOAD-THIS-ZIP-TO-GODADDY.txt"
start "" "https://account.godaddy.com/products"

echo.
echo ############################################################
echo #  STOP - read the Notepad window                         #
echo #  Upload the highlighted ZIP into public_html            #
echo #  Then Extract / overwrite                               #
echo ############################################################
echo.
pause
exit /b 0
