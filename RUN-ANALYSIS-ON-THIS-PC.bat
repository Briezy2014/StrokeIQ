@echo off
setlocal
title Run Elite analysis on THIS PC
cd /d "%~dp0"

echo.
echo ############################################################
echo #  Run analysis on THIS computer (not swimiqapp.com)      #
echo ############################################################
echo.
echo swimiqapp.com is still showing an OLD message until the new
echo website zip is uploaded. To test analysis RIGHT NOW:
echo.
echo   1. This will start Elite + Chrome on localhost
echo   2. Sign in
echo   3. Open Elite tab
echo   4. Click Run Elite Analysis
echo.
echo Close any swimiqapp.com tabs first.
echo.
pause

git -C "%CD%" fetch origin cursor/elite-video-on-dashboard-b7ef >nul 2>&1
git -C "%CD%" checkout -f cursor/elite-video-on-dashboard-b7ef >nul 2>&1
git -C "%CD%" reset --hard origin/cursor/elite-video-on-dashboard-b7ef >nul 2>&1

call "%~dp0START-SWIMIQ-WITH-ELITE.bat"
exit /b %ERRORLEVEL%
