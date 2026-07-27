@echo off
REM One path for Kara: keystore (if needed) → validate .env → signed AAB
setlocal
cd /d "%~dp0"

echo.
echo ========================================
echo  SwimIQ PLAY LAUNCH NOW
echo ========================================
echo.

if not exist "android\keystore\swimiq-upload.jks" (
  echo [1/3] Creating upload keystore...
  powershell -ExecutionPolicy Bypass -File "%~dp0GENERATE-ANDROID-KEYSTORE.ps1"
  if errorlevel 1 exit /b 1
) else (
  echo [1/3] Keystore already exists — OK
)

if not exist "android\key.properties" (
  echo ERROR: android\key.properties missing after keystore step.
  echo Re-run GENERATE-ANDROID-KEYSTORE.bat
  pause
  exit /b 1
)

echo [2/3] Checking .env for real Supabase keys...
findstr /C:"your-project.supabase.co" ".env" >nul 2>&1
if not errorlevel 1 (
  echo.
  echo ERROR: .env still has placeholder SUPABASE_URL.
  echo Open FIX-ENV-FOR-PLAY.txt and paste real keys, then run this again.
  start notepad "%~dp0FIX-ENV-FOR-PLAY.txt"
  pause
  exit /b 1
)
findstr /C:"your-supabase-anon-key" ".env" >nul 2>&1
if not errorlevel 1 (
  echo.
  echo ERROR: .env still has placeholder SUPABASE_ANON_KEY.
  echo Open FIX-ENV-FOR-PLAY.txt and paste real keys, then run this again.
  start notepad "%~dp0FIX-ENV-FOR-PLAY.txt"
  pause
  exit /b 1
)

echo [3/3] Building signed Google Play AAB...
powershell -ExecutionPolicy Bypass -File "%~dp0SWIMIQ-BUILD-AAB-NOW.ps1"
if errorlevel 1 exit /b 1

echo.
echo Next: upload build\app\outputs\bundle\release\app-release.aab
echo to Play Console → Testing → Internal testing
echo See PLAY-CONSOLE-FILL-THIS.txt for listing / Data safety text.
pause
