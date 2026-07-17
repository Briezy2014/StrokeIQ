@echo off
REM Creates swimiq\.env from .env.example if missing, then opens Notepad to edit it.
cd /d "%~dp0"

if exist ".env" (
  echo .env already exists:
  echo   %CD%\.env
  echo.
  echo Opening it in Notepad so you can check SUPABASE_URL and SUPABASE_ANON_KEY...
  notepad ".env"
  goto done
)

if not exist ".env.example" (
  echo ERROR: .env.example is missing in %CD%
  pause
  exit /b 1
)

copy /Y ".env.example" ".env" >nul
echo Created: %CD%\.env
echo.
echo Notepad will open. Replace these two lines with your real Supabase values:
echo   SUPABASE_URL=https://xxxx.supabase.co
echo   SUPABASE_ANON_KEY=eyJ...
echo.
echo Also set:
echo   VIDEO_ENGINE_V2=true
echo.
echo Save and close Notepad, then run run-chrome.bat
echo.
notepad ".env"

:done
echo.
pause
