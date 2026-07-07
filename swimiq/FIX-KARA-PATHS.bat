@echo off
REM ============================================================
REM  ONE-TIME FIX for "C:\Users\Kara is not recognized"
REM  Double-click ONCE. Close ALL VS Code / PowerShell windows after.
REM  Then use LAUNCH-CHROME.bat every night.
REM ============================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\kara-fix-windows-once.ps1"
pause
