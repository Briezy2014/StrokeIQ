@echo off
setlocal EnableDelayedExpansion
cd /d "%~dp0"

echo.
echo ============================================
echo   SwimIQ - FORCE the fixed app branch
echo   Folder: %CD%
echo ============================================
echo.

where git >nul 2>&1
if errorlevel 1 (
  echo [FAIL] Git is not installed or not on PATH.
  pause
  exit /b 1
)

if not exist ".git" (
  echo [FAIL] This folder is not the StrokeIQ git repo.
  echo Put this file inside Desktop\StrokeIQ and run it there.
  echo Do NOT run this from StrokeIQ-Elite.
  pause
  exit /b 1
)

echo [1/6] Fetching from GitHub...
git fetch origin
if errorlevel 1 (
  echo [FAIL] git fetch failed. Check internet / GitHub login.
  pause
  exit /b 1
)

echo [2/6] Aborting any stuck merge...
git merge --abort >nul 2>&1

echo [3/6] Switching to fixed branch...
git checkout -f cursor/elite-video-on-dashboard-b7ef
if errorlevel 1 (
  git checkout -B cursor/elite-video-on-dashboard-b7ef origin/cursor/elite-video-on-dashboard-b7ef
)
git reset --hard origin/cursor/elite-video-on-dashboard-b7ef
if errorlevel 1 (
  echo [FAIL] Could not reset to fixed branch.
  pause
  exit /b 1
)

echo [4/6] Checking that rope + passport card files exist...
if not exist "swimiq\lib\widgets\swimiq_rope_climb_card.dart" (
  echo [FAIL] Rope file MISSING. Wrong folder or checkout failed.
  pause
  exit /b 1
)
if not exist "swimiq\lib\core\recruiting\recruiting_business_card_pdf.dart" (
  echo [FAIL] Passport card file MISSING. Wrong folder or checkout failed.
  pause
  exit /b 1
)
echo [OK] Rope file found
echo [OK] Passport card file found

echo [5/6] Turning Elite V2 OFF so Video works without Python server...
if exist "swimiq\.env" (
  powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$p='swimiq\.env'; $c=Get-Content -LiteralPath $p; $out=@(); $found=$false; foreach($l in $c){ if($l -match '^\s*VIDEO_ENGINE_V2\s*='){ $out+='VIDEO_ENGINE_V2=false'; $found=$true } else { $out+=$l } }; if(-not $found){ $out+='VIDEO_ENGINE_V2=false' }; Set-Content -LiteralPath $p -Value $out -Encoding UTF8"
  echo [OK] VIDEO_ENGINE_V2=false
) else (
  echo [WARN] swimiq\.env not found yet. After make-env.bat, keep VIDEO_ENGINE_V2=false
)

echo [6/6] Creating S: drive shortcut...
if exist "swimiq\scripts\setup-short-path.bat" (
  call "swimiq\scripts\setup-short-path.bat"
) else (
  echo [WARN] setup-short-path.bat missing
)

echo.
echo ============================================
echo   SUCCESS - fixed branch is loaded
echo ============================================
echo.
echo Current branch:
git branch --show-current
echo.
echo NEXT STEPS:
echo   1. Close Chrome / any old SwimIQ window
echo   2. Open a NEW PowerShell
echo   3. Run:
echo        S:
echo        cd swimiq
echo        .\START-SWIMIQ.bat
echo.
echo After login you MUST see bottom tabs:
echo   Dashboard | PBs | Log | Goals | Video | Passport
echo   ^(NO separate Add tab^)
echo Dashboard must show the rope climb card.
echo.
pause
