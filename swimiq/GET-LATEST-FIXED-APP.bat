@echo off
title Get latest fixed app
cd /d "%~dp0.."
if exist "%CD%\GET-LATEST-FIXED-APP.bat" (
  call "%CD%\GET-LATEST-FIXED-APP.bat"
  exit /b %ERRORLEVEL%
)
echo [FAIL] Open Desktop\StrokeIQ and run GET-LATEST-FIXED-APP.bat there.
pause
exit /b 1
