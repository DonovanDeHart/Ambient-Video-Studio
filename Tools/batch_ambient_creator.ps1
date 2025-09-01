# Batch Ambient Video Creator - Enhanced Version
# Processes multiple video/audio combinations for ambient video creation
# Enhanced with smart scheduling, resource management, and progress tracking

param(
    [string]$ConfigFile = "ambient_config.json",
    [int]$MaxConcurrent = 1,
    [switch]$SkipExisting,
    [switch]$ValidateOnly,
    [switch]$Verbose,
    [switch]$Help
)

# Enhanced error handling and logging
$ErrorActionPreference = "Stop"
$LogFile = "batch_creator.log"

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

function Test-SystemResources {
    Write-Log "🔍 Checking system resources..." "INFO"
    
    # Check available disk space
    $outputDir = Join-Path $PSScriptRoot "Output"
    if (Test-Path $outputDir) {
        $drive = (Get-Item $outputDir).PSDrive
        $freeSpaceGB = [math]::Round($drive.Free / 1GB, 2)
        $totalSpaceGB = [math]::Round($drive.Used / 1GB, 2)
        
        Write-Log "💾 Disk space: ${freeSpaceGB}GB free of ${totalSpaceGB}GB total" "INFO"
        
        if ($freeSpaceGB -lt 10) {
            Write-Log "⚠️ Low disk space warning: Only ${freeSpaceGB}GB available" "WARNING"
        }
    }
    
    # Check available memory
    $memory = Get-CimInstance -ClassName Win32_OperatingSystem
    $freeMemoryGB = [math]::Round($memory.FreePhysicalMemory / 1MB, 2)
    $totalMemoryGB = [math]::Round($memory.TotalVisibleMemorySize / 1MB, 2)
    
    Write-Log "🧠 Memory: ${freeMemoryGB}GB free of ${totalMemoryGB}GB total" "INFO"
    
    # Check CPU cores
    $cpuCores = (Get-WmiObject -Class Win32_Processor).NumberOfCores
    Write-Log "🖥️ CPU cores: $cpuCores" "INFO"
    
    return @{
        DiskSpaceGB = $freeSpaceGB
        MemoryGB = $freeMemoryGB
        CPUCores = $cpuCores
    }
}

function Estimate-ProcessingTime {
    param([object]$Project, [hashtable]$SystemResources)
    
    # Rough estimation based on duration and system resources
    $baseTimePerHour = 300 # 5 minutes per hour of video (rough estimate)
    $estimatedSeconds = $Project.duration * $baseTimePerHour
    
    # Adjust based on system resources
    if ($SystemResources.MemoryGB -lt 4) {
        $estimatedSeconds *= 1.5 # Slower with low memory
    }
    
    if ($SystemResources.CPUCores -lt 4) {
        $estimatedSeconds *= 1.3 # Slower with fewer cores
    }
    
    return [math]::Round($estimatedSeconds / 60, 1) # Return in minutes
}

function Validate-Project {
    param([object]$Project, [int]$ProjectNumber, [int]$TotalProjects)
    
    Write-Log "🔍 Validating project $ProjectNumber/$TotalProjects`: $($Project.name)" "INFO"
    
    $errors = @()
    $warnings = @()
    
    # Check required fields
    if (-not $Project.name) { $errors += "Missing project name" }
    if (-not $Project.video) { $errors += "Missing video file path" }
    if (-not $Project.audio) { $errors += "Missing audio file path" }
    if (-not $Project.duration) { $errors += "Missing duration" }
    if (-not $Project.output) { $errors += "Missing output path" }
    
    # Validate duration
    if ($Project.duration -lt 1 -or $Project.duration -gt 24) {
        $errors += "Duration must be between 1 and 24 hours"
    }
    
    # Check input files
    if ($Project.video -and -not (Test-Path $Project.video)) {
        $errors += "Video file not found: $($Project.video)"
    }
    
    if ($Project.audio -and -not (Test-Path $Project.audio)) {
        $errors += "Audio file not found: $($Project.audio)"
    }
    
    # Check output path
    $outputDir = Split-Path $Project.output -Parent
    if ($outputDir -and -not (Test-Path $outputDir)) {
        $warnings += "Output directory will be created: $outputDir"
    }
    
    # Check if output already exists
    if (Test-Path $Project.output) {
        if ($SkipExisting) {
            $warnings += "Output file exists, will be skipped"
        } else {
            $warnings += "Output file exists, will be overwritten"
        }
    }
    
    # Display results
    if ($errors.Count -gt 0) {
        Write-Log "❌ Validation errors:" "ERROR"
        foreach ($err in $errors) {
            Write-Log "   - $err" "ERROR"
        }
        return $false
    }
    
    if ($warnings.Count -gt 0) {
        Write-Log "⚠️ Validation warnings:" "WARNING"
        foreach ($warning in $warnings) {
            Write-Log "   - $warning" "WARNING"
        }
    }
    
    Write-Log "✅ Project validation passed" "INFO"
    return $true
}

