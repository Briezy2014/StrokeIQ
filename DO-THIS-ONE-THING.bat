@echo off
title SwimIQ - one click upload helper
cd /d "%~dp0"
echo.
echo Opening local website zip (no GitHub)...
echo.
if exist "%~dp0DOUBLE-CLICK-ME.vbs" (
  wscript "%~dp0DOUBLE-CLICK-ME.vbs"
  exit /b 0
)
if exist "%~dp0DOUBLE-CLICK-ME.bat" (
  call "%~dp0DOUBLE-CLICK-ME.bat"
  exit /b 0
)
echo [FAIL] DOUBLE-CLICK-ME.vbs missing.
echo Open UPLOAD-TO-GODADDY and upload swimiq-web-godaddy.zip
pause
