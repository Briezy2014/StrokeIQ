@echo off
setlocal
title SwimIQ - Download latest fixed files
cd /d "%~dp0"

echo.
echo ============================================
echo   Download latest SwimIQ fixed files
echo   Folder: %CD%
echo ============================================
echo.

if not exist ".git" goto :NoGit

echo Updating from GitHub...
git fetch origin
if errorlevel 1 goto :FetchFail

git merge --abort >nul 2>&1
git checkout -f cursor/dryland-power-index-b7ef
if errorlevel 1 goto :UpdateFail
git reset --hard origin/cursor/dryland-power-index-b7ef
if errorlevel 1 goto :UpdateFail

echo.
echo ============================================
echo   File check after update
echo ============================================
set MISSING=0

call :CheckFile "START-SWIMIQ-WITH-ELITE.bat"
call :CheckFile "GOOD-MORNING-KARA.txt"
call :CheckFile "swimiq\scripts\start-elite-and-wait.ps1"
call :CheckFile "swimiq\scripts\ensure-elite-local-env.ps1"
call :CheckFile "swimiq\scripts\fix-one-gemini-key.ps1"
call :CheckFile "swimiq\scripts\kill-elite-port.ps1"
call :CheckFile "swimiq\scripts\launch-chrome-kara.ps1"
call :CheckFile "swimiq\scripts\swimiq-windows-paths.ps1"
call :CheckFile "swimiq\START-ELITE-ANALYSIS-SERVER.bat"
call :CheckFile "swimiq\LAUNCH-CHROME.bat"
call :CheckFile "STRIPE-BILLING-STEPS.txt"
call :CheckFile "TURN-ON-STRIPE-BILLING.bat"
call :CheckFile "GET-STRIPE-BILLING.bat"
call :CheckFile "swimiq\DEPLOY-STRIPE-NOW.cmd"
call :CheckFile "swimiq\scripts\deploy-stripe-functions.mjs"

echo.
if "%MISSING%"=="1" goto :MissingFiles

echo ============================================
echo Stripe billing files are ready.
echo For billing: open STRIPE-BILLING-STEPS.txt
echo Or double-click TURN-ON-STRIPE-BILLING.bat
echo ============================================
echo.
echo NEXT: starting Elite + Chrome for you now
echo.
if exist "%CD%\STRIPE-BILLING-STEPS.txt" start "" notepad "%CD%\STRIPE-BILLING-STEPS.txt"
if exist "%CD%\GOOD-MORNING-KARA.txt" start "" notepad "%CD%\GOOD-MORNING-KARA.txt"
call "%CD%\START-SWIMIQ-WITH-ELITE.bat"
exit /b %ERRORLEVEL%

:CheckFile
if exist "%~1" (
  echo [OK] %~1
  goto :eof
)
echo [BAD] %~1
set MISSING=1
goto :eof

:NoGit
echo [FAIL] This is not the StrokeIQ git folder.
echo Open Desktop\StrokeIQ and run this file there.
pause
exit /b 1

:FetchFail
echo [FAIL] git fetch failed. Check internet / Wi-Fi.
pause
exit /b 1

:UpdateFail
echo [FAIL] Could not update files from GitHub.
pause
exit /b 1

:MissingFiles
echo [FAIL] Some files are still missing after update.
pause
exit /b 1
