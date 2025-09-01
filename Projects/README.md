# 📋 Projects Folder

**Store your batch configuration files here**

## 📄 Configuration Files
Create JSON files to batch process multiple videos:

Example: `my_ambient_series.json`
```json
{
  "projects": [
    {
      "name": "Cozy Fireplace",
      "video": "../Source-Files/fireplace.mp4",
      "audio": "../Source-Files/crackling.wav", 
      "duration": 8,
      "output": "../Output/fireplace_8hrs.mp4"
    }
  ]
}
```

## 🚀 Usage
```powershell
cd Tools
.\batch_ambient_creator.ps1 -ConfigFile "../Projects/my_ambient_series.json"
```

## 💡 Tips
- Use descriptive project names
- Check file paths are correct
- Test with one project before batching many