@echo off
rem Creates DRAG-LOGO-HERE.bat and COPY-LOGO.bat if missing.
cd /d "%~dp0.."

if exist "DRAG-LOGO-HERE.bat" if exist "COPY-LOGO.bat" exit /b 0

(
echo @echo off
echo title SwimIQ Copy Logo (512x512^)
echo cd /d "%%~dp0"
echo.
echo if "%%~1"=="" ^(
echo   echo.
echo   echo ========================================
echo   echo  SwimIQ - DRAG YOUR LOGO HERE
echo   echo ========================================
echo   echo.
echo   echo Drag your 512x512 swimiq_icon.png ONTO this file.
echo   echo.
echo   echo Or run: DRAG-LOGO-HERE.bat "C:\path\to\your\logo.png"
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
echo echo   web\icons\Icon-192.png
echo echo   web\icons\Icon-512.png
echo echo.
echo echo Close Chrome, then run LAUNCH-CHROME.bat
echo pause
) > "DRAG-LOGO-HERE.bat"

copy /Y "DRAG-LOGO-HERE.bat" "COPY-LOGO.bat" >nul
echo [OK] Created DRAG-LOGO-HERE.bat and COPY-LOGO.bat in %CD%
exit /b 0
