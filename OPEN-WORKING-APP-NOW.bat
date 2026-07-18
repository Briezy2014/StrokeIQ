@echo off
REM Same as START-SWIMIQ-WITH-ELITE.bat (kept as an older alias name).
cd /d "%~dp0"
if exist "%CD%\START-SWIMIQ-WITH-ELITE.bat" (
  call "%CD%\START-SWIMIQ-WITH-ELITE.bat"
  exit /b %ERRORLEVEL%
)
echo [FAIL] START-SWIMIQ-WITH-ELITE.bat is missing.
echo Run GET-LATEST-FIXED-APP.bat first.
pause
exit /b 1
