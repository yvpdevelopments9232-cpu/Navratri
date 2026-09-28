@echo off
setlocal
cd /d "%~dp0"
echo ==============================================================
echo    Navratri Utsav - Download Latest iOS .IPA from GitHub
echo ==============================================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0download_latest_ipa.ps1"
echo.
pause
