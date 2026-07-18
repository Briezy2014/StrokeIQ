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

REM Reload PATH from the registry so a just-installed FFmpeg is found
REM without logging out of Windows.
call :RefreshPath

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

REM If something is already serving Elite health on 8080, reuse it.
call :CheckAlreadyRunning
if "!ALREADY_RUNNING!"=="1" (
  echo.
  echo [OK] Elite analysis server is ALREADY running on port 8080.
  echo Leave the other Elite server window open.
  echo Opening http://127.0.0.1:8080/health ...
  start "" "http://127.0.0.1:8080/health"
  echo.
  echo Next: in SwimIQ tap Confirm ^& Analyze again.
  echo Do NOT start a second server.
  echo.
  pause
  exit /b 0
)

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

echo Upgrading pip/wheel...
"%VENV_PY%" -m pip install --upgrade pip wheel
if errorlevel 1 (
  echo [FAIL] pip upgrade failed.
  pause
  exit /b 1
)

call :EnsureLocalEnv

echo.
echo Installing Windows packages from prebuilt wheels only...
echo (This avoids the C-compiler / numpy build error.)
echo.
"%VENV_PY%" -m pip install --only-binary=:all: -r requirements-windows.txt
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

call :CheckFfmpeg
if "!FFMPEG_OK!"=="0" (
  echo.
  echo [WARN] FFmpeg not found on PATH yet.
  echo Install with:
  echo   winget install --id Gyan.FFmpeg -e --accept-package-agreements --accept-source-agreements
  echo Then CLOSE this window and run RESTART-ELITE-AFTER-FFMPEG.bat
  echo.
)

echo.
echo Starting server on http://127.0.0.1:8080 ...
echo Leave this window open.
echo When you see "Uvicorn running on http://127.0.0.1:8080" it is ready.
echo Then in SwimIQ tap Confirm ^& Analyze again.
echo.
REM Bind IPv4 loopback explicitly. Flutter web "localhost" can hit ::1 on Windows
REM and miss a server that only listens on IPv4.
start "" "http://127.0.0.1:8080/health"
"%VENV_PY%" -m uvicorn app.main:app --host 127.0.0.1 --port 8080
set "ERR=%ERRORLEVEL%"
echo.
if not "%ERR%"=="0" (
  echo [FAIL] Server exited with code %ERR%.
  echo If you saw "10048" / address already in use:
  echo   Another window already has port 8080. Use THAT window, or close it first.
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
where ffmpeg >nul 2>&1 && where ffprobe >nul 2>&1 && set "FFMPEG_OK=1"
if "!FFMPEG_OK!"=="1" (
  echo [OK] FFmpeg found:
  where ffmpeg
  where ffprobe
) else (
  echo [WARN] ffmpeg/ffprobe not on PATH in this window.
)
exit /b 0

:CheckAlreadyRunning
set "ALREADY_RUNNING=0"
set "HEALTH_PS1=%~dp0scripts\check-elite-health.ps1"
if exist "%HEALTH_PS1%" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%HEALTH_PS1%" >nul 2>&1
  if not errorlevel 1 set "ALREADY_RUNNING=1"
)
exit /b 0

:EnsureLocalEnv
REM Use a .ps1 file — inline PowerShell with ^ breaks on Windows (caret / Test-Path).
set "ENSURE_PS1=%~dp0scripts\ensure-elite-local-env.ps1"
if not exist "%ENSURE_PS1%" (
  echo [WARN] Missing %ENSURE_PS1%
  if not exist ".env" (
    if exist ".env.example" copy /Y ".env.example" ".env" >nul
  )
  exit /b 0
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%ENSURE_PS1%" "%CD%"
if errorlevel 1 (
  echo [WARN] Could not fully prepare .env — continuing with defaults.
)
exit /b 0
