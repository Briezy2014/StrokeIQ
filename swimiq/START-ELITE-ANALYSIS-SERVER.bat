@echo off
setlocal EnableDelayedExpansion
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

REM Prefer Python 3.11 / 3.12 (have numpy wheels). Fall back to "python".
set "PY=python"
where py >nul 2>&1
if not errorlevel 1 (
  py -3.11 -c "import sys" >nul 2>&1 && set "PY=py -3.11"
  if "!PY!"=="python" py -3.12 -c "import sys" >nul 2>&1 && set "PY=py -3.12"
)

echo Using: %PY%
%PY% --version
if errorlevel 1 (
  echo [FAIL] Python not found.
  echo Install Python 3.11 from https://www.python.org/downloads/
  echo Check "Add python.exe to PATH", then run this again.
  pause
  exit /b 1
)

if not exist ".venv\Scripts\activate.bat" (
  echo Creating Python venv...
  %PY% -m venv .venv
  if errorlevel 1 (
    echo [FAIL] Could not create venv.
    pause
    exit /b 1
  )
)

call .venv\Scripts\activate.bat

echo Upgrading pip/wheel...
python -m pip install --upgrade pip wheel
if errorlevel 1 (
  echo [FAIL] pip upgrade failed.
  pause
  exit /b 1
)

if not exist ".env" (
  if exist ".env.example" copy /Y ".env.example" ".env" >nul
  echo.
  echo Created services\video_analysis\.env — fill Supabase keys, then save.
  echo Set SUPABASE_AUTH_REQUIRED=true
  notepad ".env"
)

echo.
echo Installing Windows packages from prebuilt wheels only...
echo (This avoids the C-compiler / numpy build error.)
echo.
python -m pip install --only-binary=:all: -r requirements-windows.txt
if errorlevel 1 (
  echo.
  echo [FAIL] Wheel install failed.
  echo Your Python version may be too new. Install Python 3.11, then:
  echo   1. Delete folder: services\video_analysis\.venv
  echo   2. Run this bat again
  echo.
  pause
  exit /b 1
)

echo.
echo Starting server on port 8080...
echo Leave this window open.
echo When you see "Uvicorn running on http://0.0.0.0:8080" it is ready.
echo Then in SwimIQ tap Confirm ^& Analyze again.
echo.
python -m uvicorn app.main:app --host 0.0.0.0 --port 8080
echo.
echo Server stopped.
pause
