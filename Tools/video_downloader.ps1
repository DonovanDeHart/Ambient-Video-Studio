# Video Downloader - Downloads ambient videos from free sources
# Uses yt-dlp to download from various platforms

param(
    [string[]]$URLs,
    [string]$OutputDir = "..\Source-Files",
    [string]$Quality = "best[height<=1080]",
    [switch]$AudioOnly,
    [switch]$Install,
    [switch]$Help
)

if ($Help) {
    Write-Host @"
Video Downloader for Ambient Content
===================================
Downloads videos from free platforms using yt-dlp

Parameters:
  -URLs        Array of video URLs to download
  -OutputDir   Output directory (default: ../Source-Files)
  -Quality     Video quality (default: best[height<=1080])
  -AudioOnly   Download audio only
  -Install     Install yt-dlp if not available
  
Supported Sites:
  - YouTube (free content only)
  - Pixabay
  - Pexels  
  - Archive.org
  - Many other free platforms
  
Examples:
  .\video_downloader.ps1 -URLs @("https://pixabay.com/videos/...") -Install
  .\video_downloader.ps1 -URLs @("url1", "url2") -Quality "720p"
  .\video_downloader.ps1 -URLs @("url") -AudioOnly
"@
    return
}

# Install yt-dlp if requested or not available
if ($Install -or (-not (Get-Command yt-dlp -ErrorAction SilentlyContinue))) {
    Write-Host "📦 Installing yt-dlp..." -ForegroundColor Yellow
    
    # Try winget first
    try {
        winget install yt-dlp
        Write-Host "✅ yt-dlp installed via winget" -ForegroundColor Green
    } catch {
        # Fallback to pip
        try {
            pip install yt-dlp
            Write-Host "✅ yt-dlp installed via pip" -ForegroundColor Green
        } catch {
            Write-Error "❌ Failed to install yt-dlp. Please install manually: https://github.com/yt-dlp/yt-dlp"
            return
        }
    }
}

# Check if yt-dlp is available
if (-not (Get-Command yt-dlp -ErrorAction SilentlyContinue)) {
    Write-Error "❌ yt-dlp not found. Use -Install to install it."
    return
}

if (-not $URLs -or $URLs.Count -eq 0) {
    Write-Error "❌ Please provide URLs to download. Use -Help for examples."
    return
}

# Create output directory
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

Write-Host "🎬 Video Downloader" -ForegroundColor Cyan
Write-Host "📂 Output: $OutputDir"
Write-Host "🎯 Quality: $Quality"
Write-Host "📋 URLs: $($URLs.Count)"
Write-Host "=" * 50

$successCount = 0
$failCount = 0

foreach ($url in $URLs) {
    Write-Host "`n📹 Processing: $url" -ForegroundColor Yellow
    
    try {
        # Build yt-dlp command
        $ytdlArgs = @(
            $url
            "--output", "$OutputDir/%(title)s.%(ext)s"
            "--format", $Quality
            "--no-playlist"
            "--write-info-json"
        )
        
        if ($AudioOnly) {
            $ytdlArgs += @("--extract-audio", "--audio-format", "wav")
        }
        
        # Execute download
        & yt-dlp @ytdlArgs
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Downloaded successfully" -ForegroundColor Green
            $successCount++
        } else {
            Write-Host "❌ Download failed" -ForegroundColor Red
            $failCount++
        }
    } catch {
        Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
        $failCount++
    }
}

Write-Host "`n" + "=" * 50
Write-Host "📊 Download Summary:" -ForegroundColor Cyan
Write-Host "✅ Successful: $successCount"
Write-Host "❌ Failed: $failCount"

if ($successCount -gt 0) {
    Write-Host "`n📁 Files saved to: $OutputDir" -ForegroundColor Green
    Write-Host "🎯 Ready for ambient video creation!" -ForegroundColor Cyan
}