@echo off
REM Maps drive S: to this StrokeIQ folder so Flutter tools are not confused by
REM spaces in "C:\Users\Kara Williams\..."
cd /d "%~dp0..\.."
set "ROOT=%CD%"
subst S: "%ROOT%"
echo.
echo Created shortcut drive:
echo   S:  --^>  %ROOT%
echo.
echo NEXT — open a NEW PowerShell window and run:
echo   S:
echo   cd swimiq
echo   run-chrome.bat
echo.
pause
