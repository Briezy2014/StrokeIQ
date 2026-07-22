@echo off
setlocal
title SwimIQ - Get latest + open upload zip
cd /d "%~dp0"

echo.
echo ============================================
echo   SwimIQ — get latest files
echo   Folder: %CD%
echo ============================================
echo.

REM If the upload zip is already here, skip GitHub entirely.
if exist "%CD%\UPLOAD-TO-GODADDY\swimiq-web-godaddy.zip" (
  if exist "%CD%\DOUBLE-CLICK-ME.vbs" (
    echo [OK] Website zip is already in this folder.
    echo Opening it now — NO website download needed.
    echo.
    wscript "%CD%\DOUBLE-CLICK-ME.vbs"
    exit /b 0
  )
)

if not exist ".git" goto :NoGit

echo Checking GitHub connection...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "try { $r = Invoke-WebRequest -Uri 'https://github.com' -UseBasicParsing -TimeoutSec 12; if ($r.StatusCode -ge 200 -and $r.StatusCode -lt 500) { exit 0 } else { exit 1 } } catch { exit 1 }"
if errorlevel 1 goto :NetworkFail

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

call :CheckFile "DOUBLE-CLICK-ME.vbs"
call :CheckFile "UPLOAD-TO-GODADDY\swimiq-web-godaddy.zip"
call :CheckFile "UPLOAD-TO-GODADDY\READ-ME-UPLOAD-STEPS.txt"

echo.
if "%MISSING%"=="1" goto :MissingFiles

echo ============================================
echo Latest files are ready.
echo ============================================
echo.
echo NEXT: opening DOUBLE-CLICK-ME.vbs
echo That highlights UPLOAD-TO-GODADDY\swimiq-web-godaddy.zip
echo.
if exist "%CD%\DOUBLE-CLICK-ME.vbs" (
  wscript "%CD%\DOUBLE-CLICK-ME.vbs"
  exit /b 0
)
echo Open UPLOAD-TO-GODADDY and upload swimiq-web-godaddy.zip
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

:NetworkFail
echo.
echo ============================================
echo   Cannot reach GitHub right now
echo ============================================
echo.
if exist "%CD%\UPLOAD-TO-GODADDY\swimiq-web-godaddy.zip" (
  echo But your folder ALREADY has the website zip.
  echo Opening it now — skip GitHub.
  echo.
  if exist "%CD%\DOUBLE-CLICK-ME.vbs" (
    wscript "%CD%\DOUBLE-CLICK-ME.vbs"
    exit /b 0
  )
  explorer.exe "%CD%\UPLOAD-TO-GODADDY"
  exit /b 0
)
echo.
echo No local zip found yet. Use phone hotspot, then run again.
echo Or open UPLOAD-TO-GODADDY if the zip is already there.
echo.
if exist "%CD%\UPLOAD-TO-GODADDY" explorer.exe "%CD%\UPLOAD-TO-GODADDY"
pause
exit /b 1

:FetchFail
echo [FAIL] git fetch failed.
if exist "%CD%\UPLOAD-TO-GODADDY\swimiq-web-godaddy.zip" (
  echo Using the zip already in UPLOAD-TO-GODADDY...
  if exist "%CD%\DOUBLE-CLICK-ME.vbs" wscript "%CD%\DOUBLE-CLICK-ME.vbs"
  exit /b 0
)
pause
exit /b 1

:UpdateFail
echo [FAIL] Could not update files from GitHub.
if exist "%CD%\UPLOAD-TO-GODADDY\swimiq-web-godaddy.zip" (
  echo Using the zip already in UPLOAD-TO-GODADDY...
  if exist "%CD%\DOUBLE-CLICK-ME.vbs" wscript "%CD%\DOUBLE-CLICK-ME.vbs"
  exit /b 0
)
pause
exit /b 1

:MissingFiles
echo [FAIL] Some files are still missing after update.
if exist "%CD%\UPLOAD-TO-GODADDY" explorer.exe "%CD%\UPLOAD-TO-GODADDY"
pause
exit /b 1
