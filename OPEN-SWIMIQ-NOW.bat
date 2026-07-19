@echo off
setlocal EnableExtensions
title Open SwimIQ NOW
cd /d "%~dp0"

echo.
echo ============================================
echo   OPEN SwimIQ NOW
echo ============================================
echo.

set "WEBDIR="
if exist "%CD%\swimiq\build\web\index.html" set "WEBDIR=%CD%\swimiq\build\web"
if not defined WEBDIR if exist "C:\SwimIQWork\swimiq\build\web\index.html" set "WEBDIR=C:\SwimIQWork\swimiq\build\web"

if not defined WEBDIR (
  echo [FAIL] App is not built yet.
  echo.
  echo First run: START-SWIMIQ-WITH-ELITE.bat
  echo Wait until it finishes the build, then run THIS file.
  echo.
  pause
  exit /b 1
)

echo [OK] Found app files:
echo     %WEBDIR%
echo.
echo Starting web server if needed...
powershell -NoProfile -ExecutionPolicy Bypass -File "%CD%\swimiq\scripts\start-web-server-window.ps1" -WebDir "%WEBDIR%" -Port 7357
if errorlevel 1 (
  echo [FAIL] Could not start web server.
  echo Make sure Python is installed.
  pause
  exit /b 1
)

echo.
echo Opening browser to http://127.0.0.1:7357/
echo.
start "" "http://127.0.0.1:7357/"

echo.
echo ============================================
echo Leave open: "SwimIQ WEB SERVER - DO NOT CLOSE"
echo If browser says refused to connect, that
echo server window was closed - run THIS bat again.
echo ============================================
echo.
pause
exit /b 0
