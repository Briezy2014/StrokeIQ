@echo off
title SwimIQ - Kara do video AI now (no Command Prompt)
cd /d "%~dp0"

echo.
echo ============================================================
echo   KARA - Video AI fix (double-click only - no typing)
echo ============================================================
echo.
echo Folder: %CD%
echo.
echo This file does EVERYTHING for Gemini video analysis.
echo You do NOT need Android Studio or Command Prompt.
echo.
echo ORDER:
echo   1. If you never ran FIX-KARA-PATHS.bat - run that FIRST (once).
echo   2. This file checks Node.js, then deploys Gemini to Supabase.
echo.
pause

where node >nul 2>&1
if errorlevel 1 (
  echo.
  echo ============================================================
  echo   NODE.JS NOT INSTALLED YET
  echo ============================================================
  echo.
  echo Step D from KARA-DO-THIS-NOW.txt:
  echo   1. Opening https://nodejs.org in your browser now...
  echo   2. Download the green LTS button and install.
  echo   3. RESTART YOUR COMPUTER.
  echo   4. Double-click THIS file again.
  echo.
  start https://nodejs.org
  pause
  exit /b 1
)

echo.
echo Node.js found - good.
echo.
echo Next: running KARA-GEMINI-FIX-NOW.bat ...
echo (Browser will open for Supabase login - use your SwimIQ Google account)
echo.
pause

call "%~dp0KARA-GEMINI-FIX-NOW.bat"
set ERR=%ERRORLEVEL%

echo.
if %ERR% NEQ 0 (
  echo ============================================================
  echo   DEPLOY DID NOT FINISH
  echo ============================================================
  echo.
  echo Read KARA-DO-THIS-NOW.txt - Step E troubleshooting.
  echo Check GEMINI_API_KEY in Supabase - Edge Functions - Secrets.
) else (
  echo ============================================================
  echo   NEXT: OPEN THE APP
  echo ============================================================
  echo.
  echo Double-click KARA-CLICK-THIS.bat
  echo Video tab - Test video server - then Analyze your clip.
  echo.
  set /p OPENAPP="Open SwimIQ in Chrome now? (Y/N): "
  if /i "%OPENAPP%"=="Y" (
    if exist "%~dp0KARA-CLICK-THIS.bat" (
      call "%~dp0KARA-CLICK-THIS.bat"
    ) else (
      echo Double-click KARA-CLICK-THIS.bat manually.
    )
  )
)

pause
