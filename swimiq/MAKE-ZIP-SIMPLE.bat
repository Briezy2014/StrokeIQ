@echo off
setlocal
title Make website zip - SIMPLE
cd /d "%~dp0"

echo.
echo Making zip from build\web ...
echo Folder: %CD%
echo.

if not exist "build\web\main.dart.js" (
  echo [FAIL] No build\web\main.dart.js
  echo You only have a partial build. Run from Desktop\StrokeIQ:
  echo   DO-THIS-ONE-THING.bat
  pause
  exit /b 1
)

if exist "build\swimiq-web-godaddy.zip" del /f /q "build\swimiq-web-godaddy.zip"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$web='%~dp0build\web'; $zip='%~dp0build\swimiq-web-godaddy.zip'; " ^
  "if (Test-Path $zip) { Remove-Item -LiteralPath $zip -Force }; " ^
  "Add-Type -AssemblyName System.IO.Compression.FileSystem; " ^
  "[IO.Compression.ZipFile]::CreateFromDirectory($web, $zip, 'Optimal', $false); " ^
  "if (-not (Test-Path -LiteralPath $zip)) { exit 1 }; " ^
  "Write-Host ('OK ' + $zip); Write-Host ('SizeMB ' + [math]::Round((Get-Item $zip).Length/1MB,1))"

if errorlevel 1 (
  echo [FAIL] Could not create zip.
  pause
  exit /b 1
)

echo.
echo [OK] ZIP is here - File Explorer will highlight it:
echo   %CD%\build\swimiq-web-godaddy.zip
echo.
explorer.exe /select,"%CD%\build\swimiq-web-godaddy.zip"
echo.
echo NEXT: In GoDaddy public_html click Upload, pick THAT zip, then Extract.
echo.
pause
exit /b 0
