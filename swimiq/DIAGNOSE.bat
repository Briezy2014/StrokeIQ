@echo off
title SwimIQ Diagnose
cd /d "%~dp0"
echo.
echo === SwimIQ branding diagnose ===
echo.
echo LOGIN reads ONLY: assets\branding\icon.png
echo (logo.png is a mirror copy for your brand folder — must match icon.png)
echo.
if exist "%~dp0assets\branding\icon.png" (
  echo [OK] assets\branding\icon.png  ^(login screen^)
) else (
  echo [MISSING] assets\branding\icon.png  ^(login will show fallback^)
)
if exist "%~dp0assets\branding\logo.png" (
  echo [OK] assets\branding\logo.png  ^(brand kit mirror^)
) else (
  echo [OPTIONAL] assets\branding\logo.png  ^(run COPY-LOGO.bat to create^)
)
if exist "%~dp0assets\branding\icon.png" if exist "%~dp0assets\branding\logo.png" (
  fc /b "%~dp0assets\branding\icon.png" "%~dp0assets\branding\logo.png" >nul 2>&1
  if errorlevel 1 (
    echo [WARN] icon.png and logo.png are DIFFERENT files
    echo        Login uses icon.png only. Drag your logo onto COPY-LOGO.bat.
  ) else (
    echo [OK] icon.png and logo.png match
  )
)
if exist "%~dp0assets\branding\banner.png" (
  echo [OK] assets\branding\banner.png  ^(tab banner^)
) else (
  echo [MISSING] assets\branding\banner.png
)
if exist "%~dp0assets\branding\mark.png" (
  echo [OK] assets\branding\mark.png
) else (
  echo [OPTIONAL] assets\branding\mark.png
)
if exist "%~dp0assets\branding\swimiq_icon.png" (
  echo [WARN] swimiq_icon.png exists but login IGNORES it
)
if exist "%~dp0assets\branding\swimiq_logo.png" (
  echo [WARN] swimiq_logo.png in branding is IGNORED — use icon.png
)
if exist "%~dp0web\favicon.png" (echo [OK] web\favicon.png) else (echo [MISSING] web\favicon.png)
if exist "%~dp0.env" (echo [OK] .env) else (echo [MISSING] .env)
echo.
pause
