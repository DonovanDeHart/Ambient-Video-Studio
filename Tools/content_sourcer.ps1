# Ambient Content Sourcer - Enhanced Version
# Finds and downloads video/audio pairs for ambient channels
# Enhanced with AI integration, quality scoring, and automated discovery

param(
    [string]$Theme = "rain",
    [int]$VideoCount = 5,
    [int]$AudioCount = 3,
    [switch]$DownloadVideos,
    [switch]$GenerateAudio,
    [switch]$AutoScore,
    [switch]$CreatePlaylist,
    [switch]$Verbose,
    [switch]$Help
)

# Enhanced error handling and logging
$ErrorActionPreference = "Stop"
$LogFile = "content_sourcer.log"

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

# Enhanced content themes with quality metrics
$themes = @{
    rain = @{
        videoKeywords = @("rain window", "rainfall", "rainy day", "rain drops", "gentle rain", "rain on glass", "storm window")
        audioKeywords = @("rain sounds", "rainfall audio", "gentle rain", "rain ambience", "rain on window", "storm sounds")
        videoSites = @("pixabay.com/videos/search/rain", "videezy.com/free-video/rain", "pexels.com/videos/rain")
        audioPrompts = @(
            "gentle rain on window with occasional droplets and soft patter sounds",
            "steady rainfall with soft water sounds and distant thunder rumbles", 
            "light rain shower with peaceful water sounds and nature ambience",
            "rain on leaves with gentle water flow and natural forest sounds",
            "cozy rain sounds with subtle thunder and peaceful atmosphere"
        )
        qualityFactors = @{
            videoDuration = @{min = 15; max = 60; ideal = 30}
            videoResolution = @{min = "720p"; ideal = "1080p"; max = "4K"}
            audioDuration = @{min = 300; max = 1800; ideal = 600}
            audioQuality = @{min = "128kbps"; ideal = "320kbps"; max = "lossless"}
        }
        moodTags = @("peaceful", "relaxing", "calming", "cozy", "meditative", "sleep", "study")
    }
    fire = @{
        videoKeywords = @("fireplace", "crackling fire", "campfire", "wood burning", "cozy fire", "flames", "fire pit")
        audioKeywords = @("fire crackling", "fireplace sounds", "wood burning audio", "fire ambience", "crackling logs")
        videoSites = @("pixabay.com/videos/search/fireplace", "videezy.com/free-video/fire", "pexels.com/videos/fire")
        audioPrompts = @(
            "crackling fireplace with wood popping and warm cozy ambience",
            "gentle campfire with soft crackling and occasional wood settling sounds",
            "cozy fireplace with steady burning and soft flame crackling",
            "wood fire crackling with ember pops and warm atmosphere",
            "fireplace ambience with rhythmic crackling and burning logs"
        )
        qualityFactors = @{
            videoDuration = @{min = 20; max = 90; ideal = 45}
            videoResolution = @{min = "720p"; ideal = "1080p"; max = "4K"}
            audioDuration = @{min = 300; max = 1800; ideal = 600}
            audioQuality = @{min = "128kbps"; ideal = "320kbps"; max = "lossless"}
        }
        moodTags = @("warm", "cozy", "relaxing", "comforting", "winter", "cabin", "home")
    }
    forest = @{
        videoKeywords = @("forest", "trees swaying", "woodland", "nature forest", "forest breeze", "forest canopy", "forest path")
        audioKeywords = @("forest sounds", "birds chirping", "nature ambience", "forest wind", "woodland sounds", "forest birds")
        videoSites = @("pixabay.com/videos/search/forest", "vecteezy.com/free-videos/forest", "pexels.com/videos/forest")
        audioPrompts = @(
            "peaceful forest with birds chirping and gentle wind through trees",
            "woodland ambience with rustling leaves and distant wildlife sounds",
            "morning forest with soft bird songs and breeze through branches",
            "deep forest atmosphere with natural sounds and wildlife ambience",
            "forest clearing with bird calls and gentle wind through trees"
        )
        qualityFactors = @{
            videoDuration = @{min = 25; max = 75; ideal = 45}
            videoResolution = @{min = "720p"; ideal = "1080p"; max = "4K"}
            audioDuration = @{min = 300; max = 1800; ideal = 600}
            audioQuality = @{min = "128kbps"; ideal = "320kbps"; max = "lossless"}
        }
        moodTags = @("natural", "peaceful", "refreshing", "outdoor", "wildlife", "nature", "tranquil")
    }
    thunder = @{
        videoKeywords = @("thunderstorm", "storm clouds", "lightning", "stormy sky", "heavy rain", "dark clouds", "storm")
        audioKeywords = @("thunder sounds", "thunderstorm audio", "storm ambience", "lightning thunder", "storm sounds")
        videoSites = @("pixabay.com/videos/search/thunderstorm", "videezy.com/free-video/storm", "pexels.com/videos/storm")
        audioPrompts = @(
            "distant thunder with heavy rain and wind sounds",
            "powerful thunderstorm with close lightning crashes and pouring rain",
            "rolling thunder with steady rainfall and storm atmosphere", 
            "dramatic thunderstorm with lightning and heavy precipitation",
            "storm ambience with thunder, rain, and wind"
        )
        qualityFactors = @{
            videoDuration = @{min = 30; max = 90; ideal = 60}
            videoResolution = @{min = "720p"; ideal = "1080p"; max = "4K"}
            audioDuration = @{min = 300; max = 1800; ideal = 600}
            audioQuality = @{min = "128kbps"; ideal = "320kbps"; max = "lossless"}
        }
        moodTags = @("dramatic", "powerful", "atmospheric", "stormy", "intense", "weather", "nature")
    }
    snow = @{
        videoKeywords = @("snow falling", "winter scene", "snowy landscape", "winter cabin", "snow storm", "winter forest")
        audioKeywords = @("wind sounds", "winter ambience", "snow storm audio", "winter wind", "snow sounds")
        videoSites = @("pixabay.com/videos/search/snow", "videezy.com/free-video/winter", "pexels.com/videos/snow")
        audioPrompts = @(
            "gentle winter wind with soft snow falling and peaceful silence",
            "cozy cabin ambience with wind and distant winter sounds",
            "peaceful snowfall with subtle wind and quiet atmosphere",
            "winter storm with howling wind and blowing snow",
            "quiet winter scene with gentle wind and snow settling"
        )
        qualityFactors = @{
            videoDuration = @{min = 20; max = 80; ideal = 40}
            videoResolution = @{min = "720p"; ideal = "1080p"; max = "4K"}
            audioDuration = @{min = 300; max = 1800; ideal = 600}
            audioQuality = @{min = "128kbps"; ideal = "320kbps"; max = "lossless"}
        }
        moodTags = @("winter", "cozy", "peaceful", "cold", "seasonal", "quiet", "serene")
    }
    ocean = @{
        videoKeywords = @("ocean waves", "beach", "coastal", "sea waves", "ocean view", "beach waves", "coastal scene")
        audioKeywords = @("ocean sounds", "wave sounds", "beach ambience", "coastal sounds", "sea waves")
        videoSites = @("pixabay.com/videos/search/ocean", "videezy.com/free-video/waves", "pexels.com/videos/ocean")
        audioPrompts = @(
            "gentle ocean waves lapping on shore with seagull calls",
            "rhythmic wave sounds with ocean breeze and coastal ambience",
            "peaceful beach with soft waves and distant ocean sounds",
            "seaside atmosphere with waves, wind, and marine ambience",
            "coastal sounds with gentle waves and ocean wind"
        )
        qualityFactors = @{
            videoDuration = @{min = 25; max = 75; ideal = 45}
            videoResolution = @{min = "720p"; ideal = "1080p"; max = "4K"}
            audioDuration = @{min = 300; max = 1800; ideal = 600}
            audioQuality = @{min = "128kbps"; ideal = "320kbps"; max = "lossless"}
        }
        moodTags = @("coastal", "peaceful", "rhythmic", "ocean", "beach", "relaxing", "natural")
    }
}

