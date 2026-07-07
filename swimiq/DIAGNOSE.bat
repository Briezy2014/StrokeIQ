@echo off
REM Quick check — double-click to see what's wrong
title SwimIQ Diagnose
cd /d "%~dp0"

echo.
echo === SwimIQ diagnose ===
echo Folder: %CD%
echo.

if exist "%~dp0scripts\launch-chrome-tonight.ps1" (
  echo [OK] launch-chrome-tonight.ps1 found
) else (
  echo [MISSING] scripts\launch-chrome-tonight.ps1 - run git pull
)

if exist "%~dp0scripts\kara-fix-windows-once.ps1" (
  echo [OK] kara-fix-windows-once.ps1 found
) else (
  echo [MISSING] scripts\kara-fix-windows-once.ps1 - run git pull
)

if exist "%~dp0.env" (
  echo [OK] .env found
) else (
  echo [MISSING] .env - copy .env.example to .env and add Supabase keys
)

if exist "S:\swimiq" (
  echo [OK] S:\swimiq drive mapped
) else (
  echo [WARN] S:\swimiq not mapped - run FIX-KARA-PATHS.bat
)

if exist "F:\bin\flutter.bat" (
  echo [OK] F:\bin\flutter.bat found
) else (
  echo [WARN] F:\bin\flutter not mapped - run FIX-KARA-PATHS.bat
)

echo.
echo PUB_CACHE user variable:
setx 2>nul
echo   (If empty, run FIX-KARA-PATHS.bat)
echo.
pause
