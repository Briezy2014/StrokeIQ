@echo off
title SwimIQ START HERE
echo.
echo ========================================
echo  SwimIQ - START HERE
echo ========================================
echo.
echo Use THIS folder only (swimiq). Same files also exist
echo in the parent StrokeIQ folder — pick one, not both.
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
echo When Step 1 says OK, press any key here to launch Chrome...
pause >nul
call "%~dp0KARA-CLICK-THIS.bat"
