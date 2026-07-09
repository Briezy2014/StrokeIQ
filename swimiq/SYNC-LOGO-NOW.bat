@echo off
title SwimIQ Sync Logo Everywhere
cd /d "%~dp0"

if "%~1"=="" (
  echo.
  echo ========================================
  echo  SwimIQ - SYNC YOUR BRAND ICON
  echo ========================================
  echo.
  echo Drag your 512x512 app icon PNG onto this file.
  echo.
  echo Saves to assets\branding\icon.png
  echo ^(login screen reads THIS file only^)
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
copy /Y "%SRC%" "web\favicon.png"
copy /Y "%SRC%" "web\icons\Icon-512.png"
copy /Y "%SRC%" "web\icons\Icon-192.png"

echo.
echo ========================================
echo  LOGO SYNCED
echo ========================================
echo.
echo Your icon is now in:
echo   assets\branding\icon.png   ^(login screen^)
echo   web\favicon.png
echo   web\icons\Icon-512.png
echo   web\icons\Icon-192.png
echo.
echo NEXT:
echo   1. Close Chrome completely
echo   2. Run KARA-SEE-UPDATES-NOW.bat
echo   3. Ctrl+F5 on the login page
echo.
pause
