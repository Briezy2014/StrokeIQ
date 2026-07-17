@echo off
REM Double-click this file OR run: .\START-SWIMIQ.bat
REM It launches PowerShell with script permission bypass, validates .env,
REM then starts Flutter Chrome with Supabase keys via --dart-define.
cd /d "%~dp0"
echo.
echo Starting SwimIQ via PowerShell launcher...
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0start_swimiq.ps1"
echo.
echo Launcher finished. If you saw the gray gear, scroll up for [FAIL] lines.
pause
