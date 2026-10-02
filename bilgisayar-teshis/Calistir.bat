@echo off
chcp 65001 >nul
rem Teshis.ps1 betigini yonetici olarak calistirir. Cift tiklamaniz yeterli.
net session >/dev/null 2>&1
if errorlevel 1 (
    powershell -NoProfile -Command "Start-Process -FilePath %~f0 -Verb RunAs"
    exit /b
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Teshis.ps1"
echo.
echo Rapor masaustune kaydedildi: Teshis-Raporu.txt
pause
