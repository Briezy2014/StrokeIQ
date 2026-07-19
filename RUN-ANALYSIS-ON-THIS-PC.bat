@echo off
setlocal
title SwimIQ - redirected
cd /d "%~dp0"
echo.
echo This file is only a shortcut.
echo Running START-SWIMIQ-WITH-ELITE.bat ...
echo.
call "%~dp0START-SWIMIQ-WITH-ELITE.bat"
exit /b %ERRORLEVEL%
