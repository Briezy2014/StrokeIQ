@echo off
setlocal
cd /d "%~dp0"

echo.
echo ============================================
echo   SwimIQ - FORCE FIXED APP
echo   Starts Elite server + Chrome together
echo   Folder: %CD%
echo ============================================
echo.
echo Do NOT use StrokeIQ-Elite.
echo Use this Desktop\StrokeIQ folder only.
echo.

if not exist ".git" (
  echo [FAIL] Run this from Desktop\StrokeIQ
  pause
  exit /b 1
)

if not exist "%CD%\START-SWIMIQ-WITH-ELITE.bat" (
  echo [FAIL] Missing START-SWIMIQ-WITH-ELITE.bat
  echo Look in Desktop\StrokeIQ for that file.
  pause
  exit /b 1
)

echo Updating from GitHub, then starting Elite + app...
echo Leave windows open. First launch can take several minutes.
echo.
call "%CD%\START-SWIMIQ-WITH-ELITE.bat"
exit /b %ERRORLEVEL%
