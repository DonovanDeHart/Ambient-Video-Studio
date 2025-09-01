# Ambient Video Creator - PowerShell Script
# Creates long-form ambient videos with seamless loops
# Enhanced with error handling, validation, and progress tracking

param(
    [string]$VideoInput,
    [string]$AudioInput, 
    [int]$DurationHours = 8,
    [string]$OutputPath = "ambient_output.mp4",
    [switch]$Help,
    [switch]$Verbose,
    [switch]$SkipValidation
)

# Enhanced error handling and logging
$ErrorActionPreference = "Stop"
$LogFile = "ambient_video_creator.log"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Write-Host $logEntry
    Add-Content -Path $LogFile -Value $logEntry -ErrorAction SilentlyContinue
}

function Test-FFmpeg {
    try {
        $null = Get-Command ffmpeg -ErrorAction Stop
        $null = Get-Command ffprobe -ErrorAction Stop
        return $true
    } catch {
        Write-Log "FFmpeg not found in PATH" "ERROR"
        return $false
    }
}

function Test-FileIntegrity {
    param([string]$FilePath, [string]$FileType)
    
    if (-not (Test-Path $FilePath)) {
        throw "File not found: $FilePath"
    }
    
    $file = Get-Item $FilePath
    if ($file.Length -eq 0) {
        throw "File is empty: $FilePath"
    }
    
    # Test if file is readable
    try {
        $null = Get-Item $FilePath -ErrorAction Stop
    } catch {
        throw "File is not accessible: $FilePath"
    }
    
    Write-Log "File integrity check passed: $FilePath" "INFO"
    return $true
}

