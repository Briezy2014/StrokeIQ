@echo off
cd /d "%~dp0"
echo.
echo Tip: For the full app, double-click START-SWIMIQ-WITH-ELITE.bat instead.
echo This file only starts the analysis server at http://127.0.0.1:8080
echo.
if exist "%~dp0swimiq\START-ELITE-ANALYSIS-SERVER.bat" (
  call "%~dp0swimiq\START-ELITE-ANALYSIS-SERVER.bat"
  exit /b %ERRORLEVEL%
)
echo.
echo [FAIL] swimiq\START-ELITE-ANALYSIS-SERVER.bat is missing.
echo Your folder is out of date. In PowerShell run:
echo.
echo   cd "C:\Users\Kara Williams\OneDrive\Desktop\StrokeIQ"
echo   git fetch origin
echo   git reset --hard origin/cursor/elite-video-on-dashboard-b7ef
echo.
echo Then double-click START-SWIMIQ-WITH-ELITE.bat
echo.
pause
exit /b 1
