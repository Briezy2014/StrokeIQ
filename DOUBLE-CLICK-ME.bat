@echo off
REM OneDrive often hides/deletes .bat — use DOUBLE-CLICK-ME.vbs instead.
cd /d "%~dp0"
if exist "%~dp0DOUBLE-CLICK-ME.vbs" (
  wscript "%~dp0DOUBLE-CLICK-ME.vbs"
  exit /b %ERRORLEVEL%
)
echo DOUBLE-CLICK-ME.vbs missing in this folder.
echo Open the INNER Desktop\StrokeIQ\StrokeIQ folder if you have two.
pause
exit /b 1
