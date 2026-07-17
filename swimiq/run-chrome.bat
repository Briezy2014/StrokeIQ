@echo off
REM SwimIQ — launch Flutter web in Chrome (Windows)
REM Passes .env values as --dart-define so Chrome always gets Supabase keys
REM even if asset bundling fails.
cd /d "%~dp0"
setlocal EnableDelayedExpansion

echo.
echo SwimIQ Flutter web launcher
echo Folder: %CD%
echo.

if not exist ".env" (
  echo ERROR: swimiq\.env is missing.
  echo Copy .env.example to .env and add SUPABASE_URL + SUPABASE_ANON_KEY.
  echo.
  pause
  exit /b 1
)

set "DEFINES="
for /f "usebackq tokens=1,* delims== eol=#" %%A in (".env") do (
  set "KEY=%%A"
  set "VAL=%%B"
  if not "!KEY!"=="" if not "!KEY:~0,1!"=="#" (
    rem trim spaces around key
    for /f "tokens=* delims= " %%K in ("!KEY!") do set "KEY=%%K"
    if not "!KEY!"=="" (
      set "DEFINES=!DEFINES! --dart-define=!KEY!=!VAL!"
    )
  )
)

flutter pub get
if errorlevel 1 (
  echo.
  echo pub get failed. If your Windows username has a space ^(e.g. Kara Williams^),
  echo run scripts\setup-short-path.bat first, then use drive S:
  echo See docs\WINDOWS_SETUP.md
  pause
  exit /b 1
)

echo.
echo Launching Chrome with .env dart-defines...
echo.
flutter run -d chrome !DEFINES!
if errorlevel 1 pause
