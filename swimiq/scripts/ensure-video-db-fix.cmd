@echo off
cd /d "%~dp0\.."
set "ROOT=%CD%"
if exist "%~dp0ensure-video-db-fix.ps1" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0ensure-video-db-fix.ps1" -SwimIqRoot "%ROOT%"
) else (
  echo [WARN] ensure-video-db-fix.ps1 missing - run RESTORE-SCRIPTS.bat or KARA-SEE-UPDATES-NOW.bat
  exit /b 1
)
