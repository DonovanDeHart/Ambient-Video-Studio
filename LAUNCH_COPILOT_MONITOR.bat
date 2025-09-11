@echo off
echo 🤖 Copilot Progress Monitor - Quick Launch
echo ========================================
echo.
echo Select an option:
echo.
echo 1. Show Real-time Dashboard
echo 2. Get Current Status
echo 3. Generate Progress Report
echo 4. Run Test Operation
echo 5. Clear Monitoring History
echo 6. Open Documentation
echo.
set /p choice="Enter your choice (1-6): "

cd /d "%~dp0\Tools"

if "%choice%"=="1" (
    echo.
    echo 📊 Opening real-time dashboard...
    powershell -ExecutionPolicy Bypass -File "copilot_progress_monitor.ps1" -ShowDashboard
) else if "%choice%"=="2" (
    echo.
    echo 📋 Getting current status...
    powershell -ExecutionPolicy Bypass -File "copilot_progress_monitor.ps1" -GetStatus
    pause
) else if "%choice%"=="3" (
    echo.
    echo 📊 Generating progress report...
    powershell -ExecutionPolicy Bypass -File "copilot_progress_monitor.ps1" -GenerateReport
    echo Report generated successfully!
    pause
) else if "%choice%"=="4" (
    echo.
    echo 🧪 Running test operation with copilot monitoring...
    powershell -ExecutionPolicy Bypass -File "test_copilot_monitor.ps1" -EnableCopilotMonitoring -Duration 15
    echo Test completed!
    pause
) else if "%choice%"=="5" (
    echo.
    set /p confirm="Are you sure you want to clear monitoring history? (Y/N): "
    if /i "%confirm%"=="Y" (
        powershell -ExecutionPolicy Bypass -File "copilot_progress_monitor.ps1" -ClearHistory
        echo History cleared successfully!
    ) else (
        echo Operation cancelled.
    )
    pause
) else if "%choice%"=="6" (
    echo.
    echo 📖 Opening documentation...
    cd /d "%~dp0"
    notepad "COPILOT_MONITORING_GUIDE.md"
) else (
    echo Invalid choice. Please run the script again and select 1-6.
    pause
)

echo.
echo Thank you for using Copilot Progress Monitor! 🚀