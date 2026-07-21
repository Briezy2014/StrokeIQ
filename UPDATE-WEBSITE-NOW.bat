@echo off
REM Alias — same as DOUBLE-CLICK-ME.bat
cd /d "%~dp0"
if exist "%~dp0DOUBLE-CLICK-ME.bat" (
  call "%~dp0DOUBLE-CLICK-ME.bat"
  exit /b %ERRORLEVEL%
)
echo Missing DOUBLE-CLICK-ME.bat
pause
exit /b 1
