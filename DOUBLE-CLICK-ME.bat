@echo off
REM OneDrive often hides/deletes .bat — use DOUBLE-CLICK-ME.vbs instead.
cd /d "%~dp0"
if exist "%~dp0DOUBLE-CLICK-ME.vbs" (
  wscript "%~dp0DOUBLE-CLICK-ME.vbs"
  exit /b 0
)
echo DOUBLE-CLICK-ME.vbs missing in this folder.
echo Open UPLOAD-TO-GODADDY and upload swimiq-web-godaddy.zip
pause
