# Audio Loop Optimizer - Enhanced Version
# Creates seamless audio loops by removing clicks, pops, and optimizing for looping
# Enhanced with quality analysis, loop detection, and advanced processing

param(
    [string]$InputAudio,
    [string]$OutputAudio = "optimized_loop.wav", 
    [double]$FadeDuration = 0.1,
    [switch]$RemoveNoise,
    [switch]$Normalize,
    [switch]$AnalyzeQuality,
    [switch]$AutoLoop,
    [switch]$Verbose,
    [switch]$Help
)

# Enhanced error handling and logging
$ErrorActionPreference = "Stop"
$LogFile = "audio_optimizer.log"

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

function Get-AudioInfo {
    param([string]$FilePath)
    
    try {
        $durationCmd = "ffprobe -v quiet -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 `"$FilePath`""
        $duration = [double](Invoke-Expression $durationCmd)
        
        $sampleRateCmd = "ffprobe -v quiet -select_streams a:0 -show_entries stream=sample_rate -of default=noprint_wrappers=1:nokey=1 `"$FilePath`""
        $sampleRate = Invoke-Expression $sampleRateCmd
        
        $channelsCmd = "ffprobe -v quiet -select_streams a:0 -show_entries stream=channels -of default=noprint_wrappers=1:nokey=1 `"$FilePath`""
        $channels = Invoke-Expression $channelsCmd
        
        $bitrateCmd = "ffprobe -v quiet -show_entries format=bit_rate -of default=noprint_wrappers=1:nokey=1 `"$FilePath`""
        $bitrate = Invoke-Expression $bitrateCmd
        
        return @{
            Duration = $duration
            SampleRate = $sampleRate
            Channels = $channels
            Bitrate = $bitrate
        }
    } catch {
        Write-Log "Failed to get audio info for: $FilePath" "WARNING"
        return $null
    }
}

function Analyze-AudioQuality {
    param([string]$FilePath)
    
    Write-Log "🔍 Analyzing audio quality..." "INFO"
    
    try {
        # Analyze audio levels
        $levelsCmd = "ffprobe -v quiet -select_streams a:0 -show_entries frame=pkt_pts_time,pkt_size -of csv=p=0 `"$FilePath`""
        $levels = Invoke-Expression $levelsCmd
        
        # Analyze frequency spectrum
        $spectrumCmd = "ffmpeg -i `"$FilePath`" -af 'asetrate=44100*1,aresample=44100,lowpass=f=8000,highpass=f=80' -f null - 2>&1"
        $spectrum = Invoke-Expression $spectrumCmd
        
        # Detect potential issues
        $issues = @()
        
        if ($levels -match "error|Error|ERROR") {
            $issues += "Audio stream errors detected"
        }
        
        if ($spectrum -match "error|Error|ERROR") {
            $issues += "Frequency analysis issues"
        }
        
        # Check file size vs duration ratio
        $fileSize = (Get-Item $FilePath).Length
        $audioInfo = Get-AudioInfo -FilePath $FilePath
        
        if ($audioInfo) {
            $expectedSize = $audioInfo.Duration * $audioInfo.SampleRate * $audioInfo.Channels * 2 / 8
            $sizeRatio = $fileSize / $expectedSize
            
            if ($sizeRatio -lt 0.8) {
                $issues += "Audio file may be compressed or corrupted"
            }
        }
        
        return @{
            Issues = $issues
            Levels = $levels
            Spectrum = $spectrum
        }
    } catch {
        Write-Log "Audio quality analysis failed: $($_.Exception.Message)" "WARNING"
        return $null
    }
}

