@echo off
cd /d "%~dp0"
setlocal

echo.
echo Creating/opening swimiq\.env ...
echo.

if exist ".env" (
  echo [OK] .env already exists.
  goto edit
)

if exist "..\..\StrokeIQ\swimiq\.env" (
  copy /Y "..\..\StrokeIQ\swimiq\.env" ".env" >nul
  echo [OK] Copied .env from Desktop\StrokeIQ\swimiq
  goto edit
)

if not exist ".env.example" (
  echo [FAIL] .env.example missing
  pause
  exit /b 1
)

copy /Y ".env.example" ".env" >nul
echo [OK] Created .env from .env.example

:edit
echo.
echo Notepad will open. Make sure these are REAL values:
echo   SUPABASE_URL=https://YOURPROJECT.supabase.co
echo   SUPABASE_ANON_KEY=eyJ...   ^(anon public key from Supabase API settings^)
echo   VIDEO_ENGINE_V2=true
echo.
echo Save, close Notepad, then double-click START-SWIMIQ.bat
echo.
notepad ".env"
echo.
pause
