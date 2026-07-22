@echo off
setlocal
title FIX Elite storage download NOW
cd /d "%~dp0"

echo.
echo ============================================
echo   FIX: Elite storage download error
echo ============================================
echo.
echo This will:
echo   1. Update code from GitHub
echo   2. Kill the OLD Elite server on port 8080
echo   3. Start a FRESH Elite server with Supabase keys
echo   4. Wait until health shows storage_download_configured:true
echo   5. Launch SwimIQ
echo.
pause

git fetch origin cursor/elite-video-on-dashboard-b7ef 2>nul
git checkout -f cursor/elite-video-on-dashboard-b7ef 2>nul
git reset --hard origin/cursor/elite-video-on-dashboard-b7ef 2>nul

echo.
echo Killing old Elite server...
if exist "%~dp0swimiq\scripts\kill-elite-port.ps1" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0swimiq\scripts\kill-elite-port.ps1"
) else (
  echo [WARN] kill-elite-port.ps1 missing - close Elite windows manually.
)

echo.
echo Starting fresh Elite + SwimIQ...
call "%~dp0START-SWIMIQ-WITH-ELITE.bat"
exit /b %ERRORLEVEL%
