@echo off
title SwimIQ START HERE
echo.
echo ========================================
echo  SwimIQ - START HERE
echo ========================================
echo.
echo Use THIS folder only (swimiq).
echo.
echo ----------------------------------------
echo  STEP 1 of 2 — Fix paths (run ONCE)
echo ----------------------------------------
echo.
pause
call "%~dp0FIX-KARA-PATHS.bat"
echo.
echo ----------------------------------------
echo  STEP 2 of 2 — Open SwimIQ in Chrome
echo ----------------------------------------
echo.
echo When Step 1 says OK, press any key to launch Chrome...
echo (Uses LAUNCH-CHROME, SWIMIQ-CHROME-NOW, or KARA-CLICK-THIS)
pause >nul
if exist "%~dp0LAUNCH-CHROME.bat" (call "%~dp0LAUNCH-CHROME.bat" & exit /b %ERRORLEVEL%)
if exist "%~dp0SWIMIQ-CHROME-NOW.bat" (call "%~dp0SWIMIQ-CHROME-NOW.bat" & exit /b %ERRORLEVEL%)
call "%~dp0KARA-CLICK-THIS.bat"
