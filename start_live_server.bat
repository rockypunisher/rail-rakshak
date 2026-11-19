@echo off
title RAIL RAKSHAK Live Train Server
echo ========================================================
echo    Starting RAIL RAKSHAK Live Train Server
echo    URL: http://127.0.0.1:8000
echo ========================================================
echo.
cd /d "%~dp0"

start "" "http://127.0.0.1:8000"

if exist "C:\Users\A C E R\AppData\Local\Programs\Python\Python313\python.exe" (
    "C:\Users\A C E R\AppData\Local\Programs\Python\Python313\python.exe" live_server.py
) else (
    python live_server.py
)

pause
