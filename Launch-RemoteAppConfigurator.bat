@echo off
:: Launch RemoteApp Configurator with Administrator privileges
:: This script will request elevation if not already running as admin

NET SESSION >nul 2>&1
if %errorLevel% == 0 (
    powershell -ExecutionPolicy Bypass -File "%~dp0RemoteAppConfigurator.ps1"
) else (
    echo Requesting administrator privileges...
    powershell -Command "Start-Process -FilePath 'powershell.exe' -ArgumentList '-ExecutionPolicy Bypass -File \"%~dp0RemoteAppConfigurator.ps1\"' -Verb RunAs"
)
