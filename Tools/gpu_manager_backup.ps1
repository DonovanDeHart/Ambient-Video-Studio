# GPU Manager - Multi-GPU detection and optimization for video processing
# Detects and manages NVIDIA GPUs for FFmpeg acceleration

param(
    [switch]$ListGPUs,
    [switch]$GetOptimalConfig,
    [int]$TargetGPU = -1,
    [switch]$Help
)

if ($Help) {
    Write-Host @"
GPU Manager for Ambient Video Studio
===================================
Detects and optimizes NVIDIA GPU usage for video processing

Parameters:
  -ListGPUs        Show all available NVIDIA GPUs
  -GetOptimalConfig Get optimal FFmpeg configuration
  -TargetGPU       Use specific GPU (0, 1, etc.)
  
Examples:
  .\gpu_manager.ps1 -ListGPUs
  .\gpu_manager.ps1 -GetOptimalConfig
  .\gpu_manager.ps1 -TargetGPU 0
"@
    return
}

function Get-NvidiaGPUs {
    try {
        $gpuInfo = nvidia-smi --query-gpu=index,name,memory.total,memory.used,utilization.gpu,temperature.gpu --format=csv,noheader,nounits
        
        if (-not $gpuInfo) {
            Write-Host "❌ No NVIDIA GPUs detected or nvidia-smi not available" -ForegroundColor Red
            return @()
        }
        
        $gpus = @()
        foreach ($line in $gpuInfo) {
            $parts = $line.Split(',').Trim()
            if ($parts.Count -eq 6) {
                $gpus += @{
                    Index = [int]$parts[0]
                    Name = $parts[1]
                    MemoryTotal = [int]$parts[2]
                    MemoryUsed = [int]$parts[3]
                    Utilization = [int]$parts[4]
                    Temperature = [int]$parts[5]
                    MemoryFree = [int]$parts[2] - [int]$parts[3]
                    MemoryUsedPercent = [math]::Round(([int]$parts[3] / [int]$parts[2]) * 100, 1)
                }
            }
        }
        
        return $gpus
    } catch {
        Write-Host "❌ Error detecting GPUs: $($_.Exception.Message)" -ForegroundColor Red
        return @()
    }
}

function Get-OptimalGPU {
    param([array]$GPUs)
    
    if ($GPUs.Count -eq 0) {
        return $null
    }
    
    # Sort by lowest utilization, then highest free memory
    $optimal = $GPUs | Sort-Object Utilization, @{Expression={-$_.MemoryFree}} | Select-Object -First 1
    return $optimal
}

function Get-FFmpegGPUConfig {
    param([int]$GPUIndex, [string]$QualityProfile = "balanced")
    
    $configs = @{
        "fast" = @{
            hwaccel = "cuda"
            hwaccel_device = $GPUIndex
            encoder = "h264_nvenc"
            preset = "fast"
            crf = "28"
            additional = "-gpu $GPUIndex -rc:v vbr -cq:v 28 -b:v 0 -maxrate:v 50M -bufsize:v 100M"
        }
        "balanced" = @{
            hwaccel = "cuda"
            hwaccel_device = $GPUIndex
            encoder = "h264_nvenc"
            preset = "medium"
            crf = "23"
            additional = "-gpu $GPUIndex -rc:v vbr -cq:v 23 -b:v 0 -maxrate:v 30M -bufsize:v 60M -spatial_aq:v 1 -temporal_aq:v 1"
        }
        "quality" = @{
            hwaccel = "cuda"
            hwaccel_device = $GPUIndex
            encoder = "h264_nvenc"
            preset = "slow"
            crf = "20"
            additional = "-gpu $GPUIndex -rc:v vbr -cq:v 20 -b:v 0 -maxrate:v 25M -bufsize:v 50M -spatial_aq:v 1 -temporal_aq:v 1 -aq-strength:v 15"
        }
    }
    
    return $configs[$QualityProfile]
}

function Test-GPUPerformance {
    param([int]$GPUIndex)
    
    Write-Host "🧪 Testing GPU $GPUIndex performance..." -ForegroundColor Yellow
    
    # Create a small test video
    $testCmd = "ffmpeg -y -hwaccel cuda -hwaccel_device $GPUIndex -f lavfi -i testsrc=duration=10:size=1920x1080:rate=30 -c:v h264_nvenc -gpu $GPUIndex -preset fast test_gpu$GPUIndex.mp4"
    
    try {
        $startTime = Get-Date
        Invoke-Expression $testCmd *> $null
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalSeconds
        
        # Cleanup test file
        Remove-Item "test_gpu$GPUIndex.mp4" -ErrorAction SilentlyContinue
        
        Write-Host "✅ GPU $GPUIndex test completed in $([math]::Round($duration, 2)) seconds" -ForegroundColor Green
        return $duration
    } catch {
        Write-Host "❌ GPU $GPUIndex test failed: $($_.Exception.Message)" -ForegroundColor Red
        return -1
    }
}

