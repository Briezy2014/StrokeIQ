@echo off
setlocal
title FIX Elite storage download NOW
cd /d "%~dp0"

echo.
echo ============================================
echo   FIX: Elite "storage download" error
echo ============================================
echo.
echo This will:
echo   1. Update code
echo   2. Kill the OLD Elite server on port 8080
echo   3. Start a FRESH Elite server with Supabase keys
echo   4. Wait until health shows storage_download_configured:true
echo   5. Launch SwimIQ
echo.
echo Close any Elite windows if this asks you to.
echo.
pause

git fetch origin cursor/elite-video-on-dashboard-b7ef 2>nul
git checkout -f cursor/elite-video-on-dashboard-b7ef 2>nul
git reset --hard origin/cursor/elite-video-on-dashboard-b7ef 2>nul

echo.
echo Killing old Elite server...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0swimiq\scripts\kill-elite-port.ps1"

echo.
echo Starting fresh Elite + SwimIQ...
call "%~dp0START-SWIMIQ-WITH-ELITE.bat"
exit /b %ERRORLEVEL%
