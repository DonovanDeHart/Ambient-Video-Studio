@echo off
echo 🚀 Ambient Video Studio - Production Mode
echo ==========================================
echo.
echo Initializing commercial-grade production environment...
echo.

REM Navigate to the correct directory
cd /d "%~dp0"

REM Check if production environment is initialized
if not exist "Production" (
    echo 📁 Production environment not found. Initializing...
    echo.
    powershell.exe -ExecutionPolicy Bypass -Command "& '.\Tools\production_manager.ps1' -Initialize"
    echo.
    echo ✅ Production environment initialized!
    echo.
) else (
    echo ✅ Production environment already exists
    echo.
)

REM Check system resources
echo 📊 Checking system resources...
powershell.exe -ExecutionPolicy Bypass -Command "& '.\Tools\production_manager.ps1' -Monitor"
echo.

REM Launch production manager
echo 🎯 Launching Production Manager...
echo.
echo Available Commands:
echo   -Monitor        : Monitor system resources
echo   -Optimize       : Optimize production environment
echo   -BatchProcess   : Process multiple videos
echo   -GenerateReport : Generate production analytics
echo.
echo Starting Production Manager...
echo.

powershell.exe -ExecutionPolicy Bypass -WindowStyle Normal -File "Tools\production_manager.ps1"

REM If there's an error, show it
if %ERRORLEVEL% neq 0 (
    echo.
    echo ❌ Error launching Production Manager. Trying alternative method...
    echo.
    powershell.exe -ExecutionPolicy Bypass -File "Tools\production_manager.ps1"
    pause
)

echo.
echo 🎬 Production session completed.
echo.
pause
