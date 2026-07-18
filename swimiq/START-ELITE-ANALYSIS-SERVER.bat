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
  echo Opening http://localhost:8080/health ...
  start "" "http://localhost:8080/health"
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
  echo Then CLOSE this window and run this bat again.
  echo Health will show degraded until FFmpeg is available.
  echo.
)

echo.
echo Starting server on port 8080...
echo Leave this window open.
echo When you see "Uvicorn running on http://0.0.0.0:8080" it is ready.
echo Then in SwimIQ tap Confirm ^& Analyze again.
echo.
start "" "http://localhost:8080/health"
"%VENV_PY%" -m uvicorn app.main:app --host 0.0.0.0 --port 8080
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
REM Common WinGet / Gyan FFmpeg locations
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
powershell -NoProfile -Command "try { $r = Invoke-WebRequest -UseBasicParsing -Uri 'http://127.0.0.1:8080/health' -TimeoutSec 2; if ($r.StatusCode -eq 200 -and $r.Content -match 'engine_version') { exit 0 } else { exit 1 } } catch { exit 1 }" >nul 2>&1
if not errorlevel 1 set "ALREADY_RUNNING=1"
exit /b 0

:EnsureLocalEnv
if not exist ".env" (
  if exist ".env.example" copy /Y ".env.example" ".env" >nul
  echo Created services\video_analysis\.env
)

REM Force local Windows defaults that unblock Flutter → API.
powershell -NoProfile -Command ^
  "$envFile = '.env'; ^
  if (-not (Test-Path -LiteralPath $envFile)) { exit 0 }; ^
  $flutterEnv = Join-Path (Split-Path (Split-Path $PWD -Parent) -Parent) 'swimiq\.env'; ^
  if (-not (Test-Path -LiteralPath $flutterEnv)) { $flutterEnv = Join-Path (Split-Path $PWD -Parent) '..\swimiq\.env' }; ^
  $map = @{}; ^
  Get-Content -LiteralPath $envFile | ForEach-Object { if ($_ -match '^\s*([A-Za-z0-9_]+)\s*=\s*(.*)$') { $map[$matches[1]] = $matches[2] } }; ^
  if (Test-Path -LiteralPath $flutterEnv) { ^
    Get-Content -LiteralPath $flutterEnv | ForEach-Object { ^
      if ($_ -match '^\s*SUPABASE_URL\s*=\s*(.+)\s*$') { $map['SUPABASE_URL'] = $matches[1].Trim() } ^
      if ($_ -match '^\s*SUPABASE_ANON_KEY\s*=\s*(.+)\s*$') { $map['SUPABASE_ANON_KEY'] = $matches[1].Trim() } ^
    } ^
  }; ^
  $map['ENGINE_VERSION'] = 'elite-0.9.0'; ^
  $map['SUPABASE_AUTH_REQUIRED'] = 'false'; ^
  $map['CORS_ALLOW_ORIGINS'] = '*'; ^
  $map['VIDEO_ENGINE_NAME'] = 'video_engine_v2'; ^
  if (-not $map.ContainsKey('FFMPEG_PATH') -or [string]::IsNullOrWhiteSpace($map['FFMPEG_PATH'])) { $map['FFMPEG_PATH'] = 'ffmpeg' }; ^
  if (-not $map.ContainsKey('FFPROBE_PATH') -or [string]::IsNullOrWhiteSpace($map['FFPROBE_PATH'])) { $map['FFPROBE_PATH'] = 'ffprobe' }; ^
  $lines = @(); ^
  foreach ($k in ($map.Keys | Sort-Object)) { $lines += ($k + '=' + $map[$k]) }; ^
  Set-Content -LiteralPath $envFile -Value $lines -Encoding ascii; ^
  Write-Host '[OK] Local analysis .env ready (auth off for Windows desktop).' -ForegroundColor Green"
exit /b 0