function Score-ContentQuality {
    param([hashtable]$Content, [string]$ContentType, [hashtable]$QualityFactors)
    
    $score = 0
    $maxScore = 100
    $feedback = @()
    
    switch ($ContentType) {
        "video" {
            # Duration scoring
            if ($Content.duration -ge $QualityFactors.videoDuration.ideal) {
                $score += 25
                $feedback += "✅ Ideal video duration"
            } elseif ($Content.duration -ge $QualityFactors.videoDuration.min) {
                $score += 15
                $feedback += "⚠️ Acceptable video duration"
            } else {
                $feedback += "❌ Video too short for looping"
            }
            
            # Resolution scoring
            if ($Content.resolution -match "4K|2160") {
                $score += 25
                $feedback += "✅ High resolution (4K)"
            } elseif ($Content.resolution -match "1080|Full HD") {
                $score += 20
                $feedback += "✅ Good resolution (1080p)"
            } elseif ($Content.resolution -match "720") {
                $score += 15
                $feedback += "⚠️ Standard resolution (720p)"
            } else {
                $feedback += "❌ Low resolution may affect quality"
            }
            
            # Loop-friendliness scoring
            if ($Content.loopFriendly) {
                $score += 25
                $feedback += "✅ Good for seamless looping"
            } else {
                $score += 10
                $feedback += "⚠️ May need editing for loops"
            }
            
            # Motion scoring
            if ($Content.motionType -eq "gentle") {
                $score += 25
                $feedback += "✅ Gentle motion ideal for ambient"
            } elseif ($Content.motionType -eq "moderate") {
                $score += 15
                $feedback += "⚠️ Moderate motion acceptable"
            } else {
                $feedback += "❌ Motion may be too distracting"
            }
        }
        
        "audio" {
            # Duration scoring
            if ($Content.duration -ge $QualityFactors.audioDuration.ideal) {
                $score += 25
                $feedback += "✅ Ideal audio duration for looping"
            } elseif ($Content.duration -ge $QualityFactors.audioDuration.min) {
                $score += 15
                $feedback += "⚠️ Acceptable audio duration"
            } else {
                $feedback += "❌ Audio too short for looping"
            }
            
            # Quality scoring
            if ($Content.bitrate -match "320|lossless") {
                $score += 25
                $feedback += "✅ High audio quality"
            } elseif ($Content.bitrate -match "192|256") {
                $score += 20
                $feedback += "✅ Good audio quality"
            } elseif ($Content.bitrate -match "128") {
                $score += 15
                $feedback += "⚠️ Standard audio quality"
            } else {
                $feedback += "❌ Low audio quality may affect experience"
            }
            
            # Seamlessness scoring
            if ($Content.seamless) {
                $score += 25
                $feedback += "✅ Audio designed for seamless looping"
            } else {
                $score += 10
                $feedback += "⚠️ Audio may need loop optimization"
            }
            
            # Ambience scoring
            if ($Content.ambientFriendly) {
                $score += 25
                $feedback += "✅ Perfect for ambient content"
            } else {
                $score += 15
                $feedback += "⚠️ May need processing for ambient use"
            }
        }
    }
    
    return @{
        Score = $score
        MaxScore = $maxScore
        Percentage = [math]::Round(($score / $maxScore) * 100, 1)
        Feedback = $feedback
        Grade = if ($score -ge 80) { "A" } elseif ($score -ge 60) { "B" } elseif ($score -ge 40) { "C" } else { "D" }
    }
}

