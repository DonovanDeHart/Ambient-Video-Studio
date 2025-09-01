# ⚡ Quick Start - Create Your First Ambient Video

## 🎯 **5-Minute Setup**

### **1. Put Your Files Here:**
- **Video loop** → `Source-Files/` folder (example: `fireplace.mp4`)
- **Audio file** → `Source-Files/` folder (example: `crackling.wav`)

### **2. Open PowerShell:**
- **Right-click** the `Tools` folder
- **Select** "Open in Terminal" or "Open PowerShell window here"

### **3. Run This Command:**
```powershell
.\\ambient_video_creator.ps1 -VideoInput "..\\Source-Files\\YOUR_VIDEO.mp4" -AudioInput "..\\Source-Files\\YOUR_AUDIO.wav" -DurationHours 8 -OutputPath "..\\Output\\my_first_ambient.mp4"
```

**Replace:**
- `YOUR_VIDEO.mp4` with your actual video filename
- `YOUR_AUDIO.wav` with your actual audio filename

### **4. Wait and Upload!**
- Script will process automatically (takes 5-15 minutes)
- Find your 8-hour video in the `Output/` folder
- Upload to YouTube! 🎉

---

## 📱 **Real Example:**

If you have:
- Video: `rain_on_window.mp4`
- Audio: `rain_sounds.mp3`

Run:
```powershell
.\\ambient_video_creator.ps1 -VideoInput "..\\Source-Files\\rain_on_window.mp4" -AudioInput "..\\Source-Files\\rain_sounds.mp3" -DurationHours 8 -OutputPath "..\\Output\\rainy_day_8hrs.mp4"
```

**That's it!** Your professional 8-hour ambient video is ready! ⚡