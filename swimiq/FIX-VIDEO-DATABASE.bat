@echo off
title SwimIQ - Fix video database
cd /d "%~dp0"
echo.
echo ============================================================
echo   FIX VIDEO DELETE + AI ANALYSIS DATABASE
echo ============================================================
echo.
echo Your Supabase project is missing swim_video_analyses table.
echo That breaks Delete video and saving AI results.
echo.
echo DO THIS ONCE on the Supabase website (2 minutes):
echo.
echo   1. Open https://supabase.com/dashboard
echo   2. Your SwimIQ project
echo   3. SQL Editor (left menu)
echo   4. New query
echo   5. Copy ALL text from the file that opens in Notepad
echo   6. Paste into SQL Editor
echo   7. Click RUN
echo   8. Should say Success
echo.
echo THEN on your PC:
echo   9. KARA-GEMINI-FIX-NOW.bat  (deploys streaming video server)
echo  10. Video tab - Delete or Analyze again
echo.

set "SQLFILE=%~dp0supabase\fix_video_tables.sql"
set "PASTEFILE=%~dp0KARA-PASTE-THIS-IN-SUPABASE.txt"

if exist "%PASTEFILE%" (
  echo Opening KARA-PASTE-THIS-IN-SUPABASE.txt in Notepad...
  echo (Copy everything from ---- START SQL ---- through ---- END SQL ----)
  start notepad "%PASTEFILE%"
) else if exist "%SQLFILE%" (
  echo Opening fix_video_tables.sql in Notepad...
  start notepad "%SQLFILE%"
) else (
  echo.
  echo [ERROR] SQL file not found on this PC.
  echo.
  echo Double-click RESTORE-SCRIPTS.bat  OR  KARA-SEE-UPDATES-NOW.bat
  echo to download the fix files from GitHub, then run this again.
  echo.
  start https://supabase.com/dashboard/project/bryurwyeosbffvfpdpbv/sql/new
)

echo.
pause
