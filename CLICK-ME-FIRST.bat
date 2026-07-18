@echo off
title SwimIQ - CLICK ME FIRST
cd /d "%~dp0"
echo.
echo ============================================
echo   Update + start Elite on this PC
echo ============================================
echo.
call "%~dp0GET-LATEST-FIXED-APP.bat"
exit /b %ERRORLEVEL%
