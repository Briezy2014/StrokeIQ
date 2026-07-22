@echo off
title SwimIQ Android Diagnose
cd /d "%~dp0"
set LOG=%~dp0android-diagnose-log.txt
echo SwimIQ Android Diagnose > "%LOG%"
echo Folder: %CD%>> "%LOG%"
echo.>> "%LOG%"

echo === SwimIQ Android Diagnose ===
echo Writing log: %LOG%
echo.

where flutter >> "%LOG%" 2>&1
where keytool >> "%LOG%" 2>&1
echo.>> "%LOG%"

if exist "%~dp0.env" (echo [OK] .env) else (echo [MISSING] .env — copy from .env.example)
if exist "%~dp0android\key.properties" (echo [OK] android\key.properties) else (echo [MISSING] android\key.properties — run GENERATE-ANDROID-KEYSTORE.bat)
if exist "%~dp0android\keystore\swimiq-upload.jks" (echo [OK] upload keystore) else (echo [MISSING] android\keystore\swimiq-upload.jks)
if exist "%~dp0android\settings.gradle" (echo [WARN] old settings.gradle — pull latest, should only have settings.gradle.kts) else (echo [OK] no duplicate settings.gradle)
if exist "%~dp0android\app\build.gradle" (echo [WARN] old app/build.gradle — pull latest, should only have build.gradle.kts) else (echo [OK] no duplicate app/build.gradle)

echo.
echo --- flutter doctor -v (saved to log) ---
call flutter doctor -v >> "%LOG%" 2>&1
flutter doctor
echo.
echo --- flutter build appbundle dry run (gradle sync) ---
echo If this fails, open %LOG% and send the last 40 lines to support.
call flutter pub get >> "%LOG%" 2>&1
call flutter build appbundle --release >> "%LOG%" 2>&1
if errorlevel 1 (
  echo BUILD FAILED — see %LOG%
) else (
  echo BUILD OK — AAB at build\app\outputs\bundle\release\app-release.aab
)
echo.
pause
