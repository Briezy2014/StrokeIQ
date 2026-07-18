@echo off
setlocal
title Make GoDaddy zip from build\web
cd /d "%~dp0"

echo.
echo ============================================
echo   Make swimiq-web-godaddy.zip
echo ============================================
echo.
echo Looking in: %CD%\build
echo.

if not exist "build\web\main.dart.js" (
  echo [FAIL] build\web\main.dart.js missing.
  echo Run this first from Desktop\StrokeIQ:
  echo   PUBLISH-SWIMIQAPP-COM.bat
  echo.
  pause
  exit /b 1
)

if exist "build\swimiq-web-godaddy.zip" del /f /q "build\swimiq-web-godaddy.zip"

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\zip-web-godaddy.ps1"
if errorlevel 1 (
  echo [FAIL] Zip step failed.
  pause
  exit /b 1
)

if not exist "build\swimiq-web-godaddy.zip" (
  echo [FAIL] Zip still missing after script.
  pause
  exit /b 1
)

echo.
echo [OK] ZIP is here:
echo   %CD%\build\swimiq-web-godaddy.zip
echo.
echo That is the GoDaddy upload file.
echo Upload THAT zip into public_html, then Extract.
echo.
explorer.exe /select,"%CD%\build\swimiq-web-godaddy.zip"
pause
exit /b 0
