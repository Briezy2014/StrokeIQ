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
echo App expects: http://127.0.0.1:8080
echo.

call :RefreshPath

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
  pause
  exit /b 1
)

if /I "%SWIMIQ_SKIP_PORT_KILL%"=="1" (
  echo Skipping port kill - parent starter already cleared 8080.
) else (
  echo Clearing any old server on port 8080...
  if exist "%~dp0scripts\kill-elite-port.ps1" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\kill-elite-port.ps1"
  )
)
echo.

if not exist ".venv\Scripts\python.exe" (
  echo Creating Python venv...
  %PY% -m venv .venv
  if errorlevel 1 (
    echo [FAIL] Could not create venv.
    pause
    exit /b 1
  )
)

set "VENV_PY=%CD%\.venv\Scripts\python.exe"

call :EnsureLocalEnv
if errorlevel 2 (
  echo.
  echo [FAIL] Elite .env is missing Supabase URL/anon key.
  echo Put SUPABASE_URL and SUPABASE_ANON_KEY in swimiq\.env
  echo then run START-SWIMIQ-WITH-ELITE.bat once.
  echo.
  pause
  exit /b 2
)

REM If core packages already import, skip pip entirely (works when Wi-Fi/DNS is down).
echo Checking installed packages...
"%VENV_PY%" -c "import fastapi,uvicorn,matplotlib,cv2,numpy,httpx" >nul 2>&1
if not errorlevel 1 (
  echo [OK] Packages already installed - skipping pip online install.
  goto :AfterPip
)

echo.
echo Packages incomplete. Trying pip install from internet...
echo If Wi-Fi/DNS is down this will warn and then try to start anyway.
echo.
"%VENV_PY%" -m pip install --upgrade pip wheel
if errorlevel 1 (
  echo [WARN] pip upgrade failed offline - continuing.
)
"%VENV_PY%" -m pip install --only-binary=:all: -r requirements-windows.txt
if errorlevel 1 (
  echo.
  echo [WARN] pip install failed offline.
  echo Trying to start with whatever is already in .venv ...
  echo.
  "%VENV_PY%" -c "import fastapi,uvicorn" >nul 2>&1
  if errorlevel 1 (
    echo [FAIL] Cannot start - packages missing and pip cannot reach pypi.org.
    echo Fix Wi-Fi/DNS, then run this again.
    pause
    exit /b 1
  )
)

:AfterPip
call :CheckFfmpeg
if "!FFMPEG_OK!"=="0" (
  echo.
  echo [WARN] FFmpeg not found on PATH yet.
  echo Install with winget, then run RESTART-ELITE-AFTER-FFMPEG.bat
  echo.
)

echo.
echo Starting server on http://127.0.0.1:8080 ...
echo Leave this window open.
echo When you see "Uvicorn running on http://127.0.0.1:8080" it is ready.
echo.
start "" "http://127.0.0.1:8080/health"
"%VENV_PY%" -m uvicorn app.main:app --host 127.0.0.1 --port 8080
set "ERR=%ERRORLEVEL%"
echo.
if not "%ERR%"=="0" (
  echo [FAIL] Server exited with code %ERR%.
  echo If you saw "10048" / address already in use:
  echo   Another window already has port 8080. Close it first.
)
echo Server stopped.
pause
exit /b %ERR%

:RefreshPath
set "SYSPATH="
set "USRPATH="
for /f "skip=2 tokens=1,2*" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do (
  if /I "%%A"=="Path" set "SYSPATH=%%C"
)
for /f "skip=2 tokens=1,2*" %%A in ('reg query "HKCU\Environment" /v Path 2^>nul') do (
  if /I "%%A"=="Path" set "USRPATH=%%C"
)
if defined SYSPATH (
  if defined USRPATH (
    set "PATH=%SYSPATH%;%USRPATH%"
  ) else (
    set "PATH=%SYSPATH%"
  )
) else if defined USRPATH (
  set "PATH=%USRPATH%"
)
if exist "%LOCALAPPDATA%\Microsoft\WinGet\Links" set "PATH=%LOCALAPPDATA%\Microsoft\WinGet\Links;%PATH%"
if exist "%ProgramFiles%\ffmpeg\bin" set "PATH=%ProgramFiles%\ffmpeg\bin;%PATH%"
if exist "%ProgramFiles%\Gyan\FFmpeg\bin" set "PATH=%ProgramFiles%\Gyan\FFmpeg\bin;%PATH%"
exit /b 0

:CheckFfmpeg
set "FFMPEG_OK=0"
where ffmpeg >nul 2>&1
if errorlevel 1 goto :eof
where ffprobe >nul 2>&1
if errorlevel 1 goto :eof
set "FFMPEG_OK=1"
echo [OK] FFmpeg found:
where ffmpeg
where ffprobe
exit /b 0

:EnsureLocalEnv
set "ENSURE_PS1=%~dp0scripts\ensure-elite-local-env.ps1"
if not exist "%ENSURE_PS1%" (
  echo [WARN] Missing %ENSURE_PS1%
  if not exist ".env" (
    if exist ".env.example" copy /Y ".env.example" ".env" >nul
  )
  exit /b 0
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%ENSURE_PS1%" "%CD%"
exit /b %ERRORLEVEL%
