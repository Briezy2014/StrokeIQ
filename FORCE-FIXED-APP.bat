@echo off
setlocal
cd /d "%~dp0"

echo.
echo ============================================
echo   SwimIQ - load fixed branch, then launch
echo   Folder: %CD%
echo ============================================
echo.
echo Do NOT use StrokeIQ-Elite.
echo Use this Desktop\StrokeIQ folder only.
echo.

if not exist ".git" (
  echo [FAIL] Run this from Desktop\StrokeIQ
  pause
  exit /b 1
)

git fetch origin
git merge --abort >nul 2>&1
git checkout -f cursor/elite-video-on-dashboard-b7ef
git reset --hard origin/cursor/elite-video-on-dashboard-b7ef
if errorlevel 1 (
  echo [FAIL] Could not switch branches.
  pause
  exit /b 1
)

if not exist "swimiq\lib\widgets\swimiq_rope_climb_card.dart" (
  echo [FAIL] Rope file missing after checkout.
  pause
  exit /b 1
)
if not exist "swimiq\lib\core\recruiting\recruiting_business_card_pdf.dart" (
  echo [FAIL] Passport card file missing after checkout.
  pause
  exit /b 1
)

echo [OK] Fixed branch loaded.
echo [OK] Rope + passport card files present.
echo.
echo NEXT: launching with the Kara path-safe Chrome script...
echo This avoids the 'C:\Users\Kara' space crash.
echo.
cd /d "%~dp0swimiq"
call "%~dp0swimiq\LAUNCH-CHROME.bat"
