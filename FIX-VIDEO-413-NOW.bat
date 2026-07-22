@echo off
setlocal EnableExtensions
title SwimIQ - FIX VIDEO 413 (100 MB server)
cd /d "%~dp0"

echo.
echo ============================================
echo   FIX the 25 MB video error (413)
echo   This updates the SERVER — not the website
echo ============================================
echo.
echo You still see "max ~25 MB" / 413 because the
echo Supabase function was never redeployed.
echo.
echo This script:
echo   1) Downloads the 100 MB server code from GitHub
echo   2) Deploys analyze-swim-video to Supabase
echo.
echo Need: internet + your Supabase login
echo.

set "BRANCH=cursor/dryland-power-index-b7ef"
set "PROJECT_REF=bryurwyeosbffvfpdpbv"
set "SWIMIQ=%CD%\swimiq"
if not exist "%SWIMIQ%\supabase\functions\analyze-swim-video" (
  if exist "%CD%\supabase\functions\analyze-swim-video" set "SWIMIQ=%CD%"
)

if not exist "%SWIMIQ%\supabase\functions" (
  echo [FAIL] Cannot find swimiq\supabase\functions
  echo Run this from Desktop\StrokeIQ
  pause
  exit /b 1
)

set "INDEX=%SWIMIQ%\supabase\functions\analyze-swim-video\index.ts"
set "URL=https://raw.githubusercontent.com/Briezy2014/StrokeIQ/%BRANCH%/swimiq/supabase/functions/analyze-swim-video/index.ts"

echo [1/4] Downloading 100 MB server code...
echo URL: %URL%
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "New-Item -ItemType Directory -Force -Path (Split-Path -LiteralPath '%INDEX%') | Out-Null; try { Invoke-WebRequest -Uri '%URL%' -OutFile '%INDEX%' -UseBasicParsing; exit 0 } catch { Write-Host $_.Exception.Message; exit 1 }"
if errorlevel 1 (
  echo.
  echo [FAIL] Could not download from GitHub.
  echo Open https://github.com in Chrome. If it fails, use phone hotspot.
  start "" "https://github.com"
  pause
  exit /b 1
)

findstr /C:"MAX_FILE_API_BYTES = 100" "%INDEX%" >nul 2>&1
if errorlevel 1 (
  echo [FAIL] Downloaded file does not contain 100 MB limit.
  pause
  exit /b 1
)
findstr /C:"2026-gemini-sync-v12" "%INDEX%" >nul 2>&1
if errorlevel 1 (
  echo [FAIL] Downloaded file is not sync-v12.
  pause
  exit /b 1
)
echo [OK] Local server code is 100 MB / sync-v12
echo.

echo [2/4] Supabase CLI via npx...
set "SUPABASE_CMD=npx --yes supabase"

echo [3/4] Login (browser may open)...
%SUPABASE_CMD% login
if errorlevel 1 (
  echo [FAIL] Login failed.
  pause
  exit /b 1
)

echo.
echo [4/4] Link + deploy analyze-swim-video...
pushd "%SWIMIQ%"
%SUPABASE_CMD% link --project-ref %PROJECT_REF%
if errorlevel 1 (
  echo [FAIL] Link failed. Use the Supabase account that owns SwimIQ.
  popd
  pause
  exit /b 1
)

%SUPABASE_CMD% functions deploy analyze-swim-video --project-ref %PROJECT_REF%
if errorlevel 1 (
  echo [FAIL] Deploy failed.
  echo Confirm GEMINI_API_KEY exists in Supabase Secrets.
  popd
  pause
  exit /b 1
)
popd

echo.
echo ============================================
echo   SERVER FIXED (100 MB)
echo ============================================
echo.
echo NEXT — update the WEBSITE too (kills "50 MB" + Technical error):
echo   1) GET-LATEST-FIXED-APP.bat
echo   2) PUBLISH-SWIMIQAPP-COM.bat  until BUILD + ZIP DONE
echo   3) Upload swimiq\build\swimiq-web-godaddy.zip to GoDaddy
echo.
echo Or if we sent you a ready zip, upload THAT zip only.
echo Then hard refresh: Ctrl+Shift+R
echo.
pause
exit /b 0
