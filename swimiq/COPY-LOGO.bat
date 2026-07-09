@echo off
title SwimIQ Copy Logo (512x512)
cd /d "%~dp0"

if "%~1"=="" (
  echo.
  echo ========================================
  echo  SwimIQ - COPY LOGO (512x512)
  echo ========================================
  echo.
  echo Drag your 512x512 icon.png ONTO this file,
  echo OR run: COPY-LOGO.bat "C:\path\to\your\logo.png"
  echo.
  echo (Same as DRAG-LOGO-HERE.bat)
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
echo Done! Logo copied to:
echo   assets\branding\icon.png
echo   assets\branding\swimiq_logo.png
echo   assets\branding\swimiq_icon.png
echo   web\favicon.png
echo   web\icons\Icon-512.png
echo   web\icons\Icon-192.png
echo.
echo Close Chrome, then run LAUNCH-CHROME.bat
pause
