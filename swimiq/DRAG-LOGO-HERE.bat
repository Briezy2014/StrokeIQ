@echo off
title SwimIQ Copy Logo (512x512)
cd /d "%~dp0"

if "%~1"=="" (
  echo.
  echo ========================================
  echo  SwimIQ - DRAG YOUR LOGO HERE
  echo ========================================
  echo.
  echo Drag your 512x512 app icon ONTO this file.
  echo.
  echo Or run: DRAG-LOGO-HERE.bat "C:\path\to\your\icon.png"
  echo.
  echo Saves as assets\branding\icon.png (login screen uses this file).
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
echo Done! Logo copied to:
echo   assets\branding\icon.png   ^(login screen^)
echo   web\favicon.png
echo   web\icons\Icon-512.png
echo   web\icons\Icon-192.png
echo.
echo Close Chrome, then run KARA-SEE-UPDATES-NOW.bat
pause
