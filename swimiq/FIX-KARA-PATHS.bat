@echo off
title SwimIQ Fix Paths
cd /d "%~dp0"
call "%~dp0scripts\ensure-logo-bats.cmd" 2>nul
echo.
echo ========================================
echo  SwimIQ - Fix Kara Paths
echo ========================================
echo.
echo Folder: %CD%
echo.

if not exist "%~dp0scripts\kara-fix-windows-once.ps1" (
  echo [ERROR] Missing scripts\kara-fix-windows-once.ps1
  echo.
  echo Double-click RESTORE-SCRIPTS.bat first, then try again.
  echo.
  goto done
)

if not exist "%~dp0scripts\swimiq-windows-paths.ps1" (
  echo [ERROR] Missing scripts\swimiq-windows-paths.ps1
  echo.
  echo Double-click RESTORE-SCRIPTS.bat first, then try again.
  echo.
  goto done
)

echo Running path fix... please wait...
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\kara-fix-windows-once.ps1"
set ERR=%ERRORLEVEL%
echo.
if %ERR% NEQ 0 (
  echo [ERROR] Fix failed with code %ERR%
  echo.
  echo Try: double-click RESTORE-SCRIPTS.bat then run this again.
) else (
  echo [OK] Fix finished.
  echo Next: double-click KARA-CLICK-THIS.bat
)

:done
echo.
echo Press any key to close this window...
pause >nul
