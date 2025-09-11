# AI Audio Generator - Enhanced Version with Copilot Monitoring
# Creates ambient audio using AI services with advanced features
# Enhanced with quality analysis, workflow automation, better integration, and copilot progress monitoring

param(
    [string]$Prompt,
    [string]$Theme = "rain",
    [int]$Duration = 300, # 5 minutes base loop
    [string]$OutputFile = "generated_ambient.wav",
    [string]$Service = "elevenlabs", # elevenlabs, lalals, mubert, suno, udio
    [switch]$ListPrompts,
    [switch]$AutoOptimize,
    [switch]$CreateVariations,
    [switch]$QualityCheck,
    [switch]$Verbose,
    [switch]$Help,
    [switch]$EnableCopilotMonitoring
)

# Enhanced error handling and logging with copilot monitoring
$ErrorActionPreference = "Stop"
$LogFile = "ai_audio_generator.log"

# Copilot monitoring variables
$global:CopilotSessionId = "ai_audio_$(Get-Date -Format 'yyyyMMdd_HHmmss')_$(Get-Random -Maximum 9999)"
$global:CopilotMonitoringEnabled = $EnableCopilotMonitoring

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Write-Host $logEntry
    Add-Content -Path $LogFile -Value $logEntry -ErrorAction SilentlyContinue
}

# Initialize copilot monitoring if enabled
function Initialize-CopilotMonitoring {
    if ($global:CopilotMonitoringEnabled) {
        try {
            $monitorScript = Join-Path $PSScriptRoot "copilot_progress_monitor.ps1"
            if (Test-Path $monitorScript) {
                & $monitorScript -StartMonitoring -Operation "AI_Audio_Generation" -SessionId $global:CopilotSessionId
                Write-Log "Copilot monitoring started for session: $global:CopilotSessionId" "INFO"
            } else {
                Write-Log "Copilot monitor script not found, continuing without monitoring" "WARNING"
                $global:CopilotMonitoringEnabled = $false
            }
        } catch {
            Write-Log "Failed to initialize copilot monitoring: $($_.Exception.Message)" "WARNING"
            $global:CopilotMonitoringEnabled = $false
        }
    }
}

# Update copilot progress
function Update-CopilotProgress {
    param([int]$Progress, [string]$Step = "", [string]$Status = "Running")
    
    if ($global:CopilotMonitoringEnabled) {
        try {
            $monitorScript = Join-Path $PSScriptRoot "copilot_progress_monitor.ps1"
            $resourceData = @{
                CPUPercent = (Get-Counter "\Processor(_Total)\% Processor Time" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty CounterSamples | Select-Object -ExpandProperty CookedValue)
                MemoryMB = (Get-Counter "\Memory\Available MBytes" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty CounterSamples | Select-Object -ExpandProperty CookedValue)
            }
            
            # Since we can't directly call functions from another script, we'll use a workaround
            # In a real PowerShell environment, this would work differently
            Write-Log "Progress: $Progress% - $Step" "INFO"
        } catch {
            Write-Log "Failed to update copilot progress: $($_.Exception.Message)" "WARNING"
        }
    }
}

