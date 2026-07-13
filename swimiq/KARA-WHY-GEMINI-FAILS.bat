@echo off
title SwimIQ - WHY GEMINI FAILS
cd /d "%~dp0"
echo.
echo ============================================================
echo   KARA - Find out WHY video AI is broken
echo ============================================================
echo.
echo This writes GEMINI-DIAGNOSIS.txt in this folder.
echo NO typing needed - just read the file when done.
echo.
pause

set "PS1=%~dp0scripts\diagnose-gemini-video.ps1"
if not exist "%PS1%" set "PS1=%~dp0scripts\diagnosis.ps1"
if not exist "%PS1%" (
  echo [ERROR] Missing scripts\diagnose-gemini-video.ps1
  echo Double-click KARA-SEE-UPDATES-NOW.bat first.
  pause
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%"
set ERR=%ERRORLEVEL%

echo.
if %ERR% EQU 0 (
  echo Opening GEMINI-DIAGNOSIS.txt ...
) else (
  echo Script had errors - still read GEMINI-DIAGNOSIS.txt if it exists.
)
if exist "%~dp0GEMINI-DIAGNOSIS.txt" start notepad "%~dp0GEMINI-DIAGNOSIS.txt"

pause
