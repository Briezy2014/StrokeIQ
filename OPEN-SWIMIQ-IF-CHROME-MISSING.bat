@echo off
REM Alias - same as OPEN-SWIMIQ-NOW.bat
cd /d "%~dp0"
call "%~dp0OPEN-SWIMIQ-NOW.bat"
exit /b %ERRORLEVEL%
