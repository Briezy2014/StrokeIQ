@echo off
title Open upload SQL only
cd /d "%~dp0"
echo.
echo Opening the SQL-ONLY file (no instructions mixed in).
echo.
echo 1. Ctrl+A then Ctrl+C in Notepad
echo 2. In Supabase SQL Editor: Ctrl+A then Delete (clear old text)
echo 3. Ctrl+V then click RUN
echo.
start "" notepad "%~dp0swimiq\FIX-VIDEO-UPLOAD-SQL-ONLY.sql"
start "" "https://supabase.com/dashboard"
pause
