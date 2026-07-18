@echo off
title Fix video upload (user_id)
cd /d "%~dp0"
echo.
echo Opening FIX-VIDEO-UPLOAD-NOW.txt ...
echo Follow the steps and paste the SQL into Supabase.
echo.
start "" notepad "%~dp0FIX-VIDEO-UPLOAD-NOW.txt"
start "" "https://supabase.com/dashboard"
echo.
echo After SQL says Success, upload your video again in SwimIQ.
echo.
pause
