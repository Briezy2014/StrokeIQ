@echo off
title Fix video upload
cd /d "%~dp0.."
if exist "%CD%\FIX-VIDEO-UPLOAD-NOW.bat" (
  call "%CD%\FIX-VIDEO-UPLOAD-NOW.bat"
  exit /b %ERRORLEVEL%
)
echo [FAIL] Open Desktop\StrokeIQ and run FIX-VIDEO-UPLOAD-NOW.bat there.
pause
exit /b 1
