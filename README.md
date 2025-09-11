# 🎬 Ambient Video Studio

## Overview

Professional ambient video creation toolkit for 8-10 hour YouTube videos

## 📁 Folder Structure

```text
Ambient-Video-Studio/
├── Tools/                    # PowerShell scripts for video creation
├── Projects/                 # Your project configurations  
├── Source-Files/            # Your video loops and audio files
├── Output/                  # Generated ambient videos
├── Examples/                # Sample files and templates
└── README.md               # This guide
```

## 🚀 Quick Start Guide

### **Step 1: Install Prerequisites**

1. **FFmpeg** - Already installed ✅
2. **PowerShell** - Built into Windows ✅

### **Step 2: Prepare Your Files**

1. Put your **video loops** in `Source-Files/` folder
   - Example: `fireplace.mp4` (15-45 seconds, loop-friendly)
2. Put your **audio files** in `Source-Files/` folder
   - Example: `fire_crackling.wav` (any length)

### **Step 3: Create Your First Ambient Video**

**Open PowerShell and navigate to the Tools folder:**

```powershell
cd "C:\\Users\\Dehar\\Desktop\\Special-Ops\\Ambient-Video-Studio\\Tools"
```

**Create an 8-hour ambient video:**

```powershell
.\\ambient_video_creator.ps1 -VideoInput "..\\Source-Files\\your_video.mp4" -AudioInput "..\\Source-Files\\your_audio.wav" -DurationHours 8 -OutputPath "..\\Output\\my_ambient_video.mp4"
```

**That's it!** Your 8-hour seamless ambient video will be created in the Output folder.

## 🛠️ Available Tools

### **1. ambient_video_creator.ps1**

**Main tool** - Creates seamless long-form ambient videos with copilot monitoring support

**Parameters:**

- `-VideoInput` - Path to your video loop file
- `-AudioInput` - Path to your ambient audio file
- `-DurationHours` - Target duration (default: 8 hours)
- `-OutputPath` - Where to save the final video
- `-EnableCopilotMonitoring` - Enable AI progress tracking

**Example:**

```powershell
.\\ambient_video_creator.ps1 -VideoInput "..\\Source-Files\\rain_window.mp4" -AudioInput "..\\Source-Files\\rain_sounds.mp3" -DurationHours 10 -OutputPath "..\\Output\\rain_10hrs.mp4" -EnableCopilotMonitoring
```

### **2. ai_audio_generator.ps1**

**AI-powered audio creator** - Generates ambient audio using AI services with progress monitoring

**Parameters:**

- `-Theme` - Predefined theme (rain, fire, forest, thunder, snow, ocean)
- `-Service` - AI service (elevenlabs, lalals, mubert)
- `-Duration` - Audio duration in seconds
- `-EnableCopilotMonitoring` - Track AI generation progress

**Example:**

```powershell
.\\ai_audio_generator.ps1 -Theme "rain" -Duration 600 -Service "elevenlabs" -EnableCopilotMonitoring
```

### **3. copilot_progress_monitor.ps1**

**🤖 NEW: AI Progress Monitor** - Tracks and monitors AI-assisted operations in real-time

**Features:**
- Real-time progress tracking
- Performance analytics and reporting
- Resource usage monitoring
- Interactive dashboard
- Historical data analysis

**Examples:**

```powershell
# Show real-time dashboard
.\\copilot_progress_monitor.ps1 -ShowDashboard

# Generate progress report
.\\copilot_progress_monitor.ps1 -GenerateReport

# Get current status
.\\copilot_progress_monitor.ps1 -GetStatus
```

### **2. audio_loop_optimizer.ps1**

**Audio enhancer** - Removes clicks and optimizes audio for looping

**Parameters:**

- `-InputAudio` - Source audio file
- `-OutputAudio` - Optimized output file
- `-RemoveNoise` - Apply noise reduction
- `-Normalize` - Normalize audio levels

**Example:**

```powershell
.\\audio_loop_optimizer.ps1 -InputAudio "..\\Source-Files\\crackling.wav" -OutputAudio "..\\Source-Files\\crackling_optimized.wav" -RemoveNoise -Normalize
```

