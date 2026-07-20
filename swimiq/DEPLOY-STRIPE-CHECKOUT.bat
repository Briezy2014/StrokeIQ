@echo off
REM Thin wrapper — use DEPLOY-STRIPE-NOW.cmd (works with PowerShell blocks)
cd /d "%~dp0"
call "%~dp0DEPLOY-STRIPE-NOW.cmd"
exit /b %ERRORLEVEL%
