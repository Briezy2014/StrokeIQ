@echo off
title SwimIQ - CLICK ME FIRST
cd /d "%~dp0"

echo.
echo ============================================
echo   CLICK ME FIRST - update StrokeIQ folder
echo ============================================
echo.
echo Your PC was missing newer fix files.
echo This downloads them from GitHub now.
echo.

call "%~dp0GET-LATEST-FIXED-APP.bat"
exit /b %ERRORLEVEL%
