@echo off
setlocal EnableExtensions EnableDelayedExpansion
title SwimIQ - DOUBLE CLICK ME
cd /d "%~dp0"

echo.
echo ############################################################
echo #  SwimIQ website update — double-click only               #
echo ############################################################
echo.
echo Live site is broken until you upload the CONNECTED zip.
echo This script downloads that zip and opens the folder.
echo.

set "OUTDIR=%CD%\UPLOAD-TO-GODADDY"
set "ZIP=%OUTDIR%\1-UPLOAD-THIS-TO-GODADDY.zip"
set "PROOF=%OUTDIR%\SWIMIQ-FLUTTER-BUILD.txt"
set "HOW=%OUTDIR%\READ-ME-UPLOAD-STEPS.txt"
set "ZIP_URL=https://github.com/Briezy2014/StrokeIQ/releases/download/swimiq-web-LATEST/swimiq-web-godaddy.zip"
set "PROOF_URL=https://github.com/Briezy2014/StrokeIQ/releases/download/swimiq-web-LATEST/SWIMIQ-FLUTTER-BUILD.txt"

if not exist "%OUTDIR%" mkdir "%OUTDIR%" >nul 2>&1

echo [1/4] Downloading CONNECTED website zip...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop'; ^
   $outDir='%OUTDIR%'; $zip='%ZIP%'; $proof='%PROOF%'; ^
   New-Item -ItemType Directory -Force -Path $outDir | Out-Null; ^
   Get-ChildItem -LiteralPath $outDir -Filter '*.zip' -ErrorAction SilentlyContinue | Remove-Item -Force; ^
   Write-Host 'Downloading...'; ^
   Invoke-WebRequest -Uri '%ZIP_URL%' -OutFile $zip -UseBasicParsing; ^
   try { Invoke-WebRequest -Uri '%PROOF_URL%' -OutFile $proof -UseBasicParsing } catch {}; ^
   $len=(Get-Item -LiteralPath $zip).Length; ^
   if ($len -lt 5000000) { throw ('Zip too small: ' + $len) }; ^
   Add-Type -AssemblyName System.IO.Compression.FileSystem; ^
   $z=[System.IO.Compression.ZipFile]::OpenRead($zip); ^
   try { ^
     $e=$z.GetEntry('main.dart.js'); ^
     if ($null -eq $e) { throw 'Zip missing main.dart.js — wrong file' }; ^
     $sr=New-Object System.IO.StreamReader($e.Open()); ^
     $chunk=$sr.ReadToEnd(); $sr.Close(); ^
     if ($chunk -notmatch 'bryurwyeosbffvfpdpbv\.supabase\.co') { throw 'Zip is NOT connected (missing Supabase). Do not upload.' }; ^
     if ($chunk -notmatch 'eyJ') { throw 'Zip is NOT connected (missing anon key). Do not upload.' }; ^
     Write-Host 'OK — zip is CONNECTED (login keys present)'; ^
     Write-Host ('Size: ' + [math]::Round($len/1MB,1) + ' MB'); ^
   } finally { $z.Dispose() }"
if errorlevel 1 (
  echo.
  echo [FAIL] Could not download a CONNECTED zip.
  echo Fix: open https://github.com , use phone hotspot if needed,
  echo then double-click this file again.
  start "" "https://github.com/Briezy2014/StrokeIQ/releases/tag/swimiq-web-LATEST"
  pause
  exit /b 1
)

echo.
echo [2/4] Writing upload steps...
(
  echo ============================================================
  echo   UPLOAD ONLY THIS FILE
  echo ============================================================
  echo.
  echo   1-UPLOAD-THIS-TO-GODADDY.zip
  echo.
  echo   ^(in this folder: UPLOAD-TO-GODADDY^)
  echo.
  echo ============================================================
  echo   STEPS
  echo ============================================================
  echo.
  echo   1. Open GoDaddy cPanel File Manager
  echo   2. Go into public_html
  echo   3. Upload: 1-UPLOAD-THIS-TO-GODADDY.zip
  echo   4. Right-click the zip → Extract
  echo   5. Choose Overwrite / Replace existing files
  echo   6. Make sure index.html and main.dart.js are INSIDE
  echo      public_html  ^(not inside an extra folder^)
  echo.
  echo   7. Open this proof link:
  echo      https://swimiqapp.com/SWIMIQ-FLUTTER-BUILD.txt
  echo.
  echo      MUST say:  supabase=connected
  echo.
  echo      If it does NOT say that, you uploaded the wrong zip
  echo      or did not overwrite. Run DOUBLE-CLICK-ME again.
  echo.
  echo   8. Hard refresh the app: Ctrl+Shift+R
  echo      Then you should see LOGIN — not "not connected".
  echo.
  echo ============================================================
  echo   DO NOT UPLOAD
  echo ============================================================
  echo   - Kara-DOUBLE-CLICK-STARTER.zip
  echo   - Anything from swimiq\build
  echo   - Older zips in Downloads
  echo.
) > "%HOW%"

echo [3/4] Opening upload folder + instructions...
start "" notepad "%HOW%"
timeout /t 1 /nobreak >nul
explorer.exe /select,"%ZIP%"

echo [4/4] Opening proof page (will still be OLD until you upload)...
start "" "https://swimiqapp.com/SWIMIQ-FLUTTER-BUILD.txt"

echo.
echo ############################################################
echo #  NEXT ACTION FOR YOU                                     #
echo ############################################################
echo.
echo File Manager is where you upload:
echo   %ZIP%
echo.
echo After extract+overwrite, proof page must say:
echo   supabase=connected
echo.
echo Right now live is still the BROKEN zip — that is why you
echo see "not connected". Uploading this file fixes it.
echo.
pause
exit /b 0
