@echo off
REM Root shortcut — starts the Elite analysis server
cd /d "%~dp0"
if exist "%~dp0swimiq\START-ELITE-ANALYSIS-SERVER.bat" (
  call "%~dp0swimiq\START-ELITE-ANALYSIS-SERVER.bat"
) else if exist "%~dp0services\video_analysis\requirements-windows.txt" (
  cd /d "%~dp0services\video_analysis"
  call "%~dp0swimiq\START-ELITE-ANALYSIS-SERVER.bat" 2>nul
  if errorlevel 1 (
    echo Run GET-LATEST-FIXED-APP.bat first, then try again.
    pause
  )
) else (
  echo.
  echo [FAIL] Elite server files are missing from this folder.
  echo.
  echo In PowerShell, run:
  echo   cd "C:\Users\Kara Williams\OneDrive\Desktop\StrokeIQ"
  echo   git fetch origin
  echo   git reset --hard origin/cursor/elite-video-on-dashboard-b7ef
  echo.
  echo Then double-click START-ELITE-ANALYSIS-SERVER.bat again.
  echo.
  pause
)