function Get-MediaInfo {
    param([string]$FilePath)
    
    try {
        $durationCmd = "ffprobe -v quiet -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 `"$FilePath`""
        $duration = [double](Invoke-Expression $durationCmd)
        
        $resolutionCmd = "ffprobe -v quiet -select_streams v:0 -show_entries stream=width,height -of default=noprint_wrappers=1:nokey=1 `"$FilePath`""
        $resolution = Invoke-Expression $resolutionCmd
        
        $audioCmd = "ffprobe -v quiet -select_streams a:0 -show_entries stream=sample_rate,channels -of default=noprint_wrappers=1:nokey=1 `"$FilePath`""
        $audio = Invoke-Expression $audioCmd
        
        return @{
            Duration = $duration
            Resolution = $resolution
            Audio = $audio
        }
    } catch {
        Write-Log "Failed to get media info for: $FilePath" "WARNING"
        return $null
    }
}

function Optimize-FFmpegCommand {
    param([string]$InputPath, [string]$OutputPath, [int]$Duration, [string]$Type)
    
    # Memory-optimized FFmpeg commands
    $preset = "medium"
    $crf = "23"
    $threads = [Environment]::ProcessorCount
    
    switch ($Type) {
        "video" {
            return @"
ffmpeg -y -stream_loop -1 -i "$InputPath" -t $Duration -c:v libx264 -preset $preset -crf $crf -pix_fmt yuv420p -threads $threads -movflags +faststart "$OutputPath"
"@
        }
        "audio" {
            return @"
ffmpeg -y -stream_loop -1 -i "$InputPath" -t $Duration -c:a pcm_s16le -ar 48000 -ac 2 "$OutputPath"
"@
        }
        "combine" {
            return @"
ffmpeg -y -i "$InputPath" -i "$OutputPath" -c:v copy -c:a aac -b:a 192k -movflags +faststart -map 0:v:0 -map 1:a:0 "$OutputPath"
"@
        }
    }
}

if ($Help) {
    Write-Host @"
Ambient Video Creator - Enhanced Version
=======================================
Creates seamless looping ambient videos for YouTube with advanced features

Parameters:
  -VideoInput     Path to base video file (should be loop-friendly)
  -AudioInput     Path to ambient audio file 
  -DurationHours  Target duration in hours (default: 8)
  -OutputPath     Output file path (default: ambient_output.mp4)
  -Verbose        Enable detailed logging
  -SkipValidation Skip file validation (use with caution)
  -Help           Show this help message

Examples:
  .\ambient_video_creator.ps1 -VideoInput "fireplace.mp4" -AudioInput "crackling.wav" -DurationHours 10
  .\ambient_video_creator.ps1 -VideoInput "rain_window.mp4" -AudioInput "rain_sounds.mp3" -DurationHours 8 -Verbose
"@
    return
}

# Initialize logging
Write-Log "=== Ambient Video Creator Starting ===" "INFO"
Write-Log "Version: Enhanced 2.0" "INFO"
Write-Log "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" "INFO"

# Validate FFmpeg installation
if (-not (Test-FFmpeg)) {
    Write-Log "FFmpeg is required but not found. Please install FFmpeg and add to PATH." "ERROR"
    Write-Error "FFmpeg not found. Install from https://ffmpeg.org/download.html"
    return
}

# Input validation
if (-not $VideoInput -or -not $AudioInput) {
    Write-Log "Missing required parameters: VideoInput and AudioInput" "ERROR"
    Write-Error "Please provide both -VideoInput and -AudioInput parameters. Use -Help for usage info."
    return
}

# File validation (unless skipped)
if (-not $SkipValidation) {
    try {
        Test-FileIntegrity -FilePath $VideoInput -FileType "Video"
        Test-FileIntegrity -FilePath $AudioInput -FileType "Audio"
    } catch {
        Write-Log "File validation failed: $($_.Exception.Message)" "ERROR"
        Write-Error $_.Exception.Message
        return
    }
}

# Calculate target duration in seconds
$targetSeconds = $DurationHours * 3600

Write-Log "🎬 Ambient Video Creator Starting..." "INFO"
Write-Log "📹 Video Input: $VideoInput" "INFO"
Write-Log "🔊 Audio Input: $AudioInput" "INFO"
Write-Log "⏱️  Target Duration: $DurationHours hours ($targetSeconds seconds)" "INFO"
Write-Log "📂 Output Path: $OutputPath" "INFO"

# Get media information
Write-Log "📊 Analyzing input files..." "INFO"
$videoInfo = Get-MediaInfo -FilePath $VideoInput
$audioInfo = Get-MediaInfo -FilePath $AudioInput

if ($videoInfo) {
    Write-Log "📹 Video duration: $([math]::Round($videoInfo.Duration, 2)) seconds" "INFO"
    Write-Log "📹 Video resolution: $($videoInfo.Resolution)" "INFO"
} else {
    Write-Log "⚠️ Could not analyze video file" "WARNING"
}

if ($audioInfo) {
    Write-Log "🔊 Audio duration: $([math]::Round($audioInfo.Duration, 2)) seconds" "INFO"
    Write-Log "🔊 Audio info: $($audioInfo.Audio)" "INFO"
} else {
    Write-Log "⚠️ Could not analyze audio file" "WARNING"
}

# Calculate loop counts
$videoLoops = [math]::Ceiling($targetSeconds / $videoInfo.Duration)
$audioLoops = [math]::Ceiling($targetSeconds / $audioInfo.Duration)

Write-Log "🔄 Video loops needed: $videoLoops" "INFO"
Write-Log "🔄 Audio loops needed: $audioLoops" "INFO"

# Create temporary directory
$tempDir = "temp_ambient_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
Write-Log "📁 Created temporary directory: $tempDir" "INFO"

try {
    # Create seamless video loop
    Write-Log "🎬 Creating seamless video loop..." "INFO"
    $videoLoopPath = Join-Path $tempDir "temp_video_loop.mp4"
    
    $videoLoopCmd = Optimize-FFmpegCommand -InputPath $VideoInput -OutputPath $videoLoopPath -Duration $targetSeconds -Type "video"
    
    Write-Log "Executing video loop creation..." "INFO"
    if ($Verbose) { Write-Log "Command: $videoLoopCmd" "DEBUG" }
    
    $videoProcess = Start-Process -FilePath "powershell.exe" -ArgumentList @("-Command", $videoLoopCmd) -NoNewWindow -PassThru -Wait
    
    if ($videoProcess.ExitCode -ne 0) {
        throw "Video loop creation failed with exit code: $($videoProcess.ExitCode)"
    }
    
    if (-not (Test-Path $videoLoopPath)) {
        throw "Video loop file was not created"
    }
    
    Write-Log "✅ Video loop created successfully" "INFO"
    
    # Create seamless audio loop
    Write-Log "🔊 Creating seamless audio loop..." "INFO"
    $audioLoopPath = Join-Path $tempDir "temp_audio_loop.wav"
    
    $audioLoopCmd = Optimize-FFmpegCommand -InputPath $AudioInput -OutputPath $audioLoopPath -Duration $targetSeconds -Type "audio"
    
    Write-Log "Executing audio loop creation..." "INFO"
    if ($Verbose) { Write-Log "Command: $audioLoopCmd" "DEBUG" }
    
    $audioProcess = Start-Process -FilePath "powershell.exe" -ArgumentList @("-Command", $audioLoopCmd) -NoNewWindow -PassThru -Wait
    
    if ($audioProcess.ExitCode -ne 0) {
        throw "Audio loop creation failed with exit code: $($audioProcess.ExitCode)"
    }
    
    if (-not (Test-Path $audioLoopPath)) {
        throw "Audio loop file was not created"
    }
    
    Write-Log "✅ Audio loop created successfully" "INFO"
    
    # Combine video and audio
    Write-Log "🎯 Combining video and audio..." "INFO"
    $finalOutput = Join-Path $tempDir "temp_final.mp4"
    
    $combineCmd = Optimize-FFmpegCommand -InputPath $videoLoopPath -OutputPath $finalOutput -Duration $targetSeconds -Type "combine"
    
    Write-Log "Executing final combination..." "INFO"
    if ($Verbose) { Write-Log "Command: $combineCmd" "DEBUG" }
    
    $combineProcess = Start-Process -FilePath "powershell.exe" -ArgumentList @("-Command", $combineCmd) -NoNewWindow -PassThru -Wait
    
    if ($combineProcess.ExitCode -ne 0) {
        throw "Final combination failed with exit code: $($combineProcess.ExitCode)"
    }
    
    # Move final file to output location
    if (Test-Path $finalOutput) {
        $outputDir = Split-Path $OutputPath -Parent
        if (-not (Test-Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }
        
        Move-Item -Path $finalOutput -Destination $OutputPath -Force
        Write-Log "✅ Final video moved to: $OutputPath" "INFO"
    } else {
        throw "Final output file was not created"
    }
    
    # Final validation
    if (Test-Path $OutputPath) {
        $outputSize = [math]::Round((Get-Item $OutputPath).Length / 1MB, 2)
        $outputDuration = Get-MediaInfo -FilePath $OutputPath
        
        Write-Log "🎉 SUCCESS! Ambient video created successfully" "INFO"
        Write-Log "📁 Output file: $OutputPath" "INFO"
        Write-Log "📏 File size: ${outputSize} MB" "INFO"
        Write-Log "⏱️ Duration: $DurationHours hours" "INFO"
        if ($outputDuration) {
            Write-Log "⏱️ Actual duration: $([math]::Round($outputDuration.Duration / 3600, 2)) hours" "INFO"
        }
        Write-Log "🚀 Your ambient video is ready for YouTube!" "INFO"
        
        # Create metadata file
        $metadata = @{
            Created = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            VideoInput = $VideoInput
            AudioInput = $AudioInput
            DurationHours = $DurationHours
            OutputPath = $OutputPath
            FileSizeMB = $outputSize
            VideoLoops = $videoLoops
            AudioLoops = $audioLoops
            ProcessingTime = (Get-Date) - (Get-Date).AddSeconds(-$DurationHours)
        }
        
        $metadataPath = $OutputPath -replace '\.mp4$', '_metadata.json'
        $metadata | ConvertTo-Json | Set-Content $metadataPath
        Write-Log "📝 Metadata saved to: $metadataPath" "INFO"
        
    } else {
        throw "Final output file validation failed"
    }
    
} catch {
    Write-Log "❌ Error during processing: $($_.Exception.Message)" "ERROR"
    Write-Error "❌ Processing failed: $($_.Exception.Message)"
} finally {
    # Cleanup temporary files
    Write-Log "🧹 Cleaning up temporary files..." "INFO"
    try {
        if (Test-Path $tempDir) {
            Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            Write-Log "✅ Temporary files cleaned up" "INFO"
        }
    } catch {
        Write-Log "⚠️ Failed to clean up temporary files: $($_.Exception.Message)" "WARNING"
    }
}

Write-Log "=== Ambient Video Creator Finished ===" "INFO"