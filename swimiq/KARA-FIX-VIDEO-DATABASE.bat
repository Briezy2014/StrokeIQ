@echo off
title SwimIQ - Fix video database tables
cd /d "%~dp0"
echo.
echo ============================================================
echo   FIX VIDEO DELETE + AI ANALYSIS DATABASE
echo ============================================================
echo.
echo Your Supabase project is missing swim_video_analyses table.
echo That breaks Delete video and saving AI results.
echo.
echo DO THIS ONCE (website, 2 minutes):
echo.
echo   1. Open https://supabase.com/dashboard
echo   2. Your SwimIQ project
echo   3. SQL Editor (left menu)
echo   4. New query
echo   5. Open this file in Notepad and copy ALL of it:
echo        supabase\fix_video_tables.sql
echo   6. Paste into SQL Editor
echo   7. Click RUN
echo   8. Should say Success
echo.
echo THEN on your PC:
echo   9. KARA-SEE-UPDATES-NOW.bat
echo  10. KARA-GEMINI-FIX-NOW.bat  (deploys streaming video server)
echo  11. Video tab - Delete or Analyze again
echo.
echo Opening fix_video_tables.sql in Notepad...
start notepad "%~dp0supabase\fix_video_tables.sql"
echo.
pause
