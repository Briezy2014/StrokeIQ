@echo off
setlocal EnableExtensions EnableDelayedExpansion
title SwimIQ + Elite Video Lab
cd /d "%~dp0"

echo.
echo ############################################################
echo #  START SwimIQ WITH Elite                                #
echo #  This is the ONE file for analysis on THIS PC           #
echo ############################################################
echo.
echo This one file:
echo   1. Updates from GitHub (best effort)
echo   2. Fixes duplicate GEMINI_API_KEY lines (keep ONE only)
echo   3. Starts Elite black window (LEAVE IT OPEN)
echo   4. Waits until http://127.0.0.1:8080 answers
echo   5. Opens SwimIQ in Chrome on localhost
echo.

echo [1/5] Updating folder from GitHub...
git -C "%CD%" fetch origin cursor/elite-video-on-dashboard-b7ef
if errorlevel 1 (
  echo [WARN] git fetch failed - continuing with files already on disk.
) else (
  git -C "%CD%" checkout -f cursor/elite-video-on-dashboard-b7ef
  if not errorlevel 1 (
    git -C "%CD%" reset --hard origin/cursor/elite-video-on-dashboard-b7ef
  )
)
echo [OK] Ready to start Elite.
echo.

echo [2/5] Checking Gemini key - MUST be exactly ONE GEMINI_API_KEY line...
if exist "%CD%\swimiq\.env" (
  if exist "%CD%\swimiq\scripts\fix-one-gemini-key.ps1" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%CD%\swimiq\scripts\fix-one-gemini-key.ps1"
  ) else (
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
      "$p='%~dp0swimiq\.env'; $lines=Get-Content -LiteralPath $p; $keys=@(); $out=New-Object System.Collections.Generic.List[string]; foreach($l in $lines){ if($l -match '^\s*GEMINI_API_KEY\s*='){ $keys+=$l } else { [void]$out.Add($l) } }; if($keys.Count -gt 1){ Write-Host ('[FIX] Found '+$keys.Count+' GEMINI_API_KEY lines - keeping the LAST one only') -ForegroundColor Yellow; $v=($keys[-1] -replace '^\s*GEMINI_API_KEY\s*=\s*','').Trim().Trim('\"').Trim(\"'\"); [void]$out.Add('GEMINI_API_KEY='+$v); Set-Content -LiteralPath $p -Value $out.ToArray() -Encoding ascii } elseif($keys.Count -eq 1){ Write-Host '[OK] One GEMINI_API_KEY line' -ForegroundColor Green } else { Write-Host '[WARN] No GEMINI_API_KEY line yet' -ForegroundColor Yellow }"
  )
) else (
  echo [WARN] Missing swimiq\.env
)
echo.

if not exist "%CD%\swimiq\scripts\start-elite-and-wait.ps1" (
  echo [FAIL] Missing swimiq\scripts\start-elite-and-wait.ps1
  echo Run GET-LATEST-FIXED-APP.bat on Wi-Fi, then run this file again.
  pause
  exit /b 1
)

echo [3/5] Clearing old Elite on port 8080...
if exist "%CD%\swimiq\scripts\kill-elite-port.ps1" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%CD%\swimiq\scripts\kill-elite-port.ps1"
)
echo.

echo [4/5] Starting Elite server...
echo A NEW black window titled "Elite Video Lab" will open.
echo DO NOT CLOSE THAT WINDOW.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%CD%\swimiq\scripts\start-elite-and-wait.ps1" -ForceRestart
if errorlevel 1 (
  echo.
  echo [FAIL] Elite is not answering on http://127.0.0.1:8080
  echo Look at the Elite black window for the error.
  echo.
  pause
  exit /b 1
)

echo.
echo [5/5] Elite is up. Opening Chrome on localhost (NOT swimiqapp.com)...
echo Keep BOTH windows open: Elite black window + Chrome.
echo.
if not exist "%CD%\swimiq\LAUNCH-CHROME.bat" (
  echo [FAIL] Missing swimiq\LAUNCH-CHROME.bat
  pause
  exit /b 1
)
call "%CD%\swimiq\LAUNCH-CHROME.bat"
exit /b %ERRORLEVEL%
