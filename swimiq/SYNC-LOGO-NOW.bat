@echo off
title SwimIQ Sync Logo Everywhere
cd /d "%~dp0"

if "%~1"=="" (
  echo.
  echo ========================================
  echo  SwimIQ - SYNC YOUR NEW LOGO
  echo ========================================
  echo.
  echo Drag your NEW 512x512 PNG onto this file.
  echo.
  echo This overwrites ALL logo copies so the old
  echo Aspyn icon cannot stick around.
  echo.
  pause
  exit /b 1
)

set "SRC=%~1"
if not exist "%SRC%" (
  echo File not found: %SRC%
  pause
  exit /b 1
)

if not exist "assets\branding" mkdir "assets\branding"
if not exist "web\icons" mkdir "web\icons"

copy /Y "%SRC%" "assets\branding\icon.png"
copy /Y "%SRC%" "assets\branding\swimiq_logo.png"
copy /Y "%SRC%" "assets\branding\swimiq_icon.png"
copy /Y "%SRC%" "web\favicon.png"
copy /Y "%SRC%" "web\icons\Icon-512.png"
copy /Y "%SRC%" "web\icons\Icon-192.png"

echo.
echo ========================================
echo  LOGO SYNCED
echo ========================================
echo.
echo Your PNG is now saved as:
echo   assets\branding\icon.png
echo   assets\branding\swimiq_logo.png
echo   assets\branding\swimiq_icon.png
echo   web\favicon.png + web\icons\
echo.
echo NEXT:
echo   1. Close Chrome completely
echo   2. Double-click LAUNCH-CHROME.bat
echo   3. Ctrl+F5 on the login page
echo.
echo If swimiqapp.com still shows the old logo, rebuild GoDaddy later.
echo.
pause
