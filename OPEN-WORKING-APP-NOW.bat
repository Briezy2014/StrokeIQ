@echo off
setlocal EnableExtensions
title SwimIQ WORKING APP - localhost only
cd /d "%~dp0"

echo.
echo ############################################################
echo #  WORKING APP - localhost only                           #
echo #  Close swimiqapp.com first                              #
echo ############################################################
echo.
echo This one file:
echo   1. Downloads the latest fixes from GitHub
echo   2. Checks coaching key (GEMINI_API_KEY)
echo   3. Starts Elite + Chrome on THIS PC
echo.

echo [1/3] Updating files from GitHub...
git -C "%CD%" fetch origin cursor/elite-video-on-dashboard-b7ef
if errorlevel 1 (
  echo [FAIL] git fetch failed. Check Wi-Fi.
  pause
  exit /b 1
)
git -C "%CD%" checkout -f cursor/elite-video-on-dashboard-b7ef
git -C "%CD%" reset --hard origin/cursor/elite-video-on-dashboard-b7ef
if errorlevel 1 (
  echo [FAIL] Could not update files.
  pause
  exit /b 1
)
echo [OK] Files updated.
echo.

if not exist "%CD%\swimiq\.env" (
  echo [FAIL] Missing swimiq\.env
  if exist "%CD%\swimiq\.env.example" copy /Y "%CD%\swimiq\.env.example" "%CD%\swimiq\.env" >nul
)

echo [2/3] Checking coaching key (GEMINI_API_KEY)...
set "HAS_GEMINI=0"
REM Accept Google AI Studio keys: older AIza... and newer AQ.... formats.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$p='%~dp0swimiq\.env'; if (-not (Test-Path -LiteralPath $p)) { exit 1 };" ^
  "$line=(Get-Content -LiteralPath $p | Where-Object { $_ -match '^\s*GEMINI_API_KEY\s*=' } | Select-Object -First 1);" ^
  "if (-not $line) { exit 1 };" ^
  "$v=($line -replace '^\s*GEMINI_API_KEY\s*=\s*','').Trim().Trim('\"').Trim(\"'\");" ^
  "if ([string]::IsNullOrWhiteSpace($v)) { exit 1 };" ^
  "$bad=@('paste_','your-','changeme','your_key','xxx');" ^
  "foreach ($b in $bad) { if ($v.ToLower().Contains($b)) { exit 1 } };" ^
  "if ($v.Length -lt 20) { exit 1 }; exit 0"
if not errorlevel 1 set "HAS_GEMINI=1"
if "%HAS_GEMINI%"=="0" (
  echo.
  echo [NEED KEY] Coaching tips need GEMINI_API_KEY in swimiq\.env
  echo.
  echo Notepad will open swimiq\.env
  echo Add this ONE line, then save and close Notepad:
  echo.
  echo   GEMINI_API_KEY=paste_your_key_here
  echo.
  echo Either Google AI Studio key is fine:
  echo   - "Gemini API KEY"  OR  "SwimIQ Video Analysis"
  echo Keys may start with AIza... or AQ.... — both are OK.
  echo.
  if exist "%CD%\ADD-GEMINI-KEY-FOR-COACHING.txt" start "" notepad "%CD%\ADD-GEMINI-KEY-FOR-COACHING.txt"
  start "" notepad "%CD%\swimiq\.env"
  echo After you SAVE the key in Notepad, press any key here to continue...
  pause >nul
) else (
  echo [OK] GEMINI_API_KEY found in swimiq\.env
  echo      Elite will copy it into services\video_analysis\.env on start.
)

echo [3/3] Starting Elite + Chrome localhost...
echo Address bar MUST be 127.0.0.1 or localhost - NOT swimiqapp.com
echo.
call "%CD%\FINAL-TRY-THIS-ONLY.bat"
exit /b %ERRORLEVEL%
