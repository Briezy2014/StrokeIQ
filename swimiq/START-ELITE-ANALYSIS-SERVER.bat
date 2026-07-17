@echo off
title Elite Video Lab - Analysis Server
cd /d "%~dp0..\services\video_analysis"

echo.
echo ============================================
echo   Elite Video Lab analysis server
echo ============================================
echo.
echo This window must stay OPEN while you analyze videos.
echo App expects: http://localhost:8080
echo.

if not exist ".venv\Scripts\activate.bat" (
  echo Creating Python venv...
  python -m venv .venv
  if errorlevel 1 (
    echo [FAIL] Python not found. Install Python 3, then run this again.
    pause
    exit /b 1
  )
)

call .venv\Scripts\activate.bat
if not exist ".env" (
  if exist ".env.example" copy /Y ".env.example" ".env" >nul
  echo.
  echo Created services\video_analysis\.env
  echo Edit it with SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY,
  echo set SUPABASE_AUTH_REQUIRED=true and POSE_ENABLED=true, then save.
  notepad ".env"
)

echo Installing / updating Python packages (first run can take a while)...
python -m pip install -q -r requirements.txt
if errorlevel 1 (
  echo [FAIL] pip install failed.
  pause
  exit /b 1
)

echo.
echo Starting server on port 8080...
echo Leave this window open. In the other window run LAUNCH-CHROME.bat
echo.
uvicorn app.main:app --host 0.0.0.0 --port 8080
pause
