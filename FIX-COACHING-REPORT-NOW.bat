@echo off
REM Same as OPEN-WORKING-APP-NOW.bat (kept as an alias name)
cd /d "%~dp0"
if exist "%CD%\OPEN-WORKING-APP-NOW.bat" (
  call "%CD%\OPEN-WORKING-APP-NOW.bat"
  exit /b %ERRORLEVEL%
)
echo [FAIL] Run GET-LATEST-FIXED-APP.bat first, then OPEN-WORKING-APP-NOW.bat
pause
exit /b 1
