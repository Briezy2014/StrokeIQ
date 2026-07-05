@echo off
REM SwimIQ — launch Flutter web in Chrome (use this on Windows)
cd /d "%~dp0"
echo.
echo SwimIQ Flutter web launcher
echo Folder: %CD%
echo.

flutter pub get
if errorlevel 1 (
  echo.
  echo pub get failed. If your Windows username has a space ^(e.g. Kara Williams^),
  echo run setup-short-path.bat from the StrokeIQ folder first, then try again.
  echo See docs\WINDOWS_SETUP.md
  pause
  exit /b 1
)

flutter run -d chrome
if errorlevel 1 pause