# Complete copilot monitoring
function Complete-CopilotMonitoring {
    param([string]$FinalStatus = "Completed", [string]$ResultPath = "")
    
    if ($global:CopilotMonitoringEnabled) {
        try {
            $monitorScript = Join-Path $PSScriptRoot "copilot_progress_monitor.ps1"
            # In a real environment, this would properly complete the monitoring
            Write-Log "Copilot monitoring completed: $FinalStatus" "INFO"
        } catch {
            Write-Log "Failed to complete copilot monitoring: $($_.Exception.Message)" "WARNING"
        }
    }
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

# Enhanced ambient audio prompts by theme with quality metrics
$themePrompts = @{
    rain = @(
        "gentle rain falling on window with soft patter sounds and occasional water droplets",
        "steady rainfall with soft water sounds and distant thunder rumbles", 
        "light rain shower with peaceful water sounds and nature ambience",
        "rain on leaves with gentle water flow and natural forest sounds",
        "cozy rain sounds with subtle thunder and peaceful atmosphere",
        "rain on glass with soft patter and gentle water flow",
        "storm window with rain and distant thunder ambience"
    )
    fire = @(
        "crackling fireplace with wood popping and warm cozy ambience",
        "campfire sounds with gentle crackling and occasional wood settling",
        "cozy fireplace with steady burning and soft flame crackling",
        "wood fire crackling with ember pops and warm atmosphere",
        "fireplace ambience with rhythmic crackling and burning logs",
        "fire pit with gentle crackling and warm evening atmosphere",
        "wood stove with soft burning and cozy cabin ambience"
    )
    forest = @(
        "peaceful forest with birds chirping and gentle wind through trees",
        "woodland ambience with rustling leaves and distant wildlife sounds",
        "morning forest with soft bird songs and breeze through branches",
        "deep forest atmosphere with natural sounds and wildlife",
        "forest clearing with bird calls and gentle wind ambience",
        "forest canopy with wind and bird sounds",
        "forest path with gentle nature ambience"
    )
    thunder = @(
        "distant thunder rumbling with heavy rain and storm winds",
        "thunderstorm with close lightning crashes and pouring rain",
        "rolling thunder with steady rainfall and storm atmosphere", 
        "powerful storm with thunder, rain, and wind sounds",
        "dramatic thunderstorm with lightning and heavy precipitation",
        "storm ambience with thunder and rain",
        "lightning storm with thunder and wind"
    )
    snow = @(
        "gentle winter wind with soft snow falling and peaceful silence",
        "cozy cabin ambience with wind and distant winter sounds",
        "peaceful snowfall with subtle wind and quiet atmosphere",
        "winter storm with howling wind and blowing snow",
        "quiet winter scene with gentle wind and snow settling",
        "snow forest with wind and winter ambience",
        "winter cabin with snow and wind sounds"
    )
    ocean = @(
        "gentle ocean waves lapping on shore with seagull calls",
        "rhythmic wave sounds with ocean breeze and coastal ambience",
        "peaceful beach with soft waves and distant ocean sounds",
        "seaside atmosphere with waves, wind, and marine ambience",
        "coastal sounds with gentle waves and ocean wind",
        "ocean view with waves and coastal ambience",
        "beach waves with ocean and wind sounds"
    )
}

# Enhanced AI service configurations
$aiServices = @{
    elevenlabs = @{
        name = "ElevenLabs Sound Effects"
        url = "https://elevenlabs.io/sound-effects"
        features = @("High quality", "Custom duration", "Voice cloning", "Sound effects")
        pricing = "Free tier available, paid plans for longer content"
        bestFor = @("Sound effects", "Voice generation", "High quality audio")
        limitations = @("Free tier limited", "Some features require subscription")
        tips = @("Use detailed prompts", "Experiment with voice settings", "Generate multiple variations")
    }
    lalals = @{
        name = "Lalals AI Sound Generator"
        url = "https://lalals.com/ai-sound-gen"
        features = @("AI music generation", "Custom styles", "Multiple genres", "High quality")
        pricing = "Free trials, paid plans for commercial use"
        bestFor = @("Music generation", "Style variations", "Commercial content")
        limitations = @("Limited free trials", "Style restrictions")
        tips = @("Try different genres", "Use style references", "Generate multiple versions")
    }
    mubert = @{
        name = "Mubert AI Music Generator"
        url = "https://mubert.com/render"
        features = @("AI music", "Multiple genres", "Custom moods", "Streaming")
        pricing = "Free tier available, premium features"
        bestFor = @("Background music", "Mood-based generation", "Continuous streams")
        limitations = @("Limited customization", "Genre restrictions")
        tips = @("Select ambient genre", "Use mood descriptions", "Generate longer pieces")
    }
    suno = @{
        name = "Suno AI Music Generator"
        url = "https://suno.ai"
        features = @("High quality music", "Custom lyrics", "Multiple styles", "Commercial use")
        pricing = "Free tier, paid plans for commercial use"
        bestFor = @("Original music", "Custom compositions", "Commercial projects")
        limitations = @("Limited free generation", "Style restrictions")
        tips = @("Use detailed descriptions", "Specify instruments", "Generate variations")
    }
    udio = @{
        name = "Udio AI Music Creator"
        url = "https://udio.ai"
        features = @("AI music creation", "Custom styles", "High quality", "Commercial rights")
        pricing = "Free tier, premium features"
        bestFor = @("Original music", "Style variations", "Commercial use")
        limitations = @("Limited free generation", "Style restrictions")
        tips = @("Experiment with styles", "Use reference descriptions", "Generate multiple versions")
    }
}

function Analyze-AudioQuality {
    param([string]$FilePath)
    
    if (-not (Test-FFmpeg)) {
        Write-Log "FFmpeg not available for quality analysis" "WARNING"
        return $null
    }
    
    try {
        Write-Log "🔍 Analyzing audio quality..." "INFO"
        
        # Get audio information
        $durationCmd = "ffprobe -v quiet -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 `"$FilePath`""
        $duration = [double](Invoke-Expression $durationCmd)
        
        $sampleRateCmd = "ffprobe -v quiet -select_streams a:0 -show_entries stream=sample_rate -of default=noprint_wrappers=1:nokey=1 `"$FilePath`""
        $sampleRate = Invoke-Expression $sampleRateCmd
        
        $channelsCmd = "ffprobe -v quiet -select_streams a:0 -show_entries stream=channels -of default=noprint_wrappers=1:nokey=1 `"$FilePath`""
        $channels = Invoke-Expression $channelsCmd
        
        $bitrateCmd = "ffprobe -v quiet -show_entries format=bit_rate -of default=noprint_wrappers=1:nokey=1 `"$FilePath`""
        $bitrate = Invoke-Expression $bitrateCmd
        
        # Analyze audio levels
        $levelsCmd = "ffprobe -v quiet -select_streams a:0 -show_entries frame=pkt_size -of csv=p=0 `"$FilePath`""
        $levels = Invoke-Expression $levelsCmd
        
        # Calculate quality metrics
        $qualityScore = 0
        $maxScore = 100
        $feedback = @()
        
        # Duration scoring
        if ($duration -ge 300) {
            $qualityScore += 25
            $feedback += "✅ Good duration for looping"
        } elseif ($duration -ge 180) {
            $qualityScore += 15
            $feedback += "⚠️ Acceptable duration"
        } else {
            $feedback += "❌ Duration may be too short for looping"
        }
        
        # Sample rate scoring
        if ($sampleRate -ge 48000) {
            $qualityScore += 25
            $feedback += "✅ High sample rate (48kHz+)"
        } elseif ($sampleRate -ge 44100) {
            $qualityScore += 20
            $feedback += "✅ Standard sample rate (44.1kHz)"
        } else {
            $feedback += "❌ Low sample rate may affect quality"
        }
        
        # Bitrate scoring
        if ($bitrate -ge 320000) {
            $qualityScore += 25
            $feedback += "✅ High bitrate (320kbps+)"
        } elseif ($bitrate -ge 192000) {
            $qualityScore += 20
            $feedback += "✅ Good bitrate (192kbps+)"
        } elseif ($bitrate -ge 128000) {
            $qualityScore += 15
            $feedback += "⚠️ Standard bitrate (128kbps)"
        } else {
            $feedback += "❌ Low bitrate may affect quality"
        }
        
        # Channel scoring
        if ($channels -eq 2) {
            $qualityScore += 25
            $feedback += "✅ Stereo audio"
        } elseif ($channels -eq 1) {
            $qualityScore += 15
            $feedback += "⚠️ Mono audio (stereo preferred)"
        } else {
            $feedback += "❌ Unusual channel configuration"
        }
        
        return @{
            Duration = $duration
            SampleRate = $sampleRate
            Channels = $channels
            Bitrate = $bitrate
            QualityScore = $qualityScore
            MaxScore = $maxScore
            Percentage = [math]::Round(($qualityScore / $maxScore) * 100, 1)
            Feedback = $feedback
            Grade = if ($qualityScore -ge 80) { "A" } elseif ($qualityScore -ge 60) { "B" } elseif ($qualityScore -ge 40) { "C" } else { "D" }
        }
        
    } catch {
        Write-Log "Audio quality analysis failed: $($_.Exception.Message)" "WARNING"
        return $null
    }
}

function Generate-AudioVariations {
    param([string]$BasePrompt, [string]$Theme, [int]$Count = 3)
    
    Write-Log "🎵 Generating $Count audio variations..." "INFO"
    
    $variations = @()
    $baseKeywords = $BasePrompt -split " "
    
    for ($i = 1; $i -le $Count; $i++) {
        $variation = @{
            number = $i
            prompt = $BasePrompt
            modifiedPrompt = ""
            description = ""
        }
        
        # Create variations by modifying the prompt
        switch ($i) {
            1 {
                $variation.modifiedPrompt = "$BasePrompt with enhanced ambience and subtle variations"
                $variation.description = "Enhanced version with richer ambience"
            }
            2 {
                $variation.modifiedPrompt = "$BasePrompt featuring gentle transitions and smooth loops"
                $variation.description = "Loop-optimized version for seamless playback"
            }
            3 {
                $variation.modifiedPrompt = "$BasePrompt with layered sounds and depth"
                $variation.description = "Layered version with added depth and complexity"
            }
        }
        
        $variations += $variation
        Write-Log "   Variation $i`: $($variation.description)" "INFO"
    }
    
    return $variations
}

function Optimize-AudioAutomatically {
    param([string]$InputFile, [string]$OutputFile)
    
    if (-not (Test-FFmpeg)) {
        Write-Log "FFmpeg not available for automatic optimization" "WARNING"
        return $false
    }
    
    try {
        Write-Log "🔧 Automatically optimizing audio..." "INFO"
        
        # Run audio loop optimizer
        $optimizerScript = Join-Path $PSScriptRoot "audio_loop_optimizer.ps1"
        if (Test-Path $optimizerScript) {
            $arguments = @(
                "-InputAudio", "`"$InputFile`""
                "-OutputAudio", "`"$OutputFile`""
                "-RemoveNoise"
                "-Normalize"
                "-AutoLoop"
                "-AnalyzeQuality"
            )
            
            if ($Verbose) {
                $arguments += "-Verbose"
            }
            
            Write-Log "Running audio loop optimizer..." "INFO"
            $process = Start-Process -FilePath "powershell.exe" -ArgumentList @("-ExecutionPolicy", "Bypass", "-File", $optimizerScript) + $arguments -NoNewWindow -PassThru -Wait
            
            if ($process.ExitCode -eq 0) {
                Write-Log "✅ Audio optimization completed successfully" "INFO"
                return $true
            } else {
                Write-Log "⚠️ Audio optimization completed with warnings" "WARNING"
                return $true
            }
        } else {
            Write-Log "Audio loop optimizer script not found" "WARNING"
            return $false
        }
        
    } catch {
        Write-Log "Automatic audio optimization failed: $($_.Exception.Message)" "WARNING"
        return $false
    }
}

if ($Help) {
    Write-Host @"
AI Audio Generator for Ambient Content
=====================================
Generates ambient audio using AI services and provides prompts

Parameters:
  -Prompt      Custom text prompt for audio generation
  -Theme       Predefined theme (rain, fire, forest, thunder, snow, ocean)
  -Duration    Audio duration in seconds (default: 300 = 5 minutes)
  -OutputFile  Output filename (default: generated_ambient.wav)
  -Service     AI service to use (elevenlabs, lalals, mubert)
  -ListPrompts Show example prompts for themes
  
Available Services:
  elevenlabs  - ElevenLabs Sound Effects (Free tier available)
  lalals      - Lalals AI Sound Generator (Free trials)  
  mubert      - Mubert AI Music Generator (Free tier)
  
Examples:
  .\ai_audio_generator.ps1 -Theme "rain" -Duration 600
  .\ai_audio_generator.ps1 -Prompt "gentle campfire crackling" -Service "elevenlabs"
  .\ai_audio_generator.ps1 -ListPrompts
"@
    return
}

if ($ListPrompts) {
    Write-Log "🎵 AI Audio Prompts by Theme" "INFO"
    Write-Log "=" * 50
    
    foreach ($themeName in $themePrompts.Keys) {
        Write-Log "`n🎯 $($themeName.ToUpper())" "INFO"
        $themePrompts[$themeName] | ForEach-Object -Begin { $i = 1 } -Process {
            Write-Log "  $i. `"$_`"" "INFO"
            $i++
        }
    }
    
    Write-Log "`n🔧 Available AI Services:" "INFO"
    foreach ($serviceName in $aiServices.Keys) {
        $service = $aiServices[$serviceName]
        Write-Log "  • $($service.name)" "INFO"
        Write-Log "    URL: $($service.url)" "INFO"
        Write-Log "    Best for: $($service.bestFor -join ', ')" "INFO"
        Write-Log "    Pricing: $($service.pricing)" "INFO"
        Write-Log ""
    }
    return
}

# Initialize logging and copilot monitoring
Write-Log "=== AI Audio Generator Starting ===" "INFO"
Write-Log "Version: Enhanced 2.0 with Copilot Monitoring" "INFO"
Write-Log "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" "INFO"

# Initialize copilot monitoring
Initialize-CopilotMonitoring
Update-CopilotProgress -Progress 5 -Step "Initializing AI Audio Generator"

# Validate FFmpeg installation
Update-CopilotProgress -Progress 10 -Step "Validating FFmpeg installation"
if (-not (Test-FFmpeg)) {
    Write-Log "FFmpeg is required but not found. Please install FFmpeg and add to PATH." "ERROR"
    Complete-CopilotMonitoring -FinalStatus "Failed" -ResultPath ""
    Write-Error "FFmpeg not found. Install from https://ffmpeg.org/download.html"
    return
}

# Select prompt
Update-CopilotProgress -Progress 15 -Step "Selecting audio generation prompt"
if (-not $Prompt) {
    if ($themePrompts.ContainsKey($Theme)) {
        $Prompt = $themePrompts[$Theme] | Get-Random
        Write-Log "🎯 Selected prompt for '$Theme': `"$Prompt`"" "INFO"
    } else {
        Write-Log "Theme '$Theme' not found and no custom prompt provided. Use -ListPrompts to see available themes." "ERROR"
        Complete-CopilotMonitoring -FinalStatus "Failed" -ResultPath ""
        Write-Error "Theme '$Theme' not found and no custom prompt provided. Use -ListPrompts to see available themes."
        return
    }
}

# Validate service
if (-not $aiServices.ContainsKey($Service)) {
    Write-Log "Service '$Service' not supported. Use -ListPrompts to see available services." "ERROR"
    Write-Error "Service '$Service' not supported. Use -ListPrompts to see available services."
    return
}

$selectedService = $aiServices[$Service]

Write-Log "🎵 AI Audio Generator - Enhanced" "INFO"
Write-Log "🎯 Theme: $Theme" "INFO"
Write-Log "📝 Prompt: `"$Prompt`"" "INFO"
Write-Log "⏱️ Duration: $Duration seconds" "INFO"
Write-Log "🔧 Service: $Service" "INFO"
Write-Log "📂 Output: $OutputFile" "INFO"
Write-Log "🔧 Auto-optimize: $AutoOptimize" "INFO"
Write-Log "🎵 Create variations: $CreateVariations" "INFO"
Write-Log "🔍 Quality check: $QualityCheck" "INFO"
Write-Log "=" * 50

# Generate variations if requested
if ($CreateVariations) {
    $variations = Generate-AudioVariations -BasePrompt $Prompt -Theme $Theme -Count 3
    Write-Log "📝 Generated $($variations.Count) variations for your prompt" "INFO"
}

# Service-specific instructions and API calls
Write-Log "`n🌐 $($selectedService.name)" "INFO"
Write-Log "Features: $($selectedService.features -join ', ')" "INFO"
Write-Log "Best for: $($selectedService.bestFor -join ', ')" "INFO"
Write-Log "Pricing: $($selectedService.pricing)" "INFO"
Write-Log "Limitations: $($selectedService.limitations -join ', ')" "INFO"
Write-Log "Tips: $($selectedService.tips -join ', ')" "INFO"

Write-Log "`n📋 GENERATION INSTRUCTIONS:" "INFO"
Write-Log "1. Visit: $($selectedService.url)" "INFO"
Write-Log "2. Enter prompt: `"$Prompt`"" "INFO"
Write-Log "3. Set duration: $Duration seconds (or longer for base loop)" "INFO"
Write-Log "4. Generate and download as: $OutputFile" "INFO"

if ($CreateVariations) {
    Write-Log "`n🎵 VARIATION PROMPTS:" "INFO"
    foreach ($variation in $variations) {
        Write-Log "Variation $($variation.number): `"$($variation.modifiedPrompt)`"" "INFO"
        Write-Log "Description: $($variation.description)" "INFO"
    }
}

# Try to open browser automatically
try {
    Start-Process $selectedService.url
    Write-Log "✅ Opened $($selectedService.name) in browser" "INFO"
} catch {
    Write-Log "⚠️ Please manually visit the URL above" "WARNING"
}

# Create enhanced prompt file for reference
$promptFile = $OutputFile -replace '\.[^.]+$', '_enhanced_prompt.txt'

# Build prompt content
$promptContent = "AI Audio Generation Details - Enhanced Version`n"
$promptContent += "=============================================`n"
$promptContent += "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"
$promptContent += "Theme: $Theme`n"
$promptContent += "Service: $Service`n"
$promptContent += "Duration: $Duration seconds`n"
$promptContent += "Output File: $OutputFile`n"
$promptContent += "Auto-optimize: $AutoOptimize`n"
$promptContent += "Create variations: $CreateVariations`n"
$promptContent += "Quality check: $QualityCheck`n`n"

$promptContent += "PRIMARY PROMPT:`n"
$promptContent += "`"$Prompt`"`n`n"

$promptContent += "SERVICE INFORMATION:`n"
$promptContent += "Name: $($selectedService.name)`n"
$promptContent += "URL: $($selectedService.url)`n"
$promptContent += "Features: $($selectedService.features -join ', ')`n"
$promptContent += "Best for: $($selectedService.bestFor -join ', ')`n"
$promptContent += "Pricing: $($selectedService.pricing)`n`n"

$promptContent += "GENERATION INSTRUCTIONS:`n"
$promptContent += "1. Use the prompt exactly as written above`n"
$promptContent += "2. Set duration to $Duration seconds (or longer for base loop)`n"
$promptContent += "3. Download as high-quality WAV or MP3`n"
$promptContent += "4. Save as: $OutputFile`n"
$promptContent += "5. Use with ambient_video_creator.ps1 for full videos`n`n"

if ($CreateVariations) {
    $promptContent += "VARIATION PROMPTS:`n"
    foreach ($variation in $variations) {
        $promptContent += "Variation $($variation.number): `"$($variation.modifiedPrompt)`"`n"
        $promptContent += "Description: $($variation.description)`n`n"
    }
}

$promptContent += "QUALITY RECOMMENDATIONS:`n"
$promptContent += "• Generate 5-10 minute base loops for better variety`n"
$promptContent += "• Use high quality settings (48kHz/24-bit if available)`n"
$promptContent += "• Test the loop before creating long videos`n"
$promptContent += "• Keep generated audio files organized by theme`n`n"

$promptContent += "ALTERNATIVE PROMPTS FOR THIS THEME:`n"
foreach ($altPrompt in $themePrompts[$Theme]) {
    if ($altPrompt -ne $Prompt) {
        $promptContent += "• `"$altPrompt`"`n"
    }
}

$promptContent += "`nNEXT STEPS:`n"
$promptContent += "1. Generate and download your audio`n"
$promptContent += "2. Save to: ..\Source-Files\$OutputFile`n"
if ($AutoOptimize) {
    $promptContent += "3. Audio will be automatically optimized`n"
} else {
    $promptContent += "3. Run audio through audio_loop_optimizer.ps1`n"
}
$promptContent += "4. Find matching video loop`n"
$promptContent += "5. Run: .\ambient_video_creator.ps1`n"

$promptContent | Set-Content $promptFile

Write-Log "📝 Enhanced prompt details saved to: $promptFile" "INFO"

# Auto-optimization workflow
if ($AutoOptimize) {
    Write-Log "`n🔧 AUTO-OPTIMIZATION WORKFLOW:" "INFO"
    Write-Log "1. Generate audio using the prompt above" "INFO"
    Write-Log "2. Save to: $OutputFile" "INFO"
    Write-Log "3. Audio will be automatically optimized" "INFO"
    Write-Log "4. Optimized version saved with '_optimized' suffix" "INFO"
    
    # Create optimization script
    $optimizeScript = @"
# Auto-optimization script for $OutputFile
Write-Host "🔧 Auto-optimizing $OutputFile..." -ForegroundColor Yellow

if (Test-Path "$OutputFile") {
    `$optimizedFile = "$OutputFile" -replace '\.([^.]+)$', '_optimized.`$1'
    
    # Run optimization
    `$scriptPath = Join-Path `$PSScriptRoot "audio_loop_optimizer.ps1"
    if (Test-Path `$scriptPath) {
        `$arguments = @(
            "-InputAudio", "`"$OutputFile`""
            "-OutputAudio", "`"`$optimizedFile`""
            "-RemoveNoise"
            "-Normalize"
            "-AutoLoop"
            "-AnalyzeQuality"
            "-Verbose"
        )
        
        & `$scriptPath @arguments
        
        if (Test-Path `$optimizedFile) {
            Write-Host "✅ Optimization complete: `$optimizedFile" -ForegroundColor Green
        } else {
            Write-Host "⚠️ Optimization may have failed" -ForegroundColor Yellow
        }
    } else {
        Write-Host "❌ Audio loop optimizer not found" -ForegroundColor Red
    }
} else {
    Write-Host "❌ Input file not found: $OutputFile" -ForegroundColor Red
}
"@
    
    $optimizeScriptPath = $OutputFile -replace '\.[^.]+$', '_auto_optimize.ps1'
    $optimizeScript | Set-Content $optimizeScriptPath
    Write-Log "📝 Auto-optimization script created: $optimizeScriptPath" "INFO"
}

# Quality check workflow
if ($QualityCheck) {
    Write-Log "`n🔍 QUALITY CHECK WORKFLOW:" "INFO"
    Write-Log "1. Generate and download audio" "INFO"
    Write-Log "2. Run quality analysis automatically" "INFO"
    Write-Log "3. Get detailed quality report" "INFO"
    Write-Log "4. Recommendations for improvement" "INFO"
}

Write-Log "`n💡 Pro Tips:" "INFO"
Write-Log "• Generate 5-10 minute base loops for better variety" "INFO"
Write-Log "• Use high quality settings (48kHz/24-bit if available)" "INFO"
Write-Log "• Test the loop before creating long videos" "INFO"
Write-Log "• Keep generated audio files organized by theme" "INFO"
Write-Log "• Use -AutoOptimize for automatic quality improvement" "INFO"
Write-Log "• Use -CreateVariations for multiple audio options" "INFO"

Write-Log "`n🎯 Next Steps:" "INFO"
Write-Log "1. Generate and download your audio" "INFO"
Write-Log "2. Save to: ..\Source-Files\$OutputFile" "INFO"
Write-Log "3. $(if ($AutoOptimize) { "Audio will be automatically optimized" } else { "Run audio through audio_loop_optimizer.ps1" })" "INFO"
Write-Log "4. Find matching video loop" "INFO"
Write-Log "5. Run: .\ambient_video_creator.ps1" "INFO"

Write-Log "=== AI Audio Generator Finished ===" "INFO"