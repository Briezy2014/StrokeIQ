@echo off
REM Turns Elite Video Engine V2 OFF so the existing Video Lab path works again
REM (Gemini Edge Function + AI consent dialog). Use this when you see:
REM   "The analysis service is temporarily unavailable"
cd /d "%~dp0"

if not exist ".env" (
  echo [FAIL] No .env in %CD%
  echo Run make-env.bat first.
  pause
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$p='.env'; $c=Get-Content -LiteralPath $p; $out=@(); $found=$false; foreach($l in $c){ if($l -match '^\s*VIDEO_ENGINE_V2\s*='){ $out+='VIDEO_ENGINE_V2=false'; $found=$true } else { $out+=$l } }; if(-not $found){ $out+='VIDEO_ENGINE_V2=false' }; Set-Content -LiteralPath $p -Value $out -Encoding UTF8"

echo.
echo [OK] Set VIDEO_ENGINE_V2=false in .env
echo.
echo NEXT: close the app, then run START-SWIMIQ.bat again.
echo Video will use the working legacy analysis + consent dialog.
echo.
pause
