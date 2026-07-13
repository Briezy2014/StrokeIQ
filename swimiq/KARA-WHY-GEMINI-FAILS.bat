@echo off
title SwimIQ - WHY GEMINI FAILS
cd /d "%~dp0"
echo.
echo ============================================================
echo   KARA - Find out WHY video AI is broken
echo ============================================================
echo.
echo This writes GEMINI-DIAGNOSIS.txt in this folder.
echo NO Command Prompt typing needed.
echo.
pause

if not exist "%~dp0scripts\diagnose-gemini-video.ps1" (
  echo [ERROR] Missing scripts\diagnose-gemini-video.ps1
  echo Double-click KARA-SEE-UPDATES-NOW.bat first.
  pause
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\diagnose-gemini-video.ps1"
set ERR=%ERRORLEVEL%

echo.
if %ERR% EQU 0 (
  echo Open GEMINI-DIAGNOSIS.txt — it says exactly what is wrong.
  start notepad "%~dp0GEMINI-DIAGNOSIS.txt"
) else (
  echo Something failed — still read GEMINI-DIAGNOSIS.txt for details.
  if exist "%~dp0GEMINI-DIAGNOSIS.txt" start notepad "%~dp0GEMINI-DIAGNOSIS.txt"
)

pause
