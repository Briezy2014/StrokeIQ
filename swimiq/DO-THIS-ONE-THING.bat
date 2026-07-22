@echo off
cd /d "%~dp0.."
call "%CD%\DO-THIS-ONE-THING.bat"
exit /b %ERRORLEVEL%