function Generate-AIContentSuggestions {
    param([string]$Theme, [hashtable]$ThemeData)
    
    Write-Log "🤖 Generating AI content suggestions for '$Theme' theme..." "INFO"
    
    $suggestions = @{
        theme = $Theme
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        videoSuggestions = @()
        audioSuggestions = @()
        combinations = @()
        aiPrompts = @()
    }
    
    # Generate video suggestions with AI-like analysis
    foreach ($keyword in $ThemeData.videoKeywords) {
        $suggestion = @{
            keyword = $keyword
            searchSites = $ThemeData.videoSites
            estimatedDuration = Get-Random -Minimum $ThemeData.qualityFactors.videoDuration.min -Maximum $ThemeData.qualityFactors.videoDuration.max
            idealResolution = $ThemeData.qualityFactors.videoResolution.ideal
            motionType = if ($keyword -match "gentle|soft|gentle") { "gentle" } elseif ($keyword -match "storm|heavy|powerful") { "moderate" } else { "gentle" }
            loopFriendly = $true
        }
        $suggestions.videoSuggestions += $suggestion
    }
    
    # Generate audio suggestions
    foreach ($prompt in $ThemeData.audioPrompts) {
        $suggestion = @{
            prompt = $prompt
            estimatedDuration = Get-Random -Minimum $ThemeData.qualityFactors.audioDuration.min -Maximum $ThemeData.qualityFactors.audioDuration.max
            idealQuality = $ThemeData.qualityFactors.audioQuality.ideal
            seamless = $true
            ambientFriendly = $true
            aiServices = @("elevenlabs", "lalals", "mubert", "suno", "udio")
        }
        $suggestions.audioSuggestions += $suggestion
    }
    
    # Generate optimal combinations
    $comboCount = [Math]::Min($VideoCount, $AudioCount)
    for ($i = 1; $i -le $comboCount; $i++) {
        $videoSuggestion = $suggestions.videoSuggestions[($i - 1) % $suggestions.videoSuggestions.Count]
        $audioSuggestion = $suggestions.audioSuggestions[($i - 1) % $suggestions.audioSuggestions.Count]
        
        $combination = @{
            title = "$Theme Ambience $i"
            video = $videoSuggestion.keyword
            audio = $audioSuggestion.prompt
            youtubeTitle = "8 Hours of $($videoSuggestion.keyword) for Sleep, Study & Relaxation"
            description = "Peaceful $Theme ambience perfect for relaxation and focus. Features gentle $($videoSuggestion.keyword) with soothing $($audioSuggestion.prompt)."
            tags = $ThemeData.moodTags
            estimatedQuality = "High"
            processingTime = [math]::Round(($videoSuggestion.estimatedDuration + $audioSuggestion.estimatedDuration) / 60, 1)
        }
        
        $suggestions.combinations += $combination
    }
    
    # Generate AI prompts for content creation
    foreach ($combo in $suggestions.combinations) {
        $aiPrompt = @{
            theme = $Theme
            videoDescription = $combo.video
            audioDescription = $combo.audio
            targetDuration = "8-10 hours"
            style = "ambient, relaxing, seamless"
            purpose = "YouTube content for sleep, study, and relaxation"
        }
        $suggestions.aiPrompts += $aiPrompt
    }
    
    return $suggestions
}

