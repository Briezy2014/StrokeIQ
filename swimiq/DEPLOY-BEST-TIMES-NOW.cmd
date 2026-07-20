@echo off
setlocal EnableExtensions
title SwimIQ - Deploy best times (npx.cmd)
cd /d "%~dp0"

echo.
echo This uses Node's npx.cmd (avoids PowerShell script block).
echo Project: bryurwyeosbffvfpdbv
echo.
pause

set "NPX="
if exist "%ProgramFiles%\nodejs\npx.cmd" set "NPX=%ProgramFiles%\nodejs\npx.cmd"
if not defined NPX if exist "%ProgramFiles(x86)%\nodejs\npx.cmd" set "NPX=%ProgramFiles(x86)%\nodejs\npx.cmd"
if not defined NPX (
  where npx.cmd >nul 2>nul
  if not errorlevel 1 for /f "delims=" %%I in ('where npx.cmd') do set "NPX=%%I" & goto :have_npx
)
:have_npx
if not defined NPX (
  echo [ERROR] Node.js not found. Install LTS from https://nodejs.org
  pause
  exit /b 1
)

echo Using: "%NPX%"
echo.

echo [1/4] Login ...
call "%NPX%" --yes supabase login
if errorlevel 1 goto :fail

echo [2/4] Link project ...
call "%NPX%" --yes supabase link --project-ref bryurwyeosbffvfpdbv
if errorlevel 1 goto :fail

echo [3/4] Deploy extract-best-times ...
call "%NPX%" --yes supabase functions deploy extract-best-times
if errorlevel 1 goto :fail

echo [4/4] Deploy analyze-swim-video ...
call "%NPX%" --yes supabase functions deploy analyze-swim-video
if errorlevel 1 goto :fail

echo.
echo [OK] Done. Hard-refresh SwimIQ, then Upload best times.
pause
exit /b 0

:fail
echo.
echo [ERROR] Deploy failed. Check GEMINI_API_KEY in Supabase secrets.
pause
exit /b 1
