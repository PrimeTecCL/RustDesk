@echo off
REM Instalar-RustDesk-PrimeTec.bat
REM Doble clic en este archivo instala y configura RustDesk para el servidor
REM interno de PrimeTec (rustdesk.primetec.cl). Internamente ejecuta el script
REM de PowerShell que esta en la misma carpeta.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Instalar-RustDesk-PrimeTec.ps1"
pause
