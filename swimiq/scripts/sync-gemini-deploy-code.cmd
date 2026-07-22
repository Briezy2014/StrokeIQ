@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0sync-gemini-deploy-code.ps1" -SwimIqRoot "%~dp0.."
exit /b %ERRORLEVEL%
