@echo off
setlocal
title Open FIXED Passport (localhost only)
cd /d "%~dp0"

echo.
echo ############################################################
echo #  OPEN FIXED PASSPORT                                    #
echo #  Do NOT use swimiqapp.com                               #
echo ############################################################
echo.
echo If the address bar says swimiqapp.com, that is the OLD site.
echo The left "Athlete Passport" card is already deleted in the
echo new app. You must use localhost to see it.
echo.
echo Updating files...
git -C "%CD%" fetch origin cursor/elite-video-on-dashboard-b7ef
git -C "%CD%" checkout -f cursor/elite-video-on-dashboard-b7ef
git -C "%CD%" reset --hard origin/cursor/elite-video-on-dashboard-b7ef

echo.
echo Starting localhost SwimIQ (same as FINAL TRY)...
call "%CD%\FINAL-TRY-THIS-ONLY.bat"
exit /b %ERRORLEVEL%
