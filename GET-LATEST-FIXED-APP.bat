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

call :CheckFile "WHY-NOTHING-CHANGES.txt"
call :CheckFile "FIX-NETWORK-NOW.bat"
call :CheckFile "FIX-VIDEO-413-NOW.bat"
call :CheckFile "KARA-GEMINI-FIX-NOW.bat"
call :CheckFile "swimiq\KARA-GEMINI-FIX-NOW.bat"
call :CheckFile "PUBLISH-SWIMIQAPP-COM.bat"
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
echo Latest files are ready.
echo ============================================
echo.
echo READ THIS FIRST:
echo   WHY-NOTHING-CHANGES.txt
echo.
echo To update the WEBSITE:
echo   1) Make sure https://pub.dev opens in Chrome
echo   2) Double-click PUBLISH-SWIMIQAPP-COM.bat
echo   3) Wait for BUILD + ZIP DONE
echo   4) Upload swimiq\build\swimiq-web-godaddy.zip
echo   5) Run KARA-GEMINI-FIX-NOW.bat in Desktop\StrokeIQ
echo      (raises video limit to 100 MB)
echo.
if exist "%CD%\WHY-NOTHING-CHANGES.txt" start "" notepad "%CD%\WHY-NOTHING-CHANGES.txt"
if exist "%CD%\MORNING-CHECKLIST.txt" start "" notepad "%CD%\MORNING-CHECKLIST.txt"
echo.
echo To open the local Elite app afterward, run START-SWIMIQ-WITH-ELITE.bat
echo.
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
echo   BLOCKED: cannot reach GitHub
echo ============================================
echo.
echo This is why Power Index / 100 MB video / Dryland
echo never show up on swimiqapp.com — your PC cannot
echo download the new files.
echo.
echo FIX NOW (pick one):
echo   1) Phone hotspot — fastest
echo      iPhone: Settings - Personal Hotspot - ON
echo      Connect this PC to that Wi-Fi, then re-run this.
echo   2) Open Chrome and try BOTH:
echo        https://github.com
echo        https://pub.dev
echo      Both must load. If either fails, stay on hotspot.
echo   3) Turn OFF VPN / school or work proxy if on.
echo.
echo Opening those sites now...
start "" "https://github.com"
start "" "https://pub.dev"
if exist "%CD%\FIX-NETWORK-NOW.bat" (
  echo.
  echo Or run: FIX-NETWORK-NOW.bat
)
echo.
pause
exit /b 1

:FetchFail
echo.
echo [FAIL] git fetch failed — same as GitHub blocked.
echo Run FIX-NETWORK-NOW.bat or use a phone hotspot, then try again.
echo.
start "" "https://github.com"
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
