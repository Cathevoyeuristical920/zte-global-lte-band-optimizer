@echo off
chcp 65001 >nul 2>&1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0internet-avcisi.ps1" %*
if %ERRORLEVEL% neq 0 (
    echo.
    echo Bir hata olustu / An error occurred.
    pause
)