function Create-ProjectQueue {
    param([object[]]$Projects, [hashtable]$SystemResources)
    
    Write-Log "📋 Creating optimized project queue..." "INFO"
    
    # Sort projects by priority (duration, file size, etc.)
    $prioritizedProjects = $Projects | Sort-Object { $_.duration } -Descending
    
    # Estimate processing time for each project
    foreach ($project in $prioritizedProjects) {
        $project | Add-Member -NotePropertyName "EstimatedMinutes" -NotePropertyValue (Estimate-ProcessingTime -Project $project -SystemResources $SystemResources)
        $project | Add-Member -NotePropertyName "Status" -NotePropertyValue "Pending"
        $project | Add-Member -NotePropertyName "StartTime" -NotePropertyValue $null
        $project | Add-Member -NotePropertyName "EndTime" -NotePropertyValue $null
        $project | Add-Member -NotePropertyName "Errors" -NotePropertyValue @()
    }
    
    # Calculate total estimated time
    $totalMinutes = ($prioritizedProjects | Measure-Object -Property EstimatedMinutes -Sum).Sum
    $totalHours = [math]::Round($totalMinutes / 60, 1)
    
    Write-Log "⏱️ Total estimated processing time: ${totalMinutes} minutes (${totalHours} hours)" "INFO"
    
    return $prioritizedProjects
}