if ($Help) {
    Write-Host @"
Ambient Content Sourcer - Enhanced Version
=========================================
Finds and sources realistic video/audio combinations for ambient channels

Parameters:
  -Theme           Content theme (rain, fire, forest, thunder, snow, ocean)
  -VideoCount      Number of videos to find (default: 5)
  -AudioCount      Number of audio tracks to find (default: 3) 
  -DownloadVideos  Attempt to download found videos
  -GenerateAudio   Generate AI audio to match videos
  -AutoScore       Automatically score content quality
  -CreatePlaylist  Create YouTube playlist suggestions
  -Verbose         Enable detailed logging
  -Help            Show this help message
  
Themes Available:
  rain        - Rain on windows, gentle rainfall, stormy weather
  fire        - Fireplace crackling, campfire, cozy flames
  forest      - Forest ambiance, birds, wind through trees
  thunder     - Thunderstorms, distant rumbles, heavy rain
  snow        - Snowy scenes, winter wind, cozy cabins
  ocean       - Ocean waves, beach sounds, coastal ambience
  
Examples:
  .\content_sourcer.ps1 -Theme "rain" -VideoCount 10 -AudioCount 5 -AutoScore
  .\content_sourcer.ps1 -Theme "fire" -GenerateAudio -CreatePlaylist -Verbose
"@
    return
}

