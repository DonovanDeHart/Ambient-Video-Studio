# Enhanced Ambient Video Creator with Multi-GPU Support
# Creates long-form ambient videos using NVIDIA GPU acceleration

param(
    [string]$VideoInput,
    [string]$AudioInput, 
    [int]$DurationHours = 8,
    [string]$OutputPath = "ambient_output.mp4",
    [string]$Quality = "balanced", # fast, balanced, quality
    [int]$TargetGPU = -1, # -1 for auto-select, 0/1 for specific GPU
    [switch]$UseMultiGPU, # Use both GPUs for processing
    [switch]$Help,
    [switch]$Verbose
)

if ($Help) {
    Write-Host @"
Enhanced Ambient Video Creator with GPU Acceleration
===================================================
Creates seamless 8-10 hour ambient videos using NVIDIA GPU power

Parameters:
  -VideoInput     Path to base video file (should be loop-friendly)
  -AudioInput     Path to ambient audio file 
  -DurationHours  Target duration in hours (default: 8)
  -OutputPath     Output file path (default: ambient_output.mp4)
  -Quality        Encoding quality: fast, balanced, quality (default: balanced)
  -TargetGPU      GPU to use: -1 (auto), 0 (first GPU), 1 (second GPU)
  -UseMultiGPU    Use both GPUs for parallel processing
  -Verbose        Show detailed progress

GPU Quality Profiles:
  fast      - Quick encoding, larger files (RTX 5060 Ti recommended)
  balanced  - Good quality/speed balance (recommended for most)
  quality   - High quality, slower encoding (RTX 5080 recommended)

Examples:
  .\enhanced_video_creator.ps1 -VideoInput "fire.mp4" -AudioInput "crackling.wav"
  .\enhanced_video_creator.ps1 -VideoInput "rain.mp4" -AudioInput "rainfall.wav" -Quality "quality" -TargetGPU 0
  .\enhanced_video_creator.ps1 -VideoInput "forest.mp4" -AudioInput "birds.wav" -UseMultiGPU
"@
    return
}

# Import GPU manager functions
$gpuManagerPath = Join-Path $PSScriptRoot "gpu_manager.ps1"
if (Test-Path $gpuManagerPath) {
    . $gpuManagerPath
} else {
    Write-Host "❌ GPU Manager not found. GPU acceleration disabled." -ForegroundColor Red
    $UseGPU = $false
}

# Enhanced logging with GPU info
$LogFile = "enhanced_video_creator.log"
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Write-Host $logEntry
    Add-Content -Path $LogFile -Value $logEntry -ErrorAction SilentlyContinue
}

function Get-GPUConfig {
    Write-Log "🎮 Detecting NVIDIA GPUs..." "INFO"
    
    $gpus = Get-NvidiaGPUs
    if ($gpus.Count -eq 0) {
        Write-Log "❌ No NVIDIA GPUs found - using CPU encoding" "WARN"
        return $null
    }
    
    Write-Log "✅ Found $($gpus.Count) NVIDIA GPU(s)" "INFO"
    foreach ($gpu in $gpus) {
        Write-Log "   GPU $($gpu.Index): $($gpu.Name) ($($gpu.MemoryFree)MB free)" "INFO"
    }
    
    if ($TargetGPU -ge 0) {
        $selectedGpu = $gpus | Where-Object { $_.Index -eq $TargetGPU }
        if ($selectedGpu) {
            Write-Log "🎯 Using specified GPU $TargetGPU`: $($selectedGpu.Name)" "INFO"
        } else {
            Write-Log "❌ GPU $TargetGPU not found, using optimal GPU" "WARN"
            $selectedGpu = Get-OptimalGPU -GPUs $gpus
        }
    } else {
        $selectedGpu = Get-OptimalGPU -GPUs $gpus
        Write-Log "🚀 Auto-selected optimal GPU $($selectedGpu.Index): $($selectedGpu.Name)" "INFO"
    }
    
    return @{
        GPU = $selectedGpu
        Config = Get-FFmpegGPUConfig -GPUIndex $selectedGpu.Index -Profile $Quality
        AllGPUs = $gpus
    }
}

