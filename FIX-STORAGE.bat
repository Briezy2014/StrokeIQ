@echo off
REM Easy-to-find name (same as FIX-ELITE-STORAGE-NOW.bat)
cd /d "%~dp0"
call "%~dp0FIX-ELITE-STORAGE-NOW.bat"
exit /b %ERRORLEVEL%
