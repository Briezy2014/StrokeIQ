@echo off
setlocal
title SwimIQ Build GoDaddy
REM Always use this bat's folder — never depend on caller's CD.
set "HERE=%~dp0"
if "%HERE:~-1%"=="\" set "HERE=%HERE:~0,-1%"
set "PS1=%HERE%\SWIMIQ-BUILD-GODADDY-NOW.ps1"
if not exist "%PS1%" (
  echo [FAIL] Missing %PS1%
  pause
  exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%"
exit /b %ERRORLEVEL%
