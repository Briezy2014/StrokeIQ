@echo off
title SwimIQ Restore Scripts
cd /d "%~dp0"
echo.
echo Restoring scripts folder from GitHub...
echo.
git fetch origin cursor/windows-chrome-spaces-fix-17e8
git checkout origin/cursor/windows-chrome-spaces-fix-17e8 -- scripts/
git checkout origin/cursor/windows-chrome-spaces-fix-17e8 -- SWIMIQ-CHROME-NOW.ps1 SWIMIQ-CHROME-NOW.bat SWIMIQ-BUILD-GODADDY-NOW.ps1 SWIMIQ-BUILD-GODADDY-NOW.bat SWIMIQ-BUILD-ANDROID-NOW.ps1 SWIMIQ-BUILD-ANDROID-NOW.bat START-HERE.bat KARA-CLICK-THIS.bat LAUNCH-CHROME.bat FIX-KARA-PATHS.bat FIX-GIT-PULL.bat DIAGNOSE.bat TEST-OWNER-LOGIN.bat SYNC-LOGO-NOW.bat restore-scripts.ps1 COPY-LOGO.bat DRAG-LOGO-HERE.bat ZIP-GODADDY-UPLOAD.bat

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
if exist scripts dir scripts
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
