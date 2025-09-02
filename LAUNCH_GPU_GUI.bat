@echo off
echo 🚀 Starting GPU-Enhanced Ambient Video Studio...
echo.
echo Detecting NVIDIA RTX 5080 and RTX 5060 Ti...
echo Preparing hardware acceleration...
echo.

REM Navigate to the correct directory
cd /d "%~dp0"

REM Launch the GPU-enhanced GUI
powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "GPU_Enhanced_GUI.ps1"

REM If there's an error, show it
if %ERRORLEVEL% neq 0 (
    echo ❌ Error launching GPU GUI. Trying alternative method...
    powershell.exe -ExecutionPolicy Bypass -File "GPU_Enhanced_GUI.ps1"
    pause
)
