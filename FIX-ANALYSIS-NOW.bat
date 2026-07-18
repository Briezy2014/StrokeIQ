@echo off
REM Alias only. Real starter is START-SWIMIQ-WITH-ELITE.bat (already on your PC).
cd /d "%~dp0"
if exist "%CD%\START-SWIMIQ-WITH-ELITE.bat" (
  call "%CD%\START-SWIMIQ-WITH-ELITE.bat"
  exit /b %ERRORLEVEL%
)
echo [FAIL] START-SWIMIQ-WITH-ELITE.bat is missing.
echo Open Desktop\StrokeIQ and run GET-LATEST-FIXED-APP.bat first.
pause
exit /b 1