function Find-OptimalLoopPoint {
    param([string]$FilePath, [double]$Duration)
    
    Write-Log "🔄 Finding optimal loop point..." "INFO"
    
    try {
        # Analyze audio for natural break points
        $analysisCmd = "ffprobe -v quiet -select_streams a:0 -show_entries frame=pkt_pts_time,pkt_size -of csv=p=0 `"$FilePath`""
        $frames = Invoke-Expression $analysisCmd
        
        # Look for low-energy points (potential loop points)
        $lowEnergyPoints = @()
        $frameCount = 0
        
        foreach ($frame in $frames) {
            if ($frame -match "(\d+\.\d+),(\d+)") {
                $time = [double]$matches[1]
                $size = [int]$matches[2]
                
                # Simple energy estimation based on packet size
                if ($size -lt 1000 -and $time -gt 1.0 -and $time -lt ($Duration - 1.0)) {
                    $lowEnergyPoints += $time
                }
                
                $frameCount++
                if ($frameCount -gt 1000) { break } # Limit analysis
            }
        }
        
        if ($lowEnergyPoints.Count -gt 0) {
            # Choose the point closest to the middle
            $targetTime = $Duration / 2
            $bestPoint = $lowEnergyPoints | Sort-Object { [Math]::Abs($_ - $targetTime) } | Select-Object -First 1
            
            Write-Log "✅ Optimal loop point found at: $([math]::Round($bestPoint, 2)) seconds" "INFO"
            return $bestPoint
        } else {
            Write-Log "⚠️ No optimal loop point found, using default" "WARNING"
            return $Duration / 2
        }
        
    } catch {
        Write-Log "Loop point analysis failed: $($_.Exception.Message)" "WARNING"
        return $Duration / 2
    }
}

function Build-AdvancedFilters {
    param([string]$InputPath, [double]$FadeDuration, [bool]$RemoveNoise, [bool]$Normalize, [double]$LoopPoint)
    
    $filters = @()
    
    # Add fade in/out for seamless looping
    $filters += "afade=t=in:ss=0:d=$FadeDuration"
    $filters += "afade=t=out:st=$($LoopPoint - $FadeDuration):d=$FadeDuration"
    
    # Advanced noise reduction if requested
    if ($RemoveNoise) {
        Write-Log "🔧 Adding advanced noise reduction..." "INFO"
        
        # Remove low-frequency rumble
        $filters += "highpass=f=80:width_type=q:width=0.5"
        
        # Remove high-frequency hiss
        $filters += "lowpass=f=8000:width_type=q:width=0.5"
        
        # Spectral noise reduction
        $filters += "anlmdn=s=7:p=0.002:r=0.01"
        
        # Remove DC offset
        $filters += "dcshift=shift=0:limitergain=0.02"
    }
    
    # Advanced normalization if requested
    if ($Normalize) {
        Write-Log "📊 Adding advanced normalization..." "INFO"
        
        # Dynamic range compression
        $filters += "dynaudnorm=f=500:g=31:p=0.95:m=100:s=12"
        
        # Peak normalization
        $filters += "loudnorm=I=-16:TP=-1.5:LRA=11"
        
        # Limiter to prevent clipping
        $filters += "alimiter=level_in=1:level_out=1:limit=0.8:attack=5:release=50"
    }
    
    # Add crossfade for seamless looping
    $filters += "acrossfade=d=$FadeDuration"
    
    return $filters -join ","
}

if ($Help) {
    Write-Host @"
Audio Loop Optimizer - Enhanced Version
======================================
Creates seamless audio loops by removing clicks, pops, and optimizing for looping

Parameters:
  -InputAudio     Path to input audio file
  -OutputAudio    Output file path (default: optimized_loop.wav)
  -FadeDuration   Fade in/out duration in seconds (default: 0.1)
  -RemoveNoise    Apply advanced noise reduction filters
  -Normalize      Apply advanced normalization and compression
  -AnalyzeQuality Analyze audio quality and detect issues
  -AutoLoop       Automatically find optimal loop points
  -Verbose        Enable detailed logging
  -Help           Show this help message
  
Examples:
  .\audio_loop_optimizer.ps1 -InputAudio "fire_crackling.mp3" -RemoveNoise -Normalize
  .\audio_loop_optimizer.ps1 -InputAudio "rain.wav" -FadeDuration 0.2 -OutputAudio "rain_loop.wav" -AnalyzeQuality
  .\audio_loop_optimizer.ps1 -InputAudio "ambient.mp3" -AutoLoop -RemoveNoise -Normalize -Verbose
"@
    return
}

# Initialize logging
Write-Log "=== Audio Loop Optimizer Starting ===" "INFO"
Write-Log "Version: Enhanced 2.0" "INFO"
Write-Log "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" "INFO"

# Validate FFmpeg installation
if (-not (Test-FFmpeg)) {
    Write-Log "FFmpeg is required but not found. Please install FFmpeg and add to PATH." "ERROR"
    Write-Error "FFmpeg not found. Install from https://ffmpeg.org/download.html"
    return
}

# Input validation
if (-not $InputAudio) {
    Write-Log "Missing required parameter: InputAudio" "ERROR"
    Write-Error "Please provide -InputAudio parameter. Use -Help for usage info."
    return
}

if (-not (Test-Path $InputAudio)) {
    Write-Log "Audio file not found: $InputAudio" "ERROR"
    Write-Error "Audio file not found: $InputAudio"
    return
}

Write-Log "🎵 Audio Loop Optimizer Starting..." "INFO"
Write-Log "🔊 Input: $InputAudio" "INFO"
Write-Log "📂 Output: $OutputAudio" "INFO"
Write-Log "⏱️  Fade Duration: $FadeDuration seconds" "INFO"
Write-Log "🔧 Remove Noise: $RemoveNoise" "INFO"
Write-Log "📊 Normalize: $Normalize" "INFO"
Write-Log "🔍 Analyze Quality: $AnalyzeQuality" "INFO"
Write-Log "🔄 Auto Loop: $AutoLoop" "INFO"

# Get audio information
$audioInfo = Get-AudioInfo -FilePath $InputAudio
if ($audioInfo) {
    Write-Log "📊 Audio Info:" "INFO"
    Write-Log "   Duration: $([math]::Round($audioInfo.Duration, 2)) seconds" "INFO"
    Write-Log "   Sample Rate: $($audioInfo.SampleRate) Hz" "INFO"
    Write-Log "   Channels: $($audioInfo.Channels)" "INFO"
    Write-Log "   Bitrate: $([math]::Round($audioInfo.Bitrate / 1000, 0)) kbps" "INFO"
} else {
    Write-Log "⚠️ Could not analyze audio file" "WARNING"
}

# Quality analysis if requested
if ($AnalyzeQuality) {
    $qualityReport = Analyze-AudioQuality -FilePath $InputAudio
    if ($qualityReport) {
        if ($qualityReport.Issues.Count -gt 0) {
            Write-Log "⚠️ Quality issues detected:" "WARNING"
            foreach ($issue in $qualityReport.Issues) {
                Write-Log "   - $issue" "WARNING"
            }
        } else {
            Write-Log "✅ No quality issues detected" "INFO"
        }
    }
}

# Find optimal loop point if requested
$loopPoint = $audioInfo.Duration
if ($AutoLoop -and $audioInfo) {
    $loopPoint = Find-OptimalLoopPoint -FilePath $InputAudio -Duration $audioInfo.Duration
}

# Build advanced filter chain
Write-Log "🎛️  Building advanced filter chain..." "INFO"
$filterChain = Build-AdvancedFilters -InputPath $InputAudio -FadeDuration $FadeDuration -RemoveNoise $RemoveNoise -Normalize $Normalize -LoopPoint $loopPoint

if ($Verbose) {
    Write-Log "Filter chain: $filterChain" "DEBUG"
}

# Execute FFmpeg command with advanced processing
$ffmpegCmd = @"
ffmpeg -y -i "$InputAudio" -af "$filterChain" -c:a pcm_s24le -ar 48000 -ac 2 "$OutputAudio"
"@

Write-Log "🔄 Processing audio with advanced filters..." "INFO"
if ($Verbose) { Write-Log "Command: $ffmpegCmd" "DEBUG" }

try {
    $process = Start-Process -FilePath "powershell.exe" -ArgumentList @("-Command", $ffmpegCmd) -NoNewWindow -PassThru -Wait
    
    if ($process.ExitCode -ne 0) {
        throw "FFmpeg processing failed with exit code: $($process.ExitCode)"
    }
    
    if (Test-Path $OutputAudio) {
        $inputSize = [math]::Round((Get-Item $InputAudio).Length / 1MB, 2)
        $outputSize = [math]::Round((Get-Item $OutputAudio).Length / 1MB, 2)
        
        # Analyze output quality
        $outputInfo = Get-AudioInfo -FilePath $OutputAudio
        
        Write-Log "🎉 SUCCESS! Audio optimized successfully" "INFO"
        Write-Log "📁 Optimized audio: $OutputAudio" "INFO"
        Write-Log "📏 Input size: ${inputSize} MB" "INFO"
        Write-Log "📏 Output size: ${outputSize} MB" "INFO"
        
        if ($outputInfo) {
            Write-Log "📊 Output quality:" "INFO"
            Write-Log "   Duration: $([math]::Round($outputInfo.Duration, 2)) seconds" "INFO"
            Write-Log "   Sample Rate: $($outputInfo.SampleRate) Hz" "INFO"
            Write-Log "   Channels: $($outputInfo.Channels)" "INFO"
        }
        
        Write-Log "🔄 Audio is now optimized for seamless looping!" "INFO"
        
        # Create optimization report
        $report = @{
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            InputFile = $InputAudio
            OutputFile = $OutputAudio
            FadeDuration = $FadeDuration
            RemoveNoise = $RemoveNoise
            Normalize = $Normalize
            AutoLoop = $AutoLoop
            LoopPoint = $loopPoint
            InputSizeMB = $inputSize
            OutputSizeMB = $outputSize
            Filters = $filterChain
        }
        
        $reportPath = $OutputAudio -replace '\.[^.]+$', '_optimization_report.json'
        $report | ConvertTo-Json | Set-Content $reportPath
        Write-Log "📝 Optimization report saved to: $reportPath" "INFO"
        
    } else {
        throw "Output file was not created"
    }
    
} catch {
    Write-Log "❌ Error during processing: $($_.Exception.Message)" "ERROR"
    Write-Error "❌ Processing failed: $($_.Exception.Message)"
}

Write-Log "=== Audio Loop Optimizer Finished ===" "INFO"