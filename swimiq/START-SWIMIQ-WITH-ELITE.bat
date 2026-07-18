@echo off
title Start SwimIQ with Elite
cd /d "%~dp0.."
if exist "%CD%\START-SWIMIQ-WITH-ELITE.bat" (
  call "%CD%\START-SWIMIQ-WITH-ELITE.bat"
  exit /b %ERRORLEVEL%
)
echo [FAIL] Open Desktop\StrokeIQ and run START-SWIMIQ-WITH-ELITE.bat there.
pause
exit /b 1
