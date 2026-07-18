@echo off
setlocal EnableExtensions
title SwimIQ WORKING APP - localhost only
cd /d "%~dp0"

echo.
echo ############################################################
echo #  WORKING APP - localhost only                           #
echo #  Close swimiqapp.com first                              #
echo ############################################################
echo.
echo This one file:
echo   1. Downloads the latest fixes from GitHub
echo   2. Checks coaching key (GEMINI_API_KEY)
echo   3. Starts Elite + Chrome on THIS PC
echo.

echo [1/3] Updating files from GitHub...
git -C "%CD%" fetch origin cursor/elite-video-on-dashboard-b7ef
if errorlevel 1 (
  echo [FAIL] git fetch failed. Check Wi-Fi.
  pause
  exit /b 1
)
git -C "%CD%" checkout -f cursor/elite-video-on-dashboard-b7ef
git -C "%CD%" reset --hard origin/cursor/elite-video-on-dashboard-b7ef
if errorlevel 1 (
  echo [FAIL] Could not update files.
  pause
  exit /b 1
)
echo [OK] Files updated.
echo.

if not exist "%CD%\swimiq\.env" (
  echo [FAIL] Missing swimiq\.env
  if exist "%CD%\swimiq\.env.example" copy /Y "%CD%\swimiq\.env.example" "%CD%\swimiq\.env" >nul
)

echo [2/3] Checking coaching key (GEMINI_API_KEY)...
set "HAS_GEMINI=0"
findstr /I /R /C:"^GEMINI_API_KEY=AIza" "%CD%\swimiq\.env" >nul 2>&1 && set "HAS_GEMINI=1"
findstr /I /R /C:"^GEMINI_API_KEY=AI" "%CD%\swimiq\.env" >nul 2>&1 && set "HAS_GEMINI=1"
if "%HAS_GEMINI%"=="0" (
  echo.
  echo [NEED KEY] Coaching tips need GEMINI_API_KEY in swimiq\.env
  echo.
  echo Notepad will open swimiq\.env
  echo Add this line, then save and close Notepad:
  echo.
  echo   GEMINI_API_KEY=AIza...your_google_ai_studio_key...
  echo.
  echo Use the same Google AI Studio key SwimIQ already uses.
  echo.
  if exist "%CD%\ADD-GEMINI-KEY-FOR-COACHING.txt" start "" notepad "%CD%\ADD-GEMINI-KEY-FOR-COACHING.txt"
  start "" notepad "%CD%\swimiq\.env"
  echo After you SAVE the key in Notepad, press any key here to continue...
  pause >nul
)

echo [3/3] Starting Elite + Chrome localhost...
echo Address bar MUST be 127.0.0.1 or localhost - NOT swimiqapp.com
echo.
call "%CD%\FINAL-TRY-THIS-ONLY.bat"
exit /b %ERRORLEVEL%