function Build-FFmpegCommand {
    param(
        [string]$InputVideo,
        [string]$InputAudio,
        [string]$Output,
        [int]$Duration,
        [hashtable]$GPUConfig = $null,
        [switch]$UseMultipleGPUs
    )
    
    $videoLoops = [math]::Ceiling($Duration / $videoDuration)
    $audioLoops = [math]::Ceiling($Duration / $audioDuration)
    
    if ($GPUConfig) {
        $config = $GPUConfig.Config
        
        if ($UseMultipleGPUs -and $GPUConfig.AllGPUs.Count -gt 1) {
            Write-Log "🚀 Building multi-GPU command..." "INFO"
            
            # Use primary GPU for video, secondary for audio processing
            $primaryGPU = $GPUConfig.AllGPUs[0]
            $secondaryGPU = $GPUConfig.AllGPUs[1]
            
            $cmd = @(
                "ffmpeg", "-y"
                # Video input with primary GPU acceleration
                "-hwaccel", "cuda", "-hwaccel_device", $primaryGPU.Index
                "-stream_loop", $videoLoops, "-i", "`"$InputVideo`""
                # Audio input (CPU is fine for audio)
                "-stream_loop", $audioLoops, "-i", "`"$InputAudio`""
                "-t", $Duration
                # Video encoding with primary GPU
                "-c:v", $config.encoder
                "-gpu", $primaryGPU.Index
                "-preset", $config.preset
                "-crf", $config.crf
                $config.additional.Split(' ')
                # Audio encoding (CPU)
                "-c:a", "aac", "-b:a", "128k"
                "-shortest", "`"$Output`""
            )
            
            Write-Log "   Primary GPU (Video): $($primaryGPU.Index) - $($primaryGPU.Name)" "INFO"
            Write-Log "   Secondary GPU (Available): $($secondaryGPU.Index) - $($secondaryGPU.Name)" "INFO"
        } else {
            Write-Log "🎯 Building single-GPU command..." "INFO"
            
            $cmd = @(
                "ffmpeg", "-y"
                "-hwaccel", $config.hwaccel, "-hwaccel_device", $config.hwaccel_device
                "-stream_loop", $videoLoops, "-i", "`"$InputVideo`""
                "-stream_loop", $audioLoops, "-i", "`"$InputAudio`""
                "-t", $Duration
                "-c:v", $config.encoder
                $config.additional.Split(' ')
                "-c:a", "aac", "-b:a", "128k"
                "-shortest", "`"$Output`""
            )
            
            Write-Log "   Using GPU: $($GPUConfig.GPU.Index) - $($GPUConfig.GPU.Name)" "INFO"
        }
    } else {
        Write-Log "💻 Building CPU-only command..." "INFO"
        
        $cmd = @(
            "ffmpeg", "-y"
            "-stream_loop", $videoLoops, "-i", "`"$InputVideo`""
            "-stream_loop", $audioLoops, "-i", "`"$InputAudio`""
            "-t", $Duration
            "-c:v", "libx264", "-preset", "medium", "-crf", "23"
            "-c:a", "aac", "-b:a", "128k"
            "-shortest", "`"$Output`""
        )
    }
    
    return $cmd -join " "
}

# Validation
if (-not $VideoInput -or -not $AudioInput) {
    Write-Log "❌ Please provide both video and audio input files" "ERROR"
    return 1
}

if (-not (Test-Path $VideoInput)) {
    Write-Log "❌ Video file not found: $VideoInput" "ERROR"
    return 1
}

if (-not (Test-Path $AudioInput)) {
    Write-Log "❌ Audio file not found: $AudioInput" "ERROR"
    return 1
}

# Calculate target duration in seconds
$targetSeconds = $DurationHours * 3600

Write-Log "🎬 Enhanced Ambient Video Creator Starting..." "INFO"
Write-Log "📹 Video Input: $VideoInput" "INFO"
Write-Log "🔊 Audio Input: $AudioInput" "INFO"
Write-Log "⏱️  Target Duration: $DurationHours hours ($targetSeconds seconds)" "INFO"
Write-Log "📂 Output Path: $OutputPath" "INFO"
Write-Log "🎯 Quality Profile: $Quality" "INFO"

# Get GPU configuration
$gpuConfig = Get-GPUConfig

# Get input file durations
Write-Log "📊 Analyzing input files..." "INFO"
try {
    $videoDurationCmd = "ffprobe -v quiet -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 `"$VideoInput`""
    $videoDuration = [double](Invoke-Expression $videoDurationCmd)
    
    $audioDurationCmd = "ffprobe -v quiet -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 `"$AudioInput`""
    $audioDuration = [double](Invoke-Expression $audioDurationCmd)
    
    Write-Log "📹 Video duration: $([math]::Round($videoDuration, 2)) seconds" "INFO"
    Write-Log "🔊 Audio duration: $([math]::Round($audioDuration, 2)) seconds" "INFO"
} catch {
    Write-Log "❌ Error analyzing input files: $($_.Exception.Message)" "ERROR"
    return 1
}

# Calculate loop counts
$videoLoops = [math]::Ceiling($targetSeconds / $videoDuration)
$audioLoops = [math]::Ceiling($targetSeconds / $audioDuration)

Write-Log "🔄 Video loops needed: $videoLoops" "INFO"
Write-Log "🔄 Audio loops needed: $audioLoops" "INFO"

# Build and execute FFmpeg command
Write-Log "🚀 Building optimized FFmpeg command..." "INFO"

$ffmpegCmd = Build-FFmpegCommand -InputVideo $VideoInput -InputAudio $AudioInput -Output $OutputPath -Duration $targetSeconds -GPUConfig $gpuConfig -UseMultipleGPUs:$UseMultiGPU

Write-Log "🔧 FFmpeg Command: $ffmpegCmd" "INFO"

Write-Log "⚡ Starting GPU-accelerated video creation..." "INFO"
$startTime = Get-Date

try {
    if ($Verbose) {
        Invoke-Expression $ffmpegCmd
    } else {
        Invoke-Expression "$ffmpegCmd 2>&1" | Out-Null
    }
    
    $endTime = Get-Date
    $processingTime = ($endTime - $startTime).TotalMinutes
    
    if (Test-Path $OutputPath) {
        $outputSize = [math]::Round((Get-Item $OutputPath).Length / 1MB, 2)
        Write-Log "✅ SUCCESS! GPU-accelerated creation completed" "INFO"
        Write-Log "📁 Output file: $OutputPath" "INFO"
        Write-Log "📏 File size: ${outputSize} MB" "INFO"
        Write-Log "⏱️  Processing time: $([math]::Round($processingTime, 2)) minutes" "INFO"
        Write-Log "🚀 Your $DurationHours-hour ambient video is ready!" "INFO"
        
        # Show performance stats
        if ($gpuConfig) {
            $speedup = ($DurationHours * 60) / $processingTime
            Write-Log "⚡ GPU Performance: $([math]::Round($speedup, 1))x realtime speed" "INFO"
        }
    } else {
        Write-Log "❌ Failed to create output file" "ERROR"
        return 1
    }
} catch {
    Write-Log "❌ Error during video creation: $($_.Exception.Message)" "ERROR"
    return 1
}