@echo off
setlocal
title Open SwimIQ in browser
echo.
echo Opening http://127.0.0.1:7357/
echo If this fails, the launch window is not serving yet.
echo Leave START-SWIMIQ-WITH-ELITE / Launch Chrome window open.
echo.
start "" "http://127.0.0.1:7357/"
exit /b 0
