@echo off
setlocal EnableDelayedExpansion
title Restart Elite after FFmpeg install
cd /d "%~dp0"

echo.
echo ============================================
echo   Restart Elite analysis server
echo ============================================
echo.
echo Step 1: Close ANY old "Elite Video Lab - Analysis Server" windows.
echo         (Those were started BEFORE FFmpeg was installed.)
echo.
pause

echo.
echo Step 2: Checking FFmpeg...
call :RefreshPath
where ffmpeg >nul 2>&1
if errorlevel 1 (
  echo [FAIL] ffmpeg still not found.
  echo Open a NEW PowerShell and run:
  echo   winget install --id Gyan.FFmpeg -e --accept-package-agreements --accept-source-agreements
  echo Then run this file again.
  pause
  exit /b 1
)
where ffprobe >nul 2>&1
if errorlevel 1 (
  echo [FAIL] ffprobe still not found. Reinstall FFmpeg, then try again.
  pause
  exit /b 1
)
echo [OK] FFmpeg:
where ffmpeg
where ffprobe
echo.

echo Step 3: Starting Elite server and verifying health...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0swimiq\scripts\start-elite-and-wait.ps1"
if errorlevel 1 (
  echo [FAIL] Elite did not become healthy. Read the Elite server window.
  pause
  exit /b 1
)
echo.
echo [OK] Open SwimIQ with START-SWIMIQ-WITH-ELITE.bat  (or LAUNCH-CHROME.bat)
echo Health: http://127.0.0.1:8080/health
pause
exit /b 0

:RefreshPath
set "SYSPATH="
set "USRPATH="
for /f "skip=2 tokens=1,2*" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do (
  if /I "%%A"=="Path" set "SYSPATH=%%C"
)
for /f "skip=2 tokens=1,2*" %%A in ('reg query "HKCU\Environment" /v Path 2^>nul') do (
  if /I "%%A"=="Path" set "USRPATH=%%C"
)
if defined SYSPATH (
  if defined USRPATH (set "PATH=%SYSPATH%;%USRPATH%") else (set "PATH=%SYSPATH%")
) else if defined USRPATH (
  set "PATH=%USRPATH%"
)
if exist "%LOCALAPPDATA%\Microsoft\WinGet\Links" set "PATH=%LOCALAPPDATA%\Microsoft\WinGet\Links;%PATH%"
if exist "%ProgramFiles%\ffmpeg\bin" set "PATH=%ProgramFiles%\ffmpeg\bin;%PATH%"
exit /b 0
