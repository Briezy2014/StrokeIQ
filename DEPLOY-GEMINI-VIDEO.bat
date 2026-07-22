@echo off
title SwimIQ - Deploy Gemini video
cd /d "%~dp0"
if exist "%CD%\swimiq\DEPLOY-GEMINI-VIDEO.bat" (
  call "%CD%\swimiq\DEPLOY-GEMINI-VIDEO.bat"
  exit /b %ERRORLEVEL%
)
if exist "%CD%\swimiq\KARA-GEMINI-FIX-NOW.bat" (
  call "%CD%\swimiq\KARA-GEMINI-FIX-NOW.bat"
  exit /b %ERRORLEVEL%
)
echo [FAIL] Missing swimiq\DEPLOY-GEMINI-VIDEO.bat
echo Run GET-LATEST-FIXED-APP.bat after GitHub works (phone hotspot).
pause
exit /b 1
