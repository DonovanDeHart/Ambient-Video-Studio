@echo off
echo 🎬 Ambient Video Creator - Simple Mode
echo =====================================
echo.

REM Get video file
set /p video_file="Enter your video filename (in Source-Files folder): "
if "%video_file%"=="" (
    echo ❌ Video filename is required!
    pause
    exit /b
)

REM Get audio file  
set /p audio_file="Enter your audio filename (in Source-Files folder): "
if "%audio_file%"=="" (
    echo ❌ Audio filename is required!
    pause
    exit /b
)

REM Get duration
set /p duration="Enter duration in hours (default 8): "
if "%duration%"=="" set duration=8

REM Get output name
set /p output_name="Enter output video name (without extension): "
if "%output_name%"=="" set output_name=ambient_video_%duration%hrs

echo.
echo 🎯 Creating ambient video...
echo 📹 Video: %video_file%
echo 🔊 Audio: %audio_file%
echo ⏱️ Duration: %duration% hours
echo 📂 Output: %output_name%.mp4
echo.

REM Run the PowerShell script
powershell.exe -ExecutionPolicy Bypass -File "ambient_video_creator.ps1" -VideoInput "../Source-Files/%video_file%" -AudioInput "../Source-Files/%audio_file%" -DurationHours %duration% -OutputPath "../Output/%output_name%.mp4"

echo.
echo ✅ Done! Check the Output folder for your video.
pause