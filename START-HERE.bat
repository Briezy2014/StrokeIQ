@echo off
title SwimIQ START HERE
echo.
echo ========================================
echo  SwimIQ - START HERE
echo ========================================
echo.
echo You only need ONE folder — use either:
echo   StrokeIQ folder  (this window)
echo   OR  StrokeIQ\swimiq folder
echo Do NOT run both copies at the same time.
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
