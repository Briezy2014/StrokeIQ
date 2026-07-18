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
git checkout -f cursor/elite-video-on-dashboard-b7ef
if errorlevel 1 goto :UpdateFail
git reset --hard origin/cursor/elite-video-on-dashboard-b7ef
if errorlevel 1 goto :UpdateFail

echo.
echo ============================================
echo   File check after update
echo ============================================
set MISSING=0

call :CheckFile "CLICK-ME-FIRST.bat"
call :CheckFile "FIX-STORAGE.bat"
call :CheckFile "FIX-ELITE-STORAGE-NOW.bat"
call :CheckFile "PUBLISH-SWIMIQAPP-COM.bat"
call :CheckFile "START-SWIMIQ-WITH-ELITE.bat"
call :CheckFile "swimiq\scripts\zip-web-godaddy.ps1"
call :CheckFile "swimiq\scripts\kill-elite-port.ps1"

echo.
if "%MISSING%"=="1" goto :MissingFiles

echo ============================================
echo NEXT for analysis (ONE path only):
echo.
echo   Double-click   FINAL-TRY-THIS-ONLY.bat
echo.
echo   Read steps in   FINAL-TRY-THIS-ONLY.txt
echo.
echo Do NOT use swimiqapp.com for this try.
echo ============================================
echo.
echo Opening this folder...
explorer.exe "%CD%"
if exist "%CD%\FINAL-TRY-THIS-ONLY.txt" start "" notepad "%CD%\FINAL-TRY-THIS-ONLY.txt"
pause
exit /b 0

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
echo If Wi-Fi is OK, try again in 1 minute.
echo You can still use FIX-STORAGE.bat if it is already in this folder.
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
