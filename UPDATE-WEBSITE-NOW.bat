@echo off
REM Alias — opens local upload zip (no website)
cd /d "%~dp0"
if exist "%~dp0DOUBLE-CLICK-ME.vbs" (
  wscript "%~dp0DOUBLE-CLICK-ME.vbs"
  exit /b 0
)
if exist "%~dp0DOUBLE-CLICK-ME.bat" (
  call "%~dp0DOUBLE-CLICK-ME.bat"
  exit /b 0
)
echo Missing DOUBLE-CLICK-ME.vbs
pause