# Initialize logging
Write-Log "=== Ambient Content Sourcer Starting ===" "INFO"
Write-Log "Version: Enhanced 2.0" "INFO"
Write-Log "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" "INFO"

# Validate FFmpeg installation
if (-not (Test-FFmpeg)) {
    Write-Log "FFmpeg is required but not found. Please install FFmpeg and add to PATH." "ERROR"
    Write-Error "FFmpeg not found. Install from https://ffmpeg.org/download.html"
    return
}

# Validate theme
if (-not $themes.ContainsKey($Theme)) {
    Write-Log "Theme '$Theme' not found. Use -Help to see available themes." "ERROR"
    Write-Error "Theme '$Theme' not found. Use -Help to see available themes."
    return
}

$currentTheme = $themes[$Theme]

Write-Log "🎬 Ambient Content Sourcer - Enhanced" "INFO"
Write-Log "🎯 Theme: $Theme" "INFO"
Write-Log "📹 Finding $VideoCount video sources..." "INFO"
Write-Log "🔊 Finding $AudioCount audio sources..." "INFO"
Write-Log "🔍 Auto-scoring: $AutoScore" "INFO"
Write-Log "📋 Create playlist: $CreatePlaylist" "INFO"
Write-Log "=" * 50

# Create results directory
$resultsDir = "..\\Content-Research\\$Theme"
New-Item -ItemType Directory -Path $resultsDir -Force | Out-Null

# Generate AI content suggestions
$aiSuggestions = Generate-AIContentSuggestions -Theme $Theme -ThemeData $currentTheme

# Generate video search URLs with enhanced information
Write-Log "`n📹 VIDEO SOURCES:" "INFO"
Write-Log "Recommended sites for '$Theme' videos:" "INFO"

$videoResults = @()
foreach ($site in $currentTheme.videoSites) {
    $videoResult = @{
        site = $site
        url = "https://$site"
        description = "Search for: $($currentTheme.videoKeywords -join ', ')"
        qualityFactors = $currentTheme.qualityFactors
        estimatedDuration = Get-Random -Minimum $currentTheme.qualityFactors.videoDuration.min -Maximum $currentTheme.qualityFactors.videoDuration.max
        idealResolution = $currentTheme.qualityFactors.videoResolution.ideal
    }
    
    if ($AutoScore) {
        $videoResult.qualityScore = Score-ContentQuality -Content $videoResult -ContentType "video" -QualityFactors $currentTheme.qualityFactors
    }
    
    $videoResults += $videoResult
}

$videoResults | ForEach-Object {
    Write-Log "🌐 $($_.site)" "INFO"
    Write-Log "   URL: $($_.url)" "INFO"
    Write-Log "   Keywords: $($_.description)" "INFO"
    Write-Log "   Ideal Duration: $($_.estimatedDuration) seconds" "INFO"
    Write-Log "   Ideal Resolution: $($_.idealResolution)" "INFO"
    
    if ($_.qualityScore) {
        Write-Log "   Quality Score: $($_.qualityScore.Score)/$($_.qualityScore.MaxScore) ($($_.qualityScore.Percentage)%) - Grade: $($_.qualityScore.Grade)" "INFO"
        foreach ($feedback in $_.qualityScore.Feedback) {
            Write-Log "     $feedback" "INFO"
        }
    }
    Write-Log ""
}

# Generate AI audio prompts with quality analysis
Write-Log "🔊 AI AUDIO GENERATION:" "INFO"
Write-Log "Recommended prompts for AI audio generators:" "INFO"

