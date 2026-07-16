@echo off
title SwimIQ Restore Scripts
cd /d "%~dp0"
echo.
echo Restoring scripts folder from GitHub...
echo (Run this FIRST if KARA-SEE-UPDATES-NOW says merge / overwrite errors)
echo.
git fetch origin cursor/dashboard-rope-schedule-fix-17e8
if errorlevel 1 goto fetchfail
for /f "delims=" %%i in ('git rev-parse --show-toplevel 2^>nul') do set "GITROOT=%%i"
if exist "%GITROOT%\swimiq\supabase" (
  set "GPREFIX=swimiq/"
) else (
  set "GPREFIX="
)
git checkout origin/cursor/dashboard-rope-schedule-fix-17e8 -- %GPREFIX%scripts/
git checkout origin/cursor/dashboard-rope-schedule-fix-17e8 -- %GPREFIX%supabase/functions/analyze-swim-video/
git checkout origin/cursor/dashboard-rope-schedule-fix-17e8 -- %GPREFIX%supabase/fix_video_tables.sql
goto restored
:fetchfail
echo git fetch failed — if RESTORE fails, run FIX-GIT-PULL.bat first.
:restored
git checkout origin/cursor/dashboard-rope-schedule-fix-17e8 -- %GPREFIX%SWIMIQ-CHROME-NOW.ps1 %GPREFIX%SWIMIQ-CHROME-NOW.bat %GPREFIX%SWIMIQ-BUILD-GODADDY-NOW.ps1 %GPREFIX%SWIMIQ-BUILD-GODADDY-NOW.bat %GPREFIX%SWIMIQ-BUILD-ANDROID-NOW.ps1 %GPREFIX%SWIMIQ-BUILD-ANDROID-NOW.bat %GPREFIX%START-HERE.bat %GPREFIX%KARA-CLICK-THIS.bat %GPREFIX%KARA-SEE-UPDATES-NOW.bat %GPREFIX%LAUNCH-CHROME.bat %GPREFIX%FIX-KARA-PATHS.bat %GPREFIX%FIX-GIT-PULL.bat %GPREFIX%DIAGNOSE.bat %GPREFIX%TEST-OWNER-LOGIN.bat %GPREFIX%SYNC-LOGO-NOW.bat %GPREFIX%restore-scripts.ps1 %GPREFIX%COPY-LOGO.bat %GPREFIX%DRAG-LOGO-HERE.bat %GPREFIX%ZIP-GODADDY-UPLOAD.bat %GPREFIX%ACTIVE_BRANCH.txt 2>nul
git checkout origin/cursor/dashboard-rope-schedule-fix-17e8 -- %GPREFIX%FIX-VIDEO-DATABASE.bat %GPREFIX%KARA-FIX-VIDEO-DATABASE.bat %GPREFIX%KARA-PASTE-THIS-IN-SUPABASE.txt %GPREFIX%KARA-FIX-STEP-A.bat 2>nul
git checkout origin/cursor/dashboard-rope-schedule-fix-17e8 -- %GPREFIX%KARA-GEMINI-FIX-NOW.bat %GPREFIX%KARA-DO-VIDEO-AI-NOW.bat %GPREFIX%KARA-WHY-GEMINI-FAILS.bat %GPREFIX%KARA-INSTALL-SUPABASE.bat 2>nul
git checkout origin/cursor/dashboard-rope-schedule-fix-17e8 -- KARA-GEMINI-FIX-NOW.bat KARA-DO-VIDEO-AI-NOW.bat KARA-WHY-GEMINI-FAILS.bat KARA-INSTALL-SUPABASE.bat 2>nul
git checkout origin/cursor/dashboard-rope-schedule-fix-17e8 -- KARA-DO-THIS-NOW.txt KARA-VIDEO-AI-FIX.txt KARA-FIX-GEMINI-QUOTA.txt

call "%~dp0scripts\ensure-video-db-fix.cmd" 2>nul
if not exist "%~dp0FIX-VIDEO-DATABASE.bat" (
  if exist "%~dp0scripts\ensure-video-db-fix.ps1" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\ensure-video-db-fix.ps1" -SwimIqRoot "%~dp0"
  )
)

call "%~dp0scripts\ensure-logo-bats.cmd" 2>nul
if not exist "%~dp0COPY-LOGO.bat" (
  echo.
  echo Writing COPY-LOGO.bat locally...
  call :WriteCopyLogoBat
)
if not exist "%~dp0DRAG-LOGO-HERE.bat" (
  copy /Y "%~dp0COPY-LOGO.bat" "%~dp0DRAG-LOGO-HERE.bat" >nul
)

echo.
echo DONE. Restored scripts and logo helpers.
if exist COPY-LOGO.bat echo   [OK] COPY-LOGO.bat
if exist DRAG-LOGO-HERE.bat echo   [OK] DRAG-LOGO-HERE.bat  ^(drag your 512x512 PNG onto this^)
if exist FIX-VIDEO-DATABASE.bat echo   [OK] FIX-VIDEO-DATABASE.bat  ^(video Delete / Analyze database fix^)
if exist KARA-PASTE-THIS-IN-SUPABASE.txt echo   [OK] KARA-PASTE-THIS-IN-SUPABASE.txt  ^(SQL to paste in Supabase^)
if exist scripts dir scripts
echo.
echo Video Delete or Analyze broken? Run FIX-VIDEO-DATABASE.bat once, then KARA-GEMINI-FIX-NOW.bat
echo.
echo NEXT: Double-click KARA-SEE-UPDATES-NOW.bat (should work now — no merge error)
echo.
pause
exit /b 0

:WriteCopyLogoBat
(
echo @echo off
echo title SwimIQ Copy Logo (512x512^)
echo cd /d "%%~dp0"
echo.
echo if "%%~1"=="" ^(
echo   echo.
echo   echo Drag your 512x512 swimiq_icon.png ONTO this file,
echo   echo OR run: COPY-LOGO.bat "C:\path\to\your\logo.png"
echo   echo.
echo   pause
echo   exit /b 1
echo ^)
echo.
echo set "SRC=%%~1"
echo if not exist "%%SRC%%" ^(
echo   echo File not found: %%SRC%%
echo   pause
echo   exit /b 1
echo ^)
echo.
echo if not exist "assets\branding" mkdir "assets\branding"
echo if not exist "web\icons" mkdir "web\icons"
echo.
echo copy /Y "%%SRC%%" "assets\branding\swimiq_icon.png"
echo copy /Y "%%SRC%%" "web\favicon.png"
echo copy /Y "%%SRC%%" "web\icons\Icon-512.png"
echo copy /Y "%%SRC%%" "web\icons\Icon-192.png"
echo.
echo echo.
echo echo Done! Logo copied to:
echo echo   assets\branding\swimiq_icon.png
echo echo   web\favicon.png
echo echo   web\icons\Icon-512.png
echo echo   web\icons\Icon-192.png
echo echo.
echo echo Close Chrome, then run LAUNCH-CHROME.bat
echo pause
) > "%~dp0COPY-LOGO.bat"
exit /b 0
