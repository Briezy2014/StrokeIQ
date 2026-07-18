@echo off
setlocal
title Fix coaching report
cd /d "%~dp0"

echo.
echo ############################################################
echo #  Fix coaching report (pros / tips / drills)             #
echo ############################################################
echo.
echo Updating files...
git -C "%CD%" fetch origin cursor/elite-video-on-dashboard-b7ef
git -C "%CD%" checkout -f cursor/elite-video-on-dashboard-b7ef
git -C "%CD%" reset --hard origin/cursor/elite-video-on-dashboard-b7ef

echo.
echo Opening coaching key instructions...
start "" notepad "%CD%\ADD-GEMINI-KEY-FOR-COACHING.txt"

echo.
echo After you save GEMINI_API_KEY in swimiq\.env:
echo   1) Close every Elite black window
echo   2) Run OPEN-WORKING-APP-NOW.bat
echo   3) Elite tab - analyze again
echo   4) Open Coaching tab
echo.
pause
exit /b 0
