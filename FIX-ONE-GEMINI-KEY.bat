@echo off
setlocal EnableExtensions
title FIX - only ONE Gemini key
cd /d "%~dp0"

echo.
echo ############################################################
echo #  FIX: only ONE Gemini key                                #
echo ############################################################
echo.
echo You must have exactly ONE line like:
echo   GEMINI_API_KEY=paste_one_key_here
echo.
echo Two GEMINI_API_KEY lines breaks coaching. This keeps the LAST key.
echo.

git -C "%CD%" fetch origin cursor/elite-video-on-dashboard-b7ef 2>nul
git -C "%CD%" checkout -f cursor/elite-video-on-dashboard-b7ef 2>nul
git -C "%CD%" reset --hard origin/cursor/elite-video-on-dashboard-b7ef 2>nul

if not exist "%CD%\swimiq\scripts\fix-one-gemini-key.ps1" (
  echo [FAIL] Missing fix script after update.
  pause
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%CD%\swimiq\scripts\fix-one-gemini-key.ps1"
if errorlevel 1 (
  echo.
  echo Notepad will open swimiq\.env — leave ONLY one GEMINI_API_KEY line, save, close.
  start "" notepad "%CD%\swimiq\.env"
  pause
)

echo.
echo Starting Elite with the single key...
call "%CD%\START-SWIMIQ-WITH-ELITE.bat"
exit /b %ERRORLEVEL%