### **3. batch_ambient_creator.ps1**

**Batch processor** - Create multiple videos from a configuration file

**Usage:**

```powershell
.\\batch_ambient_creator.ps1 -ConfigFile "..\\Projects\\my_batch.json"
```

## 📝 Complete Workflow Example

Let's create a cozy fireplace video step by step:

### **1. Prepare Files**

- Video: `fireplace_loop.mp4` (30-second loop of flames)
- Audio: `fire_crackling.wav` (crackling fire sounds)

Place both in `Source-Files/` folder.

### **2. Optimize Audio (Optional)**

```powershell
cd Tools
.\\audio_loop_optimizer.ps1 -InputAudio "..\\Source-Files\\fire_crackling.wav" -OutputAudio "..\\Source-Files\\fire_crackling_clean.wav" -RemoveNoise -Normalize
```

### **3. Create 8-Hour Video**

```powershell
.\\ambient_video_creator.ps1 -VideoInput "..\\Source-Files\\fireplace_loop.mp4" -AudioInput "..\\Source-Files\\fire_crackling_clean.wav" -DurationHours 8 -OutputPath "..\\Output\\cozy_fireplace_8hrs.mp4"
```

### **4. Upload to YouTube**

Your `cozy_fireplace_8hrs.mp4` is now ready for YouTube! 🎉

## 🔧 Troubleshooting

**"Video file not found"**

- Make sure your video is in the `Source-Files/` folder
- Use double quotes around file paths with spaces
- Check the file extension matches exactly

**"Audio file not found"**

- Same as above for audio files
- Supported formats: WAV, MP3, FLAC, etc.

**"FFmpeg not found"**

- Already installed in your system ✅
- If issues persist, restart PowerShell

## 💡 Pro Tips

### **Best Video Loops:**

- 15-45 seconds long
- Seamless start/end points
- Gentle, repeatable motion (flames, rain, etc.)
- 1920x1080 resolution recommended

### **Best Audio:**

- High quality (48kHz/24-bit preferred)
- Natural ambient sounds
- No sudden volume changes
- Long enough to avoid obvious repetition

### **File Organization:**

```text
Source-Files/
├── Videos/
│   ├── fireplace_loop.mp4
│   ├── rain_window.mp4
│   └── forest_cabin.mp4
└── Audio/
    ├── fire_crackling.wav
    ├── rain_sounds.mp3
    └── night_crickets.wav
```

## 🤖 Copilot Progress Monitoring

### **NEW: AI Operation Tracking**

Monitor and track the progress of AI-assisted operations in real-time:

- **Real-time Dashboard**: Visual progress tracking with live updates
- **Performance Analytics**: Success rates, completion times, resource usage
- **Comprehensive Reporting**: Detailed analytics and historical data
- **Smart Alerts**: Notifications for long-running or failed operations

### **Quick Start with Monitoring**

1. **Enable in GUI**: Check "Enable Copilot Monitoring" checkbox
2. **Run AI Operations**: Any AI tool will be automatically tracked
3. **View Progress**: Click "📊 Dashboard" to see real-time status
4. **Generate Reports**: Click "📋 Report" for detailed analytics

### **Command Line Monitoring**

```powershell
# Start monitoring dashboard
.\\Tools\\copilot_progress_monitor.ps1 -ShowDashboard

# Run test with monitoring
.\\Tools\\test_copilot_monitor.ps1 -EnableCopilotMonitoring

# Quick launcher
.\\LAUNCH_COPILOT_MONITOR.bat
```

See **COPILOT_MONITORING_GUIDE.md** for complete documentation.

## 🎯 Ready to Create!

1. **Add your video loops** to `Source-Files/`
2. **Add your audio files** to `Source-Files/`
3. **Open PowerShell** in the `Tools/` folder
4. **Run the ambient video creator**
5. **Upload to YouTube** and enjoy!

## Final Note

Your ambient video studio is ready for professional 8-10 hour video creation! 🚀

<!-- End of README -->