# Main execution
$gpus = Get-NvidiaGPUs

if ($ListGPUs) {
    Write-Host "🎮 NVIDIA GPU Detection Results" -ForegroundColor Cyan
    Write-Host "=" * 50
    
    if ($gpus.Count -eq 0) {
        Write-Host "❌ No NVIDIA GPUs found" -ForegroundColor Red
        return
    }
    
    foreach ($gpu in $gpus) {
        Write-Host "🔧 GPU $($gpu.Index): $($gpu.Name)" -ForegroundColor Yellow
        Write-Host ('   Memory: {0}MB / {1}MB ({2}% used)' -f $gpu.MemoryUsed, $gpu.MemoryTotal, $gpu.MemoryUsedPercent) -ForegroundColor Gray
        Write-Host "   Free Memory: $($gpu.MemoryFree)MB" -ForegroundColor Green
        Write-Host ('   Utilization: {0}%' -f $gpu.Utilization) -ForegroundColor Gray
        Write-Host "   Temperature: $($gpu.Temperature)°C" -ForegroundColor Gray
        Write-Host ""
    }
    
    $optimal = Get-OptimalGPU -GPUs $gpus
    if ($optimal) {
        Write-Host "🚀 Recommended GPU: GPU $($optimal.Index) ($($optimal.Name))" -ForegroundColor Green
        Write-Host ('   Reason: {0}% utilization, {1}MB free memory' -f $optimal.Utilization, $optimal.MemoryFree) -ForegroundColor Gray
    }
    return
}

if ($GetOptimalConfig) {
    Write-Host "⚙️ Optimal FFmpeg Configuration" -ForegroundColor Cyan
    Write-Host "=" * 40
    
    if ($gpus.Count -eq 0) {
        Write-Host "❌ No NVIDIA GPUs found - falling back to CPU encoding" -ForegroundColor Red
        Write-Host "CPU Config: -c:v libx264 -preset medium -crf 23" -ForegroundColor Yellow
        return
    }
    
    $optimal = Get-OptimalGPU -GPUs $gpus
    $config = Get-FFmpegGPUConfig -GPUIndex $optimal.Index -QualityProfile "balanced"
    
    Write-Host "🎯 Selected GPU: $($optimal.Index) ($($optimal.Name))" -ForegroundColor Green
    Write-Host ('📊 Status: {0}% utilization, {1}MB free' -f $optimal.Utilization, $optimal.MemoryFree) -ForegroundColor Gray
    Write-Host ""
    Write-Host "🔧 FFmpeg Configuration:" -ForegroundColor Yellow
    Write-Host "   Hardware Acceleration: -hwaccel $($config.hwaccel) -hwaccel_device $($config.hwaccel_device)" -ForegroundColor Cyan
    Write-Host "   Encoder: -c:v $($config.encoder)" -ForegroundColor Cyan
    Write-Host "   Preset: -preset $($config.preset)" -ForegroundColor Cyan  
    Write-Host "   Quality: -crf $($config.crf)" -ForegroundColor Cyan
    Write-Host "   Additional: $($config.additional)" -ForegroundColor Cyan
    
    return @{
        GPU = $optimal
        Config = $config
    }
}

if ($TargetGPU -ge 0) {
    $targetGpu = $gpus | Where-Object { $_.Index -eq $TargetGPU }
    
    if (-not $targetGpu) {
        Write-Host "❌ GPU $TargetGPU not found" -ForegroundColor Red
        return
    }
    
    Write-Host "🎯 Target GPU Configuration" -ForegroundColor Cyan
    Write-Host "=" * 35
    Write-Host "🔧 GPU $($targetGpu.Index): $($targetGpu.Name)" -ForegroundColor Yellow
    Write-Host ('📊 Status: {0}% utilization, {1}MB free' -f $targetGpu.Utilization, $targetGpu.MemoryFree) -ForegroundColor Gray
    
    $config = Get-FFmpegGPUConfig -GPUIndex $TargetGPU -QualityProfile "balanced"
    Write-Host ""
    Write-Host "🔧 FFmpeg Configuration:" -ForegroundColor Yellow
    Write-Host "   -hwaccel $($config.hwaccel) -hwaccel_device $($config.hwaccel_device) -c:v $($config.encoder) -preset $($config.preset) -crf $($config.crf) $($config.additional)" -ForegroundColor Cyan
    
    return @{
        GPU = $targetGpu
        Config = $config
    }
}

# Default: Show summary
Write-Host "🎮 GPU Summary" -ForegroundColor Cyan
Write-Host "Found $($gpus.Count) NVIDIA GPU(s)" -ForegroundColor Green

if ($gpus.Count -gt 0) {
    $optimal = Get-OptimalGPU -GPUs $gpus
    Write-Host "Recommended: GPU $($optimal.Index) - $($optimal.Name)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Use -ListGPUs for detailed information" -ForegroundColor Gray
    Write-Host "Use -GetOptimalConfig for FFmpeg configuration" -ForegroundColor Gray
}