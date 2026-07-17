@echo off
setlocal EnableDelayedExpansion
cd /d "%~dp0"

echo.
echo ============================================
echo   SwimIQ Chrome launcher (Windows)
echo   Folder: %CD%
echo ============================================
echo.

if not exist ".env" (
  echo [FAIL] No .env file in this folder.
  echo.
  echo Fix: run make-env.bat, paste your real Supabase URL + anon key,
  echo save the file as .env, then run START-SWIMIQ.bat again.
  echo.
  pause
  exit /b 1
)

echo [OK] Found .env
echo.

set "URL="
set "KEY="
set "V2="
for /f "usebackq tokens=1,* delims== eol=#" %%A in (".env") do (
  set "K=%%A"
  set "V=%%B"
  for /f "tokens=* delims= " %%X in ("!K!") do set "K=%%X"
  if /I "!K!"=="SUPABASE_URL" set "URL=!V!"
  if /I "!K!"=="SUPABASE_ANON_KEY" set "KEY=!V!"
  if /I "!K!"=="VIDEO_ENGINE_V2" set "V2=!V!"
)

echo SUPABASE_URL=%URL%
if defined KEY (
  echo SUPABASE_ANON_KEY=(hidden, length !KEY:~0,1!... loaded)
) else (
  echo SUPABASE_ANON_KEY=(missing)
)
echo VIDEO_ENGINE_V2=%V2%
echo.

if "%URL%"=="" (
  echo [FAIL] SUPABASE_URL is empty in .env
  pause
  exit /b 1
)
echo %URL% | findstr /I /C:"your-project" >nul && (
  echo [FAIL] SUPABASE_URL is still the placeholder. Put your real project URL.
  pause
  exit /b 1
)
echo %URL% | findstr /I /C:"https://https" >nul && (
  echo [FAIL] SUPABASE_URL has a double https. Fix it to one https://...
  pause
  exit /b 1
)
if "%KEY%"=="" (
  echo [FAIL] SUPABASE_ANON_KEY is empty in .env
  pause
  exit /b 1
)
echo %KEY% | findstr /I /C:"your-supabase-anon-key" >nul && (
  echo [FAIL] SUPABASE_ANON_KEY is still the placeholder.
  pause
  exit /b 1
)

echo [OK] .env looks usable
echo.
echo Installing packages then launching Chrome...
echo This can take a few minutes. Leave this window open.
echo.

flutter pub get
if errorlevel 1 (
  echo [FAIL] flutter pub get failed
  pause
  exit /b 1
)

echo.
echo [OK] Dependencies ready. Starting Chrome now...
echo.

flutter run -d chrome --dart-define=SUPABASE_URL=%URL% --dart-define=SUPABASE_ANON_KEY=%KEY% --dart-define=VIDEO_ENGINE_V2=true --dart-define=ANALYSIS_API_BASE_URL=http://localhost:8080

echo.
echo If you still saw the gray gear, photo the lines above starting at SUPABASE_URL=
pause
