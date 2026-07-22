@echo off
title SwimIQ Fix Android Pull
cd /d "%~dp0"

for /f "delims=" %%i in ('git rev-parse --show-toplevel 2^>nul') do set "GITROOT=%%i"
if not defined GITROOT (
  echo ERROR: Not a git folder. cd to S:\ or S:\swimiq where .git lives.
  pause
  exit /b 1
)

cd /d "%GITROOT%"
echo.
echo ========================================
echo  SwimIQ - Fix Android Git Pull
echo ========================================
echo Git folder: %GITROOT%
echo.

echo Step 1: Drop LOCAL edits to Android Gradle files...
git checkout -- swimiq/android/gradle.properties 2>nul
git checkout -- swimiq/android/settings.gradle 2>nul
git checkout -- swimiq/android/build.gradle 2>nul
git checkout -- swimiq/android/app/build.gradle 2>nul
git checkout -- android/gradle.properties 2>nul
git checkout -- android/settings.gradle 2>nul
git checkout -- android/build.gradle 2>nul
git checkout -- android/app/build.gradle 2>nul

echo Step 2: Pull Android AAB + PDF branch...
git fetch origin cursor/android-aab-pdf-export-17e8
git pull origin cursor/android-aab-pdf-export-17e8
if errorlevel 1 (
  echo.
  echo Pull still failed. Run in PowerShell from %GITROOT% :
  echo   git stash push -u -m "kara-backup-before-android-pull"
  echo   git pull origin cursor/android-aab-pdf-export-17e8
  echo.
  pause
  exit /b 1
)

echo.
echo Step 3: Remove OLD duplicate Gradle files if they came back...
if exist "%GITROOT%\swimiq\android\settings.gradle" (
  if exist "%GITROOT%\swimiq\android\settings.gradle.kts" del /f /q "%GITROOT%\swimiq\android\settings.gradle"
)
if exist "%GITROOT%\swimiq\android\build.gradle" (
  if exist "%GITROOT%\swimiq\android\build.gradle.kts" del /f /q "%GITROOT%\swimiq\android\build.gradle"
)
if exist "%GITROOT%\swimiq\android\app\build.gradle" (
  if exist "%GITROOT%\swimiq\android\app\build.gradle.kts" del /f /q "%GITROOT%\swimiq\android\app\build.gradle"
)

echo.
echo ========================================
echo  PULL DONE
echo ========================================
echo.
echo Next:
echo   1. cd S:\swimiq
echo   2. GENERATE-ANDROID-KEYSTORE.bat  (once)
echo   3. SWIMIQ-BUILD-AAB-NOW.bat
echo.
pause