function Process-Project {
    param([object]$Project, [int]$ProjectNumber, [int]$TotalProjects)
    
    $startTime = Get-Date
    $Project.StartTime = $startTime
    $Project.Status = "Processing"
    
    Write-Log "🎬 Processing project $ProjectNumber/$TotalProjects`: $($Project.name)" "INFO"
    Write-Log "📹 Video: $($Project.video)" "INFO"
    Write-Log "🔊 Audio: $($Project.audio)" "INFO"
    Write-Log "⏱️ Duration: $($Project.duration) hours" "INFO"
    Write-Log "📂 Output: $($Project.output)" "INFO"
    Write-Log "⏱️ Estimated time: $($Project.EstimatedMinutes) minutes" "INFO"
    
    try {
        # Create output directory if needed
        $outputDir = Split-Path $Project.output -Parent
        if ($outputDir -and -not (Test-Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
            Write-Log "📁 Created output directory: $outputDir" "INFO"
        }
        
        # Check if output already exists and should be skipped
        if (Test-Path $Project.output -and $SkipExisting) {
            Write-Log "⏭️ Skipping existing output file: $($Project.output)" "INFO"
            $Project.Status = "Skipped"
            return $true
        }
        
        # Run ambient video creator
        $scriptPath = Join-Path $PSScriptRoot "ambient_video_creator.ps1"
        $arguments = @(
            "-VideoInput", $Project.video
            "-AudioInput", $Project.audio
            "-DurationHours", $Project.duration
            "-OutputPath", $Project.output
        )
        
        if ($Verbose) {
            $arguments += "-Verbose"
        }
        
        Write-Log "🔄 Starting video creation..." "INFO"
        $process = Start-Process -FilePath "powershell.exe" -ArgumentList @("-ExecutionPolicy", "Bypass", "-File", $scriptPath) + $arguments -NoNewWindow -PassThru -Wait
        
        if ($process.ExitCode -eq 0) {
            if (Test-Path $Project.output) {
                $endTime = Get-Date
                $Project.EndTime = $endTime
                $Project.Status = "Completed"
                
                $actualMinutes = [math]::Round(($endTime - $startTime).TotalMinutes, 1)
                $outputSize = [math]::Round((Get-Item $Project.output).Length / 1MB, 2)
                
                Write-Log "✅ Project completed successfully!" "INFO"
                Write-Log "⏱️ Actual processing time: ${actualMinutes} minutes" "INFO"
                Write-Log "📏 Output file size: ${outputSize} MB" "INFO"
                
                return $true
            } else {
                throw "Output file was not created"
            }
        } else {
            throw "Video creation failed with exit code: $($process.ExitCode)"
        }
        
    } catch {
        $endTime = Get-Date
        $Project.EndTime = $endTime
        $Project.Status = "Failed"
        $Project.Errors += $_.Exception.Message
        
        Write-Log "❌ Project failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

if ($Help) {
    Write-Host @"
Batch Ambient Video Creator - Enhanced Version
============================================
Creates multiple ambient videos from a configuration file with smart scheduling

Parameters:
  -ConfigFile     JSON configuration file (default: ambient_config.json)
  -MaxConcurrent  Maximum concurrent processes (default: 1)
  -SkipExisting   Skip projects with existing output files
  -ValidateOnly   Only validate configuration without processing
  -Verbose        Enable detailed logging
  -Help           Show this help message

Configuration File Format:
{
  "projects": [
    {
      "name": "Cozy Fireplace",
      "video": "fireplace.mp4", 
      "audio": "crackling.wav",
      "duration": 8,
      "output": "fireplace_8hrs.mp4"
    }
  ]
}

Examples:
  .\batch_ambient_creator.ps1 -ConfigFile "my_ambient_videos.json" -Verbose
  .\batch_ambient_creator.ps1 -ConfigFile "config.json" -SkipExisting -MaxConcurrent 2
  .\batch_ambient_creator.ps1 -ConfigFile "config.json" -ValidateOnly
"@
    return
}

# Initialize logging
Write-Log "=== Batch Ambient Video Creator Starting ===" "INFO"
Write-Log "Version: Enhanced 2.0" "INFO"
Write-Log "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" "INFO"
Write-Log "Configuration: $ConfigFile" "INFO"
Write-Log "Max Concurrent: $MaxConcurrent" "INFO"
Write-Log "Skip Existing: $SkipExisting" "INFO"
Write-Log "Validate Only: $ValidateOnly" "INFO"

# Validate FFmpeg installation
if (-not (Test-FFmpeg)) {
    Write-Log "FFmpeg is required but not found. Please install FFmpeg and add to PATH." "ERROR"
    Write-Error "FFmpeg not found. Install from https://ffmpeg.org/download.html"
    return
}

# Check configuration file
if (-not (Test-Path $ConfigFile)) {
    Write-Log "📝 Configuration file not found. Creating example: $ConfigFile" "INFO"
    
    $exampleConfig = @{
        projects = @(
            @{
                name = "Cozy Fireplace"
                video = "fireplace.mp4"
                audio = "fire_crackling.wav"
                duration = 8
                output = "fireplace_8hrs.mp4"
            },
            @{
                name = "Rainy Cottage"
                video = "rain_window.mp4" 
                audio = "rain_sounds.mp3"
                duration = 10
                output = "rain_cottage_10hrs.mp4"
            },
            @{
                name = "Forest Night"
                video = "forest_cabin.mp4"
                audio = "crickets_frogs.wav"
                duration = 8
                output = "forest_night_8hrs.mp4"
            }
        )
    }
    
    $exampleConfig | ConvertTo-Json -Depth 3 | Set-Content $ConfigFile
    Write-Log "✅ Example configuration created: $ConfigFile" "INFO"
    Write-Log "📝 Edit the file with your video/audio paths, then run the script again." "INFO"
    return
}

# Load configuration
try {
    $config = Get-Content $ConfigFile | ConvertFrom-Json
    Write-Log "✅ Configuration loaded successfully" "INFO"
} catch {
    Write-Log "❌ Failed to parse configuration file: $ConfigFile" "ERROR"
    Write-Error "❌ Failed to parse configuration file: $ConfigFile"
    return
}

# Validate configuration structure
if (-not $config.projects -or $config.projects.Count -eq 0) {
    Write-Log "❌ No projects found in configuration file" "ERROR"
    Write-Error "❌ No projects found in configuration file"
    return
}

$totalProjects = $config.projects.Count
Write-Log "📊 Projects to process: $totalProjects" "INFO"

# Check system resources
$systemResources = Test-SystemResources

# Validate all projects first
Write-Log "🔍 Validating all projects..." "INFO"
$validProjects = 0
$invalidProjects = 0

foreach ($i in 0..($totalProjects - 1)) {
    $project = $config.projects[$i]
    $projectNumber = $i + 1
    
    if (Validate-Project -Project $project -ProjectNumber $projectNumber -TotalProjects $totalProjects) {
        $validProjects++
    } else {
        $invalidProjects++
    }
}

Write-Log "📊 Validation results: $validProjects valid, $invalidProjects invalid" "INFO"

if ($invalidProjects -gt 0) {
    Write-Log "⚠️ Some projects failed validation. Fix issues before processing." "WARNING"
    if (-not $ValidateOnly) {
        $response = Read-Host "Continue with processing? (y/n)"
        if ($response -notlike "y*") {
            Write-Log "Processing cancelled by user" "INFO"
            return
        }
    }
}

if ($ValidateOnly) {
    Write-Log "✅ Validation complete. Use -ValidateOnly:$false to process projects." "INFO"
    return
}

# Create optimized project queue
$projectQueue = Create-ProjectQueue -Projects $config.projects -SystemResources $systemResources

# Process projects
$successCount = 0
$failCount = 0
$skipCount = 0

Write-Log "🚀 Starting batch processing..." "INFO"
Write-Log "=" * 50

foreach ($i in 0..($projectQueue.Count - 1)) {
    $project = $projectQueue[$i]
    $projectNumber = $i + 1
    
    # Check if project should be skipped
    if ($project.Status -eq "Skipped") {
        $skipCount++
        continue
    }
    
    # Process the project
    $result = Process-Project -Project $project -ProjectNumber $projectNumber -TotalProjects $totalProjects
    
    if ($result) {
        $successCount++
    } else {
        $failCount++
    }
    
    # Progress update
    $completed = $successCount + $failCount + $skipCount
    $remaining = $totalProjects - $completed
    $progressPercent = [math]::Round(($completed / $totalProjects) * 100, 1)
    
    Write-Log "📊 Progress: $completed/$totalProjects completed ($remaining remaining) - $progressPercent%" "INFO"
    Write-Log "✅ Success: $successCount | ❌ Failed: $failCount | ⏭️ Skipped: $skipCount" "INFO"
    
    # Add delay between projects to prevent resource conflicts
    if ($i -lt ($projectQueue.Count - 1)) {
        Start-Sleep -Seconds 2
    }
}

# Final summary
Write-Log "=" * 50
Write-Log "🎬 Batch Processing Complete!" "INFO"
Write-Log "✅ Successful: $successCount projects" "INFO"
Write-Log "❌ Failed: $failCount projects" "INFO"
Write-Log "⏭️ Skipped: $skipCount projects" "INFO"

if ($failCount -eq 0) {
    Write-Log "🎉 All projects completed successfully!" "INFO"
} else {
    Write-Log "⚠️ Some projects failed. Check logs for details." "WARNING"
}

# Create batch processing report
$batchReport = @{
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Configuration = $ConfigFile
    TotalProjects = $totalProjects
    Successful = $successCount
    Failed = $failCount
    Skipped = $skipCount
    MaxConcurrent = $MaxConcurrent
    SkipExisting = $SkipExisting
    SystemResources = $systemResources
    Projects = $projectQueue | Select-Object name, status, EstimatedMinutes, StartTime, EndTime, errors
}

$reportPath = "batch_processing_report_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
$batchReport | ConvertTo-Json -Depth 5 | Set-Content $reportPath
Write-Log "📝 Batch processing report saved to: $reportPath" "INFO"

Write-Log "=== Batch Ambient Video Creator Finished ===" "INFO"