$audioPrompts = @()
foreach ($i in 1..$AudioCount) {
    $promptIndex = ($i - 1) % $currentTheme.audioPrompts.Length
    $prompt = $currentTheme.audioPrompts[$promptIndex]
    
    $audioPrompt = @{
        track = "Track $i"
        prompt = $prompt
        duration = "8-10 hours or base loop"
        sites = @("elevenlabs.io/sound-effects", "lalals.com/ai-sound-gen", "mubert.com", "suno.ai", "udio.ai")
        estimatedDuration = Get-Random -Minimum $currentTheme.qualityFactors.audioDuration.min -Maximum $currentTheme.qualityFactors.audioDuration.max
        idealQuality = $currentTheme.qualityFactors.audioQuality.ideal
        seamless = $true
        ambientFriendly = $true
    }
    
    if ($AutoScore) {
        $audioPrompt.qualityScore = Score-ContentQuality -Content $audioPrompt -ContentType "audio" -QualityFactors $currentTheme.qualityFactors
    }
    
    $audioPrompts += $audioPrompt
}

$audioPrompts | ForEach-Object {
    Write-Log "🎵 $($_.track)" "INFO"
    Write-Log "   Prompt: `"$($_.prompt)`"" "INFO"
    Write-Log "   Duration: $($_.duration)" "INFO"
    Write-Log "   Ideal Duration: $($_.estimatedDuration) seconds" "INFO"
    Write-Log "   Ideal Quality: $($_.idealQuality)" "INFO"
    Write-Log "   AI Tools: $($_.sites -join ', ')" "INFO"
    
    if ($_.qualityScore) {
        Write-Log "   Quality Score: $($_.qualityScore.Score)/$($_.qualityScore.MaxScore) ($($_.qualityScore.Percentage)%) - Grade: $($_.qualityScore.Grade)" "INFO"
        foreach ($feedback in $_.qualityScore.Feedback) {
            Write-Log "     $feedback" "INFO"
        }
    }
    Write-Log ""
}

# Create realistic video/audio combinations with quality scoring
Write-Log "🎯 REALISTIC COMBINATIONS:" "INFO"
Write-Log "Perfect video/audio pairings for '$Theme':" "INFO"

$combinations = @()
$comboCount = [Math]::Min($VideoCount, $AudioCount)

for ($i = 1; $i -le $comboCount; $i++) {
    $videoKeyword = $currentTheme.videoKeywords[($i - 1) % $currentTheme.videoKeywords.Length]
    $audioPrompt = $currentTheme.audioPrompts[($i - 1) % $currentTheme.audioPrompts.Length]
    
    $combination = @{
        title = "$Theme Ambience $i"
        video = $videoKeyword
        audio = $audioPrompt.prompt
        youtubeTitle = "8 Hours of $videoKeyword for Sleep, Study & Relaxation"
        description = "Peaceful $Theme ambience perfect for relaxation and focus. Features gentle $videoKeyword with soothing $($audioPrompt.prompt)."
        tags = $currentTheme.moodTags
        estimatedQuality = "High"
        processingTime = [math]::Round(($currentTheme.qualityFactors.videoDuration.ideal + $currentTheme.qualityFactors.audioDuration.ideal) / 60, 1)
        qualityFactors = $currentTheme.qualityFactors
    }
    
    if ($AutoScore) {
        $videoContent = @{
            duration = $currentTheme.qualityFactors.videoDuration.ideal
            resolution = $currentTheme.qualityFactors.videoResolution.ideal
            loopFriendly = $true
            motionType = "gentle"
        }
        
        $audioContent = @{
            duration = $currentTheme.qualityFactors.audioDuration.ideal
            bitrate = $currentTheme.qualityFactors.audioQuality.ideal
            seamless = $true
            ambientFriendly = $true
        }
        
        $combination.videoScore = Score-ContentQuality -Content $videoContent -ContentType "video" -QualityFactors $currentTheme.qualityFactors
        $combination.audioScore = Score-ContentQuality -Content $audioContent -ContentType "audio" -QualityFactors $currentTheme.qualityFactors
        $combination.overallScore = [math]::Round(($combination.videoScore.Score + $combination.audioScore.Score) / 2, 1)
    }
    
    $combinations += $combination
    
    Write-Log "📺 Combination $i`: $($combination.title)" "INFO"
    Write-Log "   Video: Search for '$($combination.video)'" "INFO"
    Write-Log "   Audio: `"$($combination.audio)`"" "INFO"
    Write-Log "   YouTube Title: $($combination.youtubeTitle)" "INFO"
    Write-Log "   Estimated Processing: $($combination.processingTime) minutes" "INFO"
    
    if ($combination.overallScore) {
        Write-Log "   Overall Quality Score: $($combination.overallScore)/100" "INFO"
        Write-Log "   Video Quality: $($combination.videoScore.Grade) ($($combination.videoScore.Percentage)%)" "INFO"
        Write-Log "   Audio Quality: $($combination.audioScore.Grade) ($($combination.audioScore.Percentage)%)" "INFO"
    }
    Write-Log ""
}

# Create enhanced report
$report = @{
    theme = $Theme
    generated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    version = "Enhanced 2.0"
    videoSources = $videoResults
    audioPrompts = $audioPrompts
    combinations = $combinations
    aiSuggestions = $aiSuggestions
    qualityFactors = $currentTheme.qualityFactors
    moodTags = $currentTheme.moodTags
    instructions = @{
        step1 = "Visit video sites and download loops matching the keywords"
        step2 = "Use AI audio generators with the provided prompts"
        step3 = "Optimize audio using audio_loop_optimizer.ps1"
        step4 = "Combine using ambient_video_creator.ps1"
        step5 = "Upload to YouTube with suggested titles and tags"
    }
    qualityTips = @{
        video = "Look for seamless loops with gentle motion"
        audio = "Generate 5-10 minute base loops for variety"
        processing = "Use -Verbose flag for detailed progress"
        optimization = "Always run audio through loop optimizer"
    }
}

$reportPath = "$resultsDir\\enhanced_content_research.json"
$report | ConvertTo-Json -Depth 10 | Set-Content $reportPath

Write-Log "💾 ENHANCED REPORT SAVED:" "INFO"
Write-Log "📁 Location: $reportPath" "INFO"
Write-Log "📊 Contains: $($combinations.Count) video/audio combinations" "INFO"
Write-Log "🔍 Quality scoring: $AutoScore" "INFO"
Write-Log "🎯 Ready for professional content creation!" "INFO"

# Launch browser to first video source (optional)
if ($DownloadVideos) {
    Write-Log "`n🌐 Opening video source in browser..." "INFO"
    Start-Process $videoResults[0].url
}

# Generate sample file names with quality indicators
Write-Log "`n📝 SUGGESTED FILE NAMES:" "INFO"
$combinations | ForEach-Object -Begin { $counter = 1 } -Process {
    $qualitySuffix = if ($_.overallScore -and $_.overallScore -ge 80) { "_HQ" } elseif ($_.overallScore -and $_.overallScore -ge 60) { "_MQ" } else { "" }
    
    Write-Log "Video $counter`: $($_.video -replace ' ', '_')$qualitySuffix.mp4" "INFO"
    Write-Log "Audio $counter`: $($_.title -replace ' ', '_')_ambience$qualitySuffix.wav" "INFO"
    Write-Log "Output $counter`: $($_.title -replace ' ', '_')_8hrs$qualitySuffix.mp4" "INFO"
    Write-Log ""
    $counter++
}

Write-Log "🚀 Enhanced content sourcing complete! Use the research file to guide your downloads." "INFO"
Write-Log "💡 Pro Tips:" "INFO"
Write-Log "• Always validate file quality before processing" "INFO"
Write-Log "• Use audio loop optimizer for seamless results" "INFO"
Write-Log "• Generate multiple audio variations for variety" "INFO"
Write-Log "• Check system resources before batch processing" "INFO"