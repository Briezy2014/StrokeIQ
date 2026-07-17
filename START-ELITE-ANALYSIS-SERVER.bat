@echo off
REM Root shortcut — same as swimiq\START-ELITE-ANALYSIS-SERVER.bat
cd /d "%~dp0"
if exist "%~dp0swimiq\START-ELITE-ANALYSIS-SERVER.bat" (
  call "%~dp0swimiq\START-ELITE-ANALYSIS-SERVER.bat"
) else (
  echo.
  echo [FAIL] swimiq\START-ELITE-ANALYSIS-SERVER.bat is missing.
  echo Your StrokeIQ folder is out of date.
  echo.
  echo Fix: open PowerShell in this StrokeIQ folder and run:
  echo   git fetch origin
  echo   git reset --hard origin/cursor/elite-video-on-dashboard-b7ef
  echo.
  echo Then double-click this file again.
  echo.
  pause
)
