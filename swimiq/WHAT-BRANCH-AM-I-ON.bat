@echo off
cd /d "%~dp0\.."
echo.
echo Folder: %CD%
echo.
git branch --show-current
echo.
if exist "swimiq\lib\widgets\swimiq_rope_climb_card.dart" (
  echo [OK] Rope file EXISTS - this can show the rope
) else (
  echo [BAD] Rope file MISSING - you are on the wrong app copy
)
if exist "swimiq\lib\core\recruiting\recruiting_business_card_pdf.dart" (
  echo [OK] Passport card file EXISTS
) else (
  echo [BAD] Passport card file MISSING - wrong app copy
)
echo.
echo If branch is NOT cursor/elite-video-on-dashboard-b7ef, run FORCE-FIXED-APP.bat
echo from the StrokeIQ folder.
echo.
pause
