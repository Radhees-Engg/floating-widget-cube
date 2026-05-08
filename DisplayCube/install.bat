@echo off
title DisplayCube Installer
color 0A

:: Check files are in the right place
if not exist "C:\DisplayCube\setup.ps1" (
    echo.
    echo  [ERROR] Files not found in C:\DisplayCube\
    echo.
    echo  Please make sure all files are placed in C:\DisplayCube\
    echo  before running this installer.
    echo.
    pause
    exit /b
)

:: Elevate to Admin
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo  Requesting administrator privileges...
    powershell -Command "Start-Process powershell -ArgumentList '-ExecutionPolicy Bypass -File C:\DisplayCube\setup.ps1' -Verb RunAs"
    exit /b
)

powershell -ExecutionPolicy Bypass -File C:\DisplayCube\setup.ps1
pause
