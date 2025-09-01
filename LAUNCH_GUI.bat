@echo off
echo 🎬 Starting Ambient Video Studio GUI...
echo.

REM Navigate to the correct directory
cd /d "%~dp0"

REM Launch the GUI
powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "Ambient_Video_GUI.ps1"

REM If there's an error, show it
if %ERRORLEVEL% neq 0 (
    echo.
    echo ❌ Error launching GUI. Trying alternative method...
    echo.
    powershell.exe -ExecutionPolicy Bypass -File "Ambient_Video_GUI.ps1"
    pause
)