@echo off
setlocal EnableExtensions
title SwimIQ - DO THIS ONE THING
cd /d "%~dp0"

echo.
echo ############################################################
echo #  SwimIQ — update website (double-click path)             #
echo ############################################################
echo.

REM Preferred path: download READY connected zip (no git / no flutter build).
if exist "%~dp0DOUBLE-CLICK-ME.bat" (
  call "%~dp0DOUBLE-CLICK-ME.bat"
  exit /b %ERRORLEVEL%
)

echo [FAIL] DOUBLE-CLICK-ME.bat missing.
echo Download the starter pack from:
echo   https://github.com/Briezy2014/StrokeIQ/releases/tag/swimiq-web-LATEST
echo Extract into Desktop\StrokeIQ, then double-click DOUBLE-CLICK-ME.bat
start "" "https://github.com/Briezy2014/StrokeIQ/releases/tag/swimiq-web-LATEST"
pause
exit /b 1
