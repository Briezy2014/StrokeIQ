@echo off
cd /d "%~dp0"
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
echo Then double-click this file again.
echo.
pause
exit /b 1
