@echo off
title SwimIQ - CLICK ME FIRST
cd /d "%~dp0"
echo.
echo ============================================
echo   Update files, then run the FINAL TRY
echo ============================================
echo.
call "%~dp0GET-LATEST-FIXED-APP.bat"
if errorlevel 1 exit /b %ERRORLEVEL%
echo.
echo Next: double-click FINAL-TRY-THIS-ONLY.bat
echo Opening the step sheet...
start "" notepad "%~dp0FINAL-TRY-THIS-ONLY.txt"
explorer.exe "%CD%"
pause
exit /b 0
