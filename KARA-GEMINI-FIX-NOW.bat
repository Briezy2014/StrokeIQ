@echo off
title SwimIQ - KARA fix Gemini video
cd /d "%~dp0"

if exist "%CD%\swimiq\KARA-GEMINI-FIX-NOW.bat" (
  echo.
  echo Opening: Desktop\StrokeIQ\swimiq\KARA-GEMINI-FIX-NOW.bat
  echo.
  call "%CD%\swimiq\KARA-GEMINI-FIX-NOW.bat"
  exit /b %ERRORLEVEL%
)

echo.
echo [FAIL] Gemini fix file is missing.
echo.
echo It should be here:
echo   %CD%\swimiq\KARA-GEMINI-FIX-NOW.bat
echo.
echo Your PC probably never downloaded latest files.
echo Fix Wi-Fi / phone hotspot, then run:
echo   GET-LATEST-FIXED-APP.bat
echo.
echo Also try opening the swimiq folder and look for:
echo   KARA-GEMINI-FIX-NOW.bat
echo   DEPLOY-GEMINI-VIDEO.bat
echo.
pause
exit /b 1
