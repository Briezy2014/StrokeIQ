@echo off
title SwimIQ Diagnose
cd /d "%~dp0"
echo.
echo === SwimIQ quick diagnose ===
echo.
if exist "%~dp0assets\branding\icon.png" (
  echo [OK] assets\branding\icon.png  ^(login uses this^)
) else (
  echo [MISSING] assets\branding\icon.png  ^(login will show fallback^)
)
if exist "%~dp0assets\branding\banner.png" (
  echo [OK] assets\branding\banner.png
) else (
  echo [MISSING] assets\branding\banner.png
)
if exist "%~dp0assets\branding\mark.png" (
  echo [OK] assets\branding\mark.png
) else (
  echo [OPTIONAL] assets\branding\mark.png
)
if exist "%~dp0assets\branding\swimiq_icon.png" (
  echo [WARN] assets\branding\swimiq_icon.png exists but login ignores it
  echo        Drag your icon onto COPY-LOGO.bat or SYNC-LOGO-NOW.bat instead.
)
if exist "%~dp0web\favicon.png" (echo [OK] web\favicon.png) else (echo [MISSING] web\favicon.png)
if exist "%~dp0.env" (echo [OK] .env) else (echo [MISSING] .env)
echo.
pause
