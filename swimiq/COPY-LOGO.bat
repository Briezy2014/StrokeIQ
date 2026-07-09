@echo off
title SwimIQ Copy Logo (512x512)
cd /d "%~dp0"

if "%~1"=="" (
  echo.
  echo ========================================
  echo  SwimIQ - COPY LOGO (512x512)
  echo ========================================
  echo.
  echo Drag your 512x512 app icon ONTO this file,
  echo OR run: COPY-LOGO.bat "C:\path\to\your\icon.png"
  echo.
  echo Saves as assets\branding\icon.png (login) and logo.png (your brand folder).
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
copy /Y "%SRC%" "assets\branding\logo.png"
copy /Y "%SRC%" "web\favicon.png"
copy /Y "%SRC%" "web\icons\Icon-512.png"
copy /Y "%SRC%" "web\icons\Icon-192.png"

echo.
echo Done! Logo copied to:
echo   assets\branding\icon.png   ^(login screen — app reads THIS^)
echo   assets\branding\logo.png   ^(same file, brand folder name^)
echo   web\favicon.png
echo   web\icons\Icon-512.png
echo   web\icons\Icon-192.png
echo.
echo Close Chrome, then run KARA-SEE-UPDATES-NOW.bat
pause
