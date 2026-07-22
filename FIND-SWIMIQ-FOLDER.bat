@echo off
setlocal EnableExtensions
title Find SwimIQ folder on this PC
cd /d "%~dp0"

echo.
echo Searching this PC for the real SwimIQ folder...
echo (Do NOT use Desktop\StrokeIQ - that path is often wrong.)
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0swimiq\scripts\find-swimiq-folder.ps1"
set "RC=%ERRORLEVEL%"
echo.
if not "%RC%"=="0" (
  echo Could not find swimiq\pubspec.yaml automatically.
  echo In File Explorer, search This PC for: pubspec.yaml
  echo Open the folder that also contains START-SWIMIQ.bat
)
pause
exit /b %RC%
