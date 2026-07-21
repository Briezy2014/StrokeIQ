@echo off
setlocal EnableExtensions EnableDelayedExpansion
title SwimIQ - DOUBLE CLICK ME
cd /d "%~dp0"

echo.
echo ############################################################
echo #  SwimIQ - ONE double-click website update                #
echo ############################################################
echo.
echo This downloads the READY website zip (login works).
echo No typing. No git. No build folder hunting.
echo.

set "OUTDIR=%CD%\UPLOAD-TO-GODADDY"
set "ZIP=%OUTDIR%\swimiq-web-godaddy.zip"
set "PROOF=%OUTDIR%\SWIMIQ-FLUTTER-BUILD.txt"
set "HOW=%OUTDIR%\HOW-TO-UPLOAD.txt"
set "ZIP_URL=https://github.com/Briezy2014/StrokeIQ/releases/download/swimiq-web-LATEST/swimiq-web-godaddy.zip"
set "PROOF_URL=https://github.com/Briezy2014/StrokeIQ/releases/download/swimiq-web-LATEST/SWIMIQ-FLUTTER-BUILD.txt"

if not exist "%OUTDIR%" mkdir "%OUTDIR%"

echo [1/3] Downloading website zip...
echo      %ZIP_URL%
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop'; ^
   $zip='%ZIP%'; $proof='%PROOF%'; ^
   $zipUrl='%ZIP_URL%'; $proofUrl='%PROOF_URL%'; ^
   if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip -Force }; ^
   if (Test-Path -LiteralPath $proof) { Remove-Item -LiteralPath $proof -Force }; ^
   Write-Host 'Downloading zip (about 16 MB)...'; ^
   Invoke-WebRequest -Uri $zipUrl -OutFile $zip -UseBasicParsing; ^
   try { Invoke-WebRequest -Uri $proofUrl -OutFile $proof -UseBasicParsing } catch {}; ^
   if (-not (Test-Path -LiteralPath $zip)) { throw 'Download missing' }; ^
   $len=(Get-Item -LiteralPath $zip).Length; ^
   if ($len -lt 1000000) { throw ('Zip too small: ' + $len) }; ^
   Write-Host ('OK downloaded ' + [math]::Round($len/1MB,1) + ' MB')"
if errorlevel 1 (
  echo.
  echo [FAIL] Download failed.
  echo Open https://github.com in Chrome. If it fails, use phone hotspot.
  echo Then double-click this file again.
  start "" "https://github.com/Briezy2014/StrokeIQ/releases/tag/swimiq-web-LATEST"
  pause
  exit /b 1
)

echo.
echo [2/3] Writing upload instructions...
(
  echo UPLOAD THIS ZIP TO GODADDY
  echo ==========================
  echo.
  echo File to upload:
  echo   swimiq-web-godaddy.zip
  echo   ^(in this same folder^)
  echo.
  echo Steps:
  echo   1. GoDaddy / cPanel File Manager
  echo   2. Open public_html
  echo   3. Upload swimiq-web-godaddy.zip
  echo   4. Extract → Overwrite ALL
  echo   5. Open https://swimiqapp.com/SWIMIQ-FLUTTER-BUILD.txt
  echo      Must say: supabase=connected
  echo   6. Hard refresh the app: Ctrl+Shift+R
  echo   7. Log in and Analyze again
  echo.
  echo Do NOT upload a "web" folder from swimiq\build.
  echo Do NOT use older zips from Downloads.
) > "%HOW%"

echo [3/3] Opening the upload folder...
echo.
echo ############################################################
echo #  DONE — upload folder is open                            #
echo ############################################################
echo.
echo Upload this file to GoDaddy public_html:
echo   %ZIP%
echo.
echo Then extract → overwrite all.
echo.

start "" notepad "%HOW%"
timeout /t 1 /nobreak >nul
explorer.exe /select,"%ZIP%"
start "" "https://swimiqapp.com/SWIMIQ-FLUTTER-BUILD.txt"

echo After GoDaddy extract, refresh that proof page until it says
echo supabase=connected — then Ctrl+Shift+R on the app.
echo.
pause
exit /b 0
