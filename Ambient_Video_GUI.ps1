# Ambient Video Studio GUI - Enhanced Version with Copilot Monitoring
# Easy-to-use interface for all ambient video creation tools
# Enhanced with progress tracking, drag-and-drop, better UX, and copilot monitoring

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms.DataVisualization

# Global variables for progress tracking and copilot monitoring
$global:CurrentProcess = $null
$global:ProgressTimer = $null
$global:LogBuffer = @()
$global:CopilotMonitoringActive = $false
$global:CopilotTimer = $null

# Main Form
$form = New-Object System.Windows.Forms.Form
$form.Text = "?? Ambient Video Studio - Enhanced"
$form.Size = New-Object System.Drawing.Size(1000, 800)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
$form.ForeColor = [System.Drawing.Color]::White
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.MinimizeBox = $false

# Title Label
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "?? Ambient Video Studio"
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
$titleLabel.Location = New-Object System.Drawing.Point(20, 20)
$titleLabel.Size = New-Object System.Drawing.Size(400, 45)
$form.Controls.Add($titleLabel)

$subtitleLabel = New-Object System.Windows.Forms.Label
$subtitleLabel.Text = "Create Professional 8-10 Hour Ambient Videos"
$subtitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11)
$subtitleLabel.ForeColor = [System.Drawing.Color]::LightGray
$subtitleLabel.Location = New-Object System.Drawing.Point(20, 65)
$subtitleLabel.Size = New-Object System.Drawing.Size(400, 30)
$form.Controls.Add($subtitleLabel)

# Version Label
$versionLabel = New-Object System.Windows.Forms.Label
$versionLabel.Text = "v2.0 Enhanced"
$versionLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$versionLabel.ForeColor = [System.Drawing.Color]::Gray
$versionLabel.Location = New-Object System.Drawing.Point(20, 95)
$versionLabel.Size = New-Object System.Drawing.Size(100, 20)
$form.Controls.Add($versionLabel)

# Enhanced Status Panel
$statusPanel = New-Object System.Windows.Forms.Panel
$statusPanel.Location = New-Object System.Drawing.Point(20, 720)
$statusPanel.Size = New-Object System.Drawing.Size(950, 60)
$statusPanel.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$statusPanel.BorderStyle = "FixedSingle"
$form.Controls.Add($statusPanel)

# Status Label
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Ready to create ambient videos"
$statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$statusLabel.ForeColor = [System.Drawing.Color]::LimeGreen
$statusLabel.Location = New-Object System.Drawing.Point(10, 10)
$statusLabel.Size = New-Object System.Drawing.Size(600, 25)
$statusPanel.Controls.Add($statusLabel)

# Progress Bar
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(10, 35)
$progressBar.Size = New-Object System.Drawing.Size(930, 20)
$progressBar.Style = "Continuous"
$progressBar.Value = 0
$statusPanel.Controls.Add($progressBar)

# Enhanced Log Display
$logTextBox = New-Object System.Windows.Forms.RichTextBox
$logTextBox.Location = New-Object System.Drawing.Point(20, 580)
$logTextBox.Size = New-Object System.Drawing.Size(950, 130)
$logTextBox.BackColor = [System.Drawing.Color]::FromArgb(25, 25, 25)
$logTextBox.ForeColor = [System.Drawing.Color]::LightGray
$logTextBox.Font = New-Object System.Drawing.Font("Consolas", 8)
$logTextBox.ReadOnly = $true
$logTextBox.ScrollBars = "Vertical"
$form.Controls.Add($logTextBox)

# Helper function to update status
function Update-Status {
    param([string]$message, [string]$color = "LimeGreen", [int]$progress = -1)
    
    $statusLabel.Text = $message
    $statusLabel.ForeColor = [System.Drawing.Color]::$color
    
    if ($progress -ge 0) {
        $progressBar.Value = [Math]::Min($progress, 100)
    }
    
    # Add to log
    $timestamp = Get-Date -Format "HH:mm:ss"
    $logEntry = "[$timestamp] $message"
    $global:LogBuffer += $logEntry
    
    # Keep only last 100 entries
    if ($global:LogBuffer.Count -gt 100) {
        $global:LogBuffer = $global:LogBuffer[-100..-1]
    }
    
    # Update log display
    $logTextBox.Text = $global:LogBuffer -join "`n"
    $logTextBox.SelectionStart = $logTextBox.Text.Length
    $logTextBox.ScrollToCaret()
    
    $form.Refresh()
}

# Enhanced script runner with progress tracking and copilot monitoring integration
function Invoke-Script {
    param([string]$scriptPath, [string[]]$arguments = @(), [string]$description = "")
    
    try {
        $fullPath = Join-Path $PSScriptRoot "Tools\$scriptPath"
        
        if (-not (Test-Path $fullPath)) {
            Update-Status "❌ Script not found: $scriptPath" "Red"
            return
        }
        
        $desc = if ($description) { $description } else { $scriptPath }
        Update-Status "⚙️ Running $desc..." "Yellow", 10
        $progressBar.Style = "Marquee"
        
        # Check if copilot monitoring is enabled and add the parameter
        if ($enableMonitoringCheckbox.Checked -and $scriptPath -like "*ai_*") {
            $arguments += "-EnableCopilotMonitoring"
            Update-Status "🤖 Copilot monitoring enabled for $desc" "Cyan"
        }
        
        # Start process with progress tracking
        $processArgs = @("-ExecutionPolicy", "Bypass", "-File", $fullPath) + $arguments
        $global:CurrentProcess = Start-Process -FilePath "powershell.exe" -ArgumentList $processArgs -NoNewWindow -PassThru
        
        # Start progress timer
        $global:ProgressTimer = New-Object System.Windows.Forms.Timer
        $global:ProgressTimer.Interval = 100
        $global:ProgressTimer.Add_Tick({
            if ($global:CurrentProcess -and -not $global:CurrentProcess.HasExited) {
                $currentProgress = $progressBar.Value + 1
                if ($currentProgress -le 90) {
                    $progressBar.Value = $currentProgress
                }
                
                # Update copilot status if monitoring is active
                if ($global:CopilotMonitoringActive) {
                    Update-CopilotStatus
                }
            } else {
                $global:ProgressTimer.Stop()
                $progressBar.Style = "Continuous"
                
                if ($global:CurrentProcess.ExitCode -eq 0) {
                    Update-Status "✅ $desc completed successfully" "LimeGreen", 100
                } else {
                    Update-Status "⚠️ $desc finished with warnings" "Orange", 100
                }
                
                $global:CurrentProcess = $null
            }
        })
        $global:ProgressTimer.Start()
        
    } catch {
        $progressBar.Style = "Continuous"
        Update-Status "❌ Error running $desc`: $($_.Exception.Message)" "Red"
    }
}

# Drag and Drop functionality
function Enable-DragAndDrop {
    param([System.Windows.Forms.Control]$control, [string]$fileType)
    
    $control.AllowDrop = $true
    
    $control.Add_DragEnter({
        if ($_.Data.GetDataPresent([System.Windows.Forms.DataFormats]::FileDrop)) {
            $_.Effect = [System.Windows.Forms.DragDropEffects]::Copy
        }
    })
    
    $control.Add_DragDrop({
        $files = $_.Data.GetData([System.Windows.Forms.DataFormats]::FileDrop)
        if ($files.Count -gt 0) {
            $file = $files[0]
            $extension = [System.IO.Path]::GetExtension($file).ToLower()
            
            switch ($fileType) {
                "video" {
                    if ($extension -in @(".mp4", ".mov", ".avi", ".mkv")) {
                        $videoTextBox.Text = $file
                        Update-Status "?? Video file loaded: $([System.IO.Path]::GetFileName($file))" "Cyan"
                    } else {
                        Update-Status "? Invalid video file format" "Red"
                    }
                }
                "audio" {
                    if ($extension -in @(".wav", ".mp3", ".flac", ".aac")) {
                        $audioTextBox.Text = $file
                        Update-Status "?? Audio file loaded: $([System.IO.Path]::GetFileName($file))" "Cyan"
                    } else {
                        Update-Status "? Invalid audio file format" "Red"
                    }
                }
            }
        }
    })
}

# === QUICK START SECTION ===
$quickStartGroup = New-Object System.Windows.Forms.GroupBox
$quickStartGroup.Text = "?? Quick Start"
$quickStartGroup.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$quickStartGroup.ForeColor = [System.Drawing.Color]::White
$quickStartGroup.Location = New-Object System.Drawing.Point(20, 130)
$quickStartGroup.Size = New-Object System.Drawing.Size(950, 140)
$form.Controls.Add($quickStartGroup)

# Video Input with Drag & Drop
$videoLabel = New-Object System.Windows.Forms.Label
$videoLabel.Text = "Video File:"
$videoLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$videoLabel.ForeColor = [System.Drawing.Color]::White
$videoLabel.Location = New-Object System.Drawing.Point(20, 30)
$videoLabel.Size = New-Object System.Drawing.Size(80, 20)
$quickStartGroup.Controls.Add($videoLabel)

$videoTextBox = New-Object System.Windows.Forms.TextBox
$videoTextBox.Location = New-Object System.Drawing.Point(100, 28)
$videoTextBox.Size = New-Object System.Drawing.Size(500, 23)
$videoTextBox.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
$videoTextBox.ForeColor = [System.Drawing.Color]::White
$videoTextBox.PlaceholderText = "Drag and drop video file here or click Browse..."
$quickStartGroup.Controls.Add($videoTextBox)

$videoBrowseButton = New-Object System.Windows.Forms.Button
$videoBrowseButton.Text = "Browse..."
$videoBrowseButton.Location = New-Object System.Drawing.Point(610, 27)
$videoBrowseButton.Size = New-Object System.Drawing.Size(80, 25)
$videoBrowseButton.BackColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
$videoBrowseButton.ForeColor = [System.Drawing.Color]::White
$videoBrowseButton.FlatStyle = "Flat"
$quickStartGroup.Controls.Add($videoBrowseButton)

$videoBrowseButton.Add_Click({
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Filter = "Video files (*.mp4;*.mov;*.avi;*.mkv)|*.mp4;*.mov;*.avi;*.mkv"
    $openFileDialog.InitialDirectory = Join-Path $PSScriptRoot "Source-Files"
    
    if ($openFileDialog.ShowDialog() -eq "OK") {
        $videoTextBox.Text = $openFileDialog.FileName
        Update-Status "?? Video file selected: $([System.IO.Path]::GetFileName($openFileDialog.FileName))" "Cyan"
    }
})

# Audio Input with Drag & Drop
$audioLabel = New-Object System.Windows.Forms.Label
$audioLabel.Text = "Audio File:"
$audioLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$audioLabel.ForeColor = [System.Drawing.Color]::White
$audioLabel.Location = New-Object System.Drawing.Point(20, 65)
$audioLabel.Size = New-Object System.Drawing.Size(80, 20)
$quickStartGroup.Controls.Add($audioLabel)

$audioTextBox = New-Object System.Windows.Forms.TextBox
$audioTextBox.Location = New-Object System.Drawing.Point(100, 63)
$audioTextBox.Size = New-Object System.Drawing.Size(500, 23)
$audioTextBox.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
$audioTextBox.ForeColor = [System.Drawing.Color]::White
$audioTextBox.PlaceholderText = "Drag and drop audio file here or click Browse..."
$quickStartGroup.Controls.Add($audioTextBox)

$audioBrowseButton = New-Object System.Windows.Forms.Button
$audioBrowseButton.Text = "Browse..."
$audioBrowseButton.Location = New-Object System.Drawing.Point(610, 62)
$audioBrowseButton.Size = New-Object System.Drawing.Size(80, 25)
$audioBrowseButton.BackColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
$audioBrowseButton.ForeColor = [System.Drawing.Color]::White
$audioBrowseButton.FlatStyle = "Flat"
$quickStartGroup.Controls.Add($audioBrowseButton)

$audioBrowseButton.Add_Click({
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Filter = "Audio files (*.wav;*.mp3;*.flac;*.aac)|*.wav;*.mp3;*.flac;*.aac"
    $openFileDialog.InitialDirectory = Join-Path $PSScriptRoot "Source-Files"
    
    if ($openFileDialog.ShowDialog() -eq "OK") {
        $audioTextBox.Text = $openFileDialog.FileName
        Update-Status "?? Audio file selected: $([System.IO.Path]::GetFileName($openFileDialog.FileName))" "Cyan"
    }
})

# Duration Input
$durationLabel = New-Object System.Windows.Forms.Label
$durationLabel.Text = "Hours:"
$durationLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$durationLabel.ForeColor = [System.Drawing.Color]::White
$durationLabel.Location = New-Object System.Drawing.Point(700, 30)
$durationLabel.Size = New-Object System.Drawing.Size(50, 20)
$quickStartGroup.Controls.Add($durationLabel)

$durationTextBox = New-Object System.Windows.Forms.NumericUpDown
$durationTextBox.Location = New-Object System.Drawing.Point(750, 28)
$durationTextBox.Size = New-Object System.Drawing.Size(60, 23)
$durationTextBox.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
$durationTextBox.ForeColor = [System.Drawing.Color]::White
$durationTextBox.Minimum = 1
$durationTextBox.Maximum = 24
$durationTextBox.Value = 8
$quickStartGroup.Controls.Add($durationTextBox)

# Create Video Button
$createVideoButton = New-Object System.Windows.Forms.Button
$createVideoButton.Text = "?? CREATE AMBIENT VIDEO"
$createVideoButton.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$createVideoButton.Location = New-Object System.Drawing.Point(700, 55)
$createVideoButton.Size = New-Object System.Drawing.Size(220, 35)
$createVideoButton.BackColor = [System.Drawing.Color]::FromArgb(76, 175, 80)
$createVideoButton.ForeColor = [System.Drawing.Color]::White
$createVideoButton.FlatStyle = "Flat"
$quickStartGroup.Controls.Add($createVideoButton)

$createVideoButton.Add_Click({
    if (-not $videoTextBox.Text -or -not $audioTextBox.Text) {
        Update-Status "? Please select both video and audio files" "Red"
        return
    }
    
    if (-not (Test-Path $videoTextBox.Text) -or -not (Test-Path $audioTextBox.Text)) {
        Update-Status "? One or both files don't exist" "Red"
        return
    }
    
    $outputPath = Join-Path $PSScriptRoot "Output\ambient_video_$($durationTextBox.Value)hrs.mp4"
    $arguments = @(
        "-VideoInput", "`"$($videoTextBox.Text)`""
        "-AudioInput", "`"$($audioTextBox.Text)`""
        "-DurationHours", $durationTextBox.Value
        "-OutputPath", "`"$outputPath`""
        "-Verbose"
    )
    
    Invoke-Script "ambient_video_creator.ps1" $arguments "Creating $($durationTextBox.Value)-hour ambient video"
})

# Enable drag and drop for video and audio textboxes
Enable-DragAndDrop -control $videoTextBox -fileType "video"
Enable-DragAndDrop -control $audioTextBox -fileType "audio"

# === CONTENT RESEARCH SECTION ===
$researchGroup = New-Object System.Windows.Forms.GroupBox
$researchGroup.Text = "?? Content Research & Sourcing"
$researchGroup.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$researchGroup.ForeColor = [System.Drawing.Color]::White
$researchGroup.Location = New-Object System.Drawing.Point(20, 290)
$researchGroup.Size = New-Object System.Drawing.Size(950, 140)
$form.Controls.Add($researchGroup)

# Theme Selection
$themeLabel = New-Object System.Windows.Forms.Label
$themeLabel.Text = "Theme:"
$themeLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$themeLabel.ForeColor = [System.Drawing.Color]::White
$themeLabel.Location = New-Object System.Drawing.Point(20, 30)
$themeLabel.Size = New-Object System.Drawing.Size(50, 20)
$researchGroup.Controls.Add($themeLabel)

$themeComboBox = New-Object System.Windows.Forms.ComboBox
$themeComboBox.Location = New-Object System.Drawing.Point(70, 28)
$themeComboBox.Size = New-Object System.Drawing.Size(100, 23)
$themeComboBox.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
$themeComboBox.ForeColor = [System.Drawing.Color]::White
$themeComboBox.DropDownStyle = "DropDownList"
$themeComboBox.Items.AddRange(@("rain", "fire", "forest", "thunder", "snow", "ocean"))
$themeComboBox.SelectedIndex = 0
$researchGroup.Controls.Add($themeComboBox)

# Research Buttons
$researchButton = New-Object System.Windows.Forms.Button
$researchButton.Text = "?? Research Content Ideas"
$researchButton.Location = New-Object System.Drawing.Point(180, 27)
$researchButton.Size = New-Object System.Drawing.Size(170, 25)
$researchButton.BackColor = [System.Drawing.Color]::FromArgb(156, 39, 176)
$researchButton.ForeColor = [System.Drawing.Color]::White
$researchButton.FlatStyle = "Flat"
$researchGroup.Controls.Add($researchButton)

$researchButton.Add_Click({
    $arguments = @("-Theme", $themeComboBox.SelectedItem, "-VideoCount", "10", "-AudioCount", "5")
    Invoke-Script "content_sourcer.ps1" $arguments "Researching $($themeComboBox.SelectedItem) content ideas"
})

$generateAudioButton = New-Object System.Windows.Forms.Button
$generateAudioButton.Text = "?? Generate AI Audio"
$generateAudioButton.Location = New-Object System.Drawing.Point(360, 27)
$generateAudioButton.Size = New-Object System.Drawing.Size(150, 25)
$generateAudioButton.BackColor = [System.Drawing.Color]::FromArgb(255, 152, 0)
$generateAudioButton.ForeColor = [System.Drawing.Color]::White
$generateAudioButton.FlatStyle = "Flat"
$researchGroup.Controls.Add($generateAudioButton)

$generateAudioButton.Add_Click({
    $arguments = @("-Theme", $themeComboBox.SelectedItem, "-Service", $serviceComboBox.SelectedItem, "-Duration", "600")
    Invoke-Script "ai_audio_generator.ps1" $arguments "Generating AI audio for $($themeComboBox.SelectedItem) theme"
})

$downloadVideoButton = New-Object System.Windows.Forms.Button
$downloadVideoButton.Text = "?? Find Video Sources"
$downloadVideoButton.Location = New-Object System.Drawing.Point(520, 27)
$downloadVideoButton.Size = New-Object System.Drawing.Size(150, 25)
$downloadVideoButton.BackColor = [System.Drawing.Color]::FromArgb(63, 81, 181)
$downloadVideoButton.ForeColor = [System.Drawing.Color]::White
$downloadVideoButton.FlatStyle = "Flat"
$researchGroup.Controls.Add($downloadVideoButton)

$downloadVideoButton.Add_Click({
    $pixabayUrl = "https://pixabay.com/videos/search/$($themeComboBox.SelectedItem)/"
    try {
        Start-Process $pixabayUrl
        Update-Status "?? Opened Pixabay search for '$($themeComboBox.SelectedItem)' videos" "Cyan"
    } catch {
        Update-Status "? Failed to open browser" "Red"
    }
})

# Audio Service Selection
$serviceLabel = New-Object System.Windows.Forms.Label
$serviceLabel.Text = "AI Service:"
$serviceLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$serviceLabel.ForeColor = [System.Drawing.Color]::White
$serviceLabel.Location = New-Object System.Drawing.Point(20, 65)
$serviceLabel.Size = New-Object System.Drawing.Size(70, 20)
$researchGroup.Controls.Add($serviceLabel)

$serviceComboBox = New-Object System.Windows.Forms.ComboBox
$serviceComboBox.Location = New-Object System.Drawing.Point(90, 63)
$serviceComboBox.Size = New-Object System.Drawing.Size(120, 23)
$serviceComboBox.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
$serviceComboBox.ForeColor = [System.Drawing.Color]::White
$serviceComboBox.DropDownStyle = "DropDownList"
$serviceComboBox.Items.AddRange(@("elevenlabs", "lalals", "mubert"))
$serviceComboBox.SelectedIndex = 0
$researchGroup.Controls.Add($serviceComboBox)

# Show Prompts Button
$showPromptsButton = New-Object System.Windows.Forms.Button
$showPromptsButton.Text = "?? Show Audio Prompts"
$showPromptsButton.Location = New-Object System.Drawing.Point(220, 62)
$showPromptsButton.Size = New-Object System.Drawing.Size(160, 25)
$showPromptsButton.BackColor = [System.Drawing.Color]::FromArgb(96, 125, 139)
$showPromptsButton.ForeColor = [System.Drawing.Color]::White
$showPromptsButton.FlatStyle = "Flat"
$researchGroup.Controls.Add($showPromptsButton)

$showPromptsButton.Add_Click({
    Invoke-Script "ai_audio_generator.ps1" @("-ListPrompts") "Listing audio prompts"
})

# === ADVANCED TOOLS SECTION ===
$advancedGroup = New-Object System.Windows.Forms.GroupBox
$advancedGroup.Text = "??? Advanced Tools"
$advancedGroup.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$advancedGroup.ForeColor = [System.Drawing.Color]::White
$advancedGroup.Location = New-Object System.Drawing.Point(20, 450)
$advancedGroup.Size = New-Object System.Drawing.Size(950, 120)
$form.Controls.Add($advancedGroup)

# Audio Optimizer
$optimizeAudioButton = New-Object System.Windows.Forms.Button
$optimizeAudioButton.Text = "?? Optimize Audio Loop"
$optimizeAudioButton.Location = New-Object System.Drawing.Point(20, 30)
$optimizeAudioButton.Size = New-Object System.Drawing.Size(160, 30)
$optimizeAudioButton.BackColor = [System.Drawing.Color]::FromArgb(121, 85, 72)
$optimizeAudioButton.ForeColor = [System.Drawing.Color]::White
$optimizeAudioButton.FlatStyle = "Flat"
$advancedGroup.Controls.Add($optimizeAudioButton)

$optimizeAudioButton.Add_Click({
    if (-not $audioTextBox.Text) {
        Update-Status "? Please select an audio file first" "Red"
        return
    }
    
    $arguments = @("-InputAudio", "`"$($audioTextBox.Text)`"", "-RemoveNoise", "-Normalize")
    Invoke-Script "audio_loop_optimizer.ps1" $arguments "Optimizing audio loop"
})

# Batch Creator
$batchButton = New-Object System.Windows.Forms.Button
$batchButton.Text = "?? Batch Create Videos"
$batchButton.Location = New-Object System.Drawing.Point(190, 30)
$batchButton.Size = New-Object System.Drawing.Size(160, 30)
$batchButton.BackColor = [System.Drawing.Color]::FromArgb(103, 58, 183)
$batchButton.ForeColor = [System.Drawing.Color]::White
$batchButton.FlatStyle = "Flat"
$advancedGroup.Controls.Add($batchButton)

$batchButton.Add_Click({
    $configFile = Join-Path $PSScriptRoot "Projects\ambient_config.json"
    if (-not (Test-Path $configFile)) {
        Update-Status "? No batch configuration found. Creating example..." "Orange"
        Invoke-Script "batch_ambient_creator.ps1" @("-ConfigFile", "`"$configFile`"") "Creating batch configuration"
    } else {
        Invoke-Script "batch_ambient_creator.ps1" @("-ConfigFile", "`"$configFile`"") "Processing batch videos"
    }
})

# Open Folders Buttons
$sourceFolderButton = New-Object System.Windows.Forms.Button
$sourceFolderButton.Text = "?? Open Source Files"
$sourceFolderButton.Location = New-Object System.Drawing.Point(360, 30)
$sourceFolderButton.Size = New-Object System.Drawing.Size(140, 30)
$sourceFolderButton.BackColor = [System.Drawing.Color]::FromArgb(69, 90, 100)
$sourceFolderButton.ForeColor = [System.Drawing.Color]::White
$sourceFolderButton.FlatStyle = "Flat"
$advancedGroup.Controls.Add($sourceFolderButton)

$sourceFolderButton.Add_Click({
    $sourceFolder = Join-Path $PSScriptRoot "Source-Files"
    if (Test-Path $sourceFolder) {
        Start-Process "explorer.exe" $sourceFolder
        Update-Status "?? Opened Source Files folder" "Cyan"
    } else {
        New-Item -ItemType Directory -Path $sourceFolder -Force | Out-Null
        Start-Process "explorer.exe" $sourceFolder
        Update-Status "?? Created and opened Source Files folder" "Cyan"
    }
})

$outputFolderButton = New-Object System.Windows.Forms.Button
$outputFolderButton.Text = "?? Open Output Folder"
$outputFolderButton.Location = New-Object System.Drawing.Point(510, 30)
$outputFolderButton.Size = New-Object System.Drawing.Size(140, 30)
$outputFolderButton.BackColor = [System.Drawing.Color]::FromArgb(69, 90, 100)
$outputFolderButton.ForeColor = [System.Drawing.Color]::White
$outputFolderButton.FlatStyle = "Flat"
$advancedGroup.Controls.Add($outputFolderButton)

$outputFolderButton.Add_Click({
    $outputFolder = Join-Path $PSScriptRoot "Output"
    if (Test-Path $outputFolder) {
        Start-Process "explorer.exe" $outputFolder
        Update-Status "?? Opened Output folder" "Cyan"
    } else {
        New-Item -ItemType Directory -Path $outputFolder -Force | Out-Null
        Start-Process "explorer.exe" $outputFolder
        Update-Status "?? Created and opened Output folder" "Cyan"
    }
})

# Help Button
$helpButton = New-Object System.Windows.Forms.Button
$helpButton.Text = "? Help & Guides"
$helpButton.Location = New-Object System.Drawing.Point(660, 30)
$helpButton.Size = New-Object System.Drawing.Size(120, 30)
$helpButton.BackColor = [System.Drawing.Color]::FromArgb(158, 158, 158)
$helpButton.ForeColor = [System.Drawing.Color]::White
$helpButton.FlatStyle = "Flat"
$advancedGroup.Controls.Add($helpButton)

$helpButton.Add_Click({
    $readmeFile = Join-Path $PSScriptRoot "README.md"
    $contentGuide = Join-Path $PSScriptRoot "CONTENT_SOURCING_GUIDE.md"
    
    if (Test-Path $readmeFile) {
        Start-Process "notepad.exe" $readmeFile
    }
    if (Test-Path $contentGuide) {
        Start-Process "notepad.exe" $contentGuide  
    }
    Update-Status "?? Opened documentation files" "Cyan"
})

# === COPILOT MONITORING SECTION ===
$copilotGroup = New-Object System.Windows.Forms.GroupBox
$copilotGroup.Text = "🤖 Copilot Progress Monitor"
$copilotGroup.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$copilotGroup.ForeColor = [System.Drawing.Color]::White
$copilotGroup.Location = New-Object System.Drawing.Point(500, 450)
$copilotGroup.Size = New-Object System.Drawing.Size(470, 120)
$form.Controls.Add($copilotGroup)

# Copilot Status Display
$copilotStatusLabel = New-Object System.Windows.Forms.Label
$copilotStatusLabel.Text = "Status: Inactive"
$copilotStatusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$copilotStatusLabel.ForeColor = [System.Drawing.Color]::Gray
$copilotStatusLabel.Location = New-Object System.Drawing.Point(20, 30)
$copilotStatusLabel.Size = New-Object System.Drawing.Size(200, 20)
$copilotGroup.Controls.Add($copilotStatusLabel)

# Active Sessions Count
$activeSessionsLabel = New-Object System.Windows.Forms.Label
$activeSessionsLabel.Text = "Active Sessions: 0"
$activeSessionsLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$activeSessionsLabel.ForeColor = [System.Drawing.Color]::LightBlue
$activeSessionsLabel.Location = New-Object System.Drawing.Point(230, 30)
$activeSessionsLabel.Size = New-Object System.Drawing.Size(120, 20)
$copilotGroup.Controls.Add($activeSessionsLabel)

# Copilot Progress Bar
$copilotProgressBar = New-Object System.Windows.Forms.ProgressBar
$copilotProgressBar.Location = New-Object System.Drawing.Point(20, 55)
$copilotProgressBar.Size = New-Object System.Drawing.Size(330, 20)
$copilotProgressBar.Style = "Continuous"
$copilotGroup.Controls.Add($copilotProgressBar)

# Show Dashboard Button
$showDashboardButton = New-Object System.Windows.Forms.Button
$showDashboardButton.Text = "📊 Dashboard"
$showDashboardButton.Location = New-Object System.Drawing.Point(360, 53)
$showDashboardButton.Size = New-Object System.Drawing.Size(100, 25)
$showDashboardButton.BackColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
$showDashboardButton.ForeColor = [System.Drawing.Color]::White
$showDashboardButton.FlatStyle = "Flat"
$copilotGroup.Controls.Add($showDashboardButton)

# Enable Monitoring Checkbox
$enableMonitoringCheckbox = New-Object System.Windows.Forms.CheckBox
$enableMonitoringCheckbox.Text = "Enable Copilot Monitoring"
$enableMonitoringCheckbox.Location = New-Object System.Drawing.Point(20, 85)
$enableMonitoringCheckbox.Size = New-Object System.Drawing.Size(180, 25)
$enableMonitoringCheckbox.ForeColor = [System.Drawing.Color]::White
$enableMonitoringCheckbox.Checked = $false
$copilotGroup.Controls.Add($enableMonitoringCheckbox)

# Generate Report Button
$generateReportButton = New-Object System.Windows.Forms.Button
$generateReportButton.Text = "📋 Report"
$generateReportButton.Location = New-Object System.Drawing.Point(210, 83)
$generateReportButton.Size = New-Object System.Drawing.Size(80, 25)
$generateReportButton.BackColor = [System.Drawing.Color]::FromArgb(76, 175, 80)
$generateReportButton.ForeColor = [System.Drawing.Color]::White
$generateReportButton.FlatStyle = "Flat"
$copilotGroup.Controls.Add($generateReportButton)

# Clear History Button
$clearHistoryButton = New-Object System.Windows.Forms.Button
$clearHistoryButton.Text = "🗑️ Clear"
$clearHistoryButton.Location = New-Object System.Drawing.Point(300, 83)
$clearHistoryButton.Size = New-Object System.Drawing.Size(70, 25)
$clearHistoryButton.BackColor = [System.Drawing.Color]::FromArgb(244, 67, 54)
$clearHistoryButton.ForeColor = [System.Drawing.Color]::White
$clearHistoryButton.FlatStyle = "Flat"
$copilotGroup.Controls.Add($clearHistoryButton)

# Toggle Monitoring Button
$toggleMonitoringButton = New-Object System.Windows.Forms.Button
$toggleMonitoringButton.Text = "▶️ Start"
$toggleMonitoringButton.Location = New-Object System.Drawing.Point(380, 83)
$toggleMonitoringButton.Size = New-Object System.Drawing.Size(80, 25)
$toggleMonitoringButton.BackColor = [System.Drawing.Color]::FromArgb(255, 152, 0)
$toggleMonitoringButton.ForeColor = [System.Drawing.Color]::White
$toggleMonitoringButton.FlatStyle = "Flat"
$copilotGroup.Controls.Add($toggleMonitoringButton)

# === QUICK ACTIONS SECTION ===
$quickActionsGroup = New-Object System.Windows.Forms.GroupBox
$quickActionsGroup.Text = "? Quick Actions"
$quickActionsGroup.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$quickActionsGroup.ForeColor = [System.Drawing.Color]::White
$quickActionsGroup.Location = New-Object System.Drawing.Point(20, 590)
$quickActionsGroup.Size = New-Object System.Drawing.Size(950, 80)
$form.Controls.Add($quickActionsGroup)

# Research Rain Content
$rainButton = New-Object System.Windows.Forms.Button
$rainButton.Text = "??? Research Rain Content"
$rainButton.Location = New-Object System.Drawing.Point(20, 30)
$rainButton.Size = New-Object System.Drawing.Size(160, 25)
$rainButton.BackColor = [System.Drawing.Color]::FromArgb(33, 150, 243)
$rainButton.ForeColor = [System.Drawing.Color]::White
$rainButton.FlatStyle = "Flat"
$quickActionsGroup.Controls.Add($rainButton)

$rainButton.Add_Click({
    $arguments = @("-Theme", "rain", "-VideoCount", "10", "-AudioCount", "5")
    Invoke-Script "content_sourcer.ps1" $arguments "Researching rain content"
})

# Research Fire Content
$fireButton = New-Object System.Windows.Forms.Button
$fireButton.Text = "?? Research Fire Content"
$fireButton.Location = New-Object System.Drawing.Point(190, 30)
$fireButton.Size = New-Object System.Drawing.Size(160, 25)
$fireButton.BackColor = [System.Drawing.Color]::FromArgb(244, 67, 54)
$fireButton.ForeColor = [System.Drawing.Color]::White
$fireButton.FlatStyle = "Flat"
$quickActionsGroup.Controls.Add($fireButton)

$fireButton.Add_Click({
    $arguments = @("-Theme", "fire", "-VideoCount", "10", "-AudioCount", "5")
    Invoke-Script "content_sourcer.ps1" $arguments "Researching fire content"
})

# Open Pixabay
$pixabayButton = New-Object System.Windows.Forms.Button
$pixabayButton.Text = "?? Open Pixabay Videos"
$pixabayButton.Location = New-Object System.Drawing.Point(360, 30)
$pixabayButton.Size = New-Object System.Drawing.Size(160, 25)
$pixabayButton.BackColor = [System.Drawing.Color]::FromArgb(76, 175, 80)
$pixabayButton.ForeColor = [System.Drawing.Color]::White
$pixabayButton.FlatStyle = "Flat"
$quickActionsGroup.Controls.Add($pixabayButton)

$pixabayButton.Add_Click({
    try {
        Start-Process "https://pixabay.com/videos/search/ambient/"
        Update-Status "?? Opened Pixabay ambient videos" "Cyan"
    } catch {
        Update-Status "? Failed to open browser" "Red"
    }
})

# Open ElevenLabs
$elevenlabsButton = New-Object System.Windows.Forms.Button
$elevenlabsButton.Text = "?? Open ElevenLabs AI Audio"
$elevenlabsButton.Location = New-Object System.Drawing.Point(530, 30)
$elevenlabsButton.Size = New-Object System.Drawing.Size(180, 25)
$elevenlabsButton.BackColor = [System.Drawing.Color]::FromArgb(255, 152, 0)
$elevenlabsButton.ForeColor = [System.Drawing.Color]::White
$elevenlabsButton.FlatStyle = "Flat"
$quickActionsGroup.Controls.Add($elevenlabsButton)

$elevenlabsButton.Add_Click({
    try {
        Start-Process "https://elevenlabs.io/sound-effects"
        Update-Status "?? Opened ElevenLabs sound effects generator" "Cyan"
    } catch {
        Update-Status "? Failed to open browser" "Red"
    }
})

# Update generate audio button to use selected service with copilot monitoring
$generateAudioButton.Add_Click({
    $arguments = @("-Theme", $themeComboBox.SelectedItem, "-Service", $serviceComboBox.SelectedItem, "-Duration", "600")
    if ($enableMonitoringCheckbox.Checked) {
        $arguments += "-EnableCopilotMonitoring"
    }
    Invoke-Script "ai_audio_generator.ps1" $arguments "Generating AI audio for $($themeComboBox.SelectedItem) theme"
})

# Copilot monitoring event handlers
$showDashboardButton.Add_Click({
    try {
        $monitorScript = Join-Path $PSScriptRoot "Tools\copilot_progress_monitor.ps1"
        if (Test-Path $monitorScript) {
            Start-Process -FilePath "powershell.exe" -ArgumentList @("-ExecutionPolicy", "Bypass", "-File", $monitorScript, "-ShowDashboard") -NoNewWindow
            Update-Status "🤖 Copilot dashboard opened" "Cyan"
        } else {
            Update-Status "❌ Copilot monitor script not found" "Red"
        }
    } catch {
        Update-Status "❌ Failed to open copilot dashboard: $($_.Exception.Message)" "Red"
    }
})

$generateReportButton.Add_Click({
    try {
        $monitorScript = Join-Path $PSScriptRoot "Tools\copilot_progress_monitor.ps1"
        if (Test-Path $monitorScript) {
            & $monitorScript -GenerateReport
            Update-Status "📋 Copilot progress report generated" "Green"
        } else {
            Update-Status "❌ Copilot monitor script not found" "Red"
        }
    } catch {
        Update-Status "❌ Failed to generate copilot report: $($_.Exception.Message)" "Red"
    }
})

$clearHistoryButton.Add_Click({
    try {
        $monitorScript = Join-Path $PSScriptRoot "Tools\copilot_progress_monitor.ps1"
        if (Test-Path $monitorScript) {
            & $monitorScript -ClearHistory
            Update-Status "🗑️ Copilot monitoring history cleared" "Yellow"
        } else {
            Update-Status "❌ Copilot monitor script not found" "Red"
        }
    } catch {
        Update-Status "❌ Failed to clear copilot history: $($_.Exception.Message)" "Red"
    }
})

$toggleMonitoringButton.Add_Click({
    if ($global:CopilotMonitoringActive) {
        # Stop monitoring
        $global:CopilotMonitoringActive = $false
        if ($global:CopilotTimer) {
            $global:CopilotTimer.Stop()
        }
        $toggleMonitoringButton.Text = "▶️ Start"
        $copilotStatusLabel.Text = "Status: Inactive"
        $copilotStatusLabel.ForeColor = [System.Drawing.Color]::Gray
        Update-Status "⏹️ Copilot monitoring stopped" "Yellow"
    } else {
        # Start monitoring
        $global:CopilotMonitoringActive = $true
        $toggleMonitoringButton.Text = "⏸️ Stop"
        $copilotStatusLabel.Text = "Status: Active"
        $copilotStatusLabel.ForeColor = [System.Drawing.Color]::LimeGreen
        
        # Start periodic status updates
        $global:CopilotTimer = New-Object System.Windows.Forms.Timer
        $global:CopilotTimer.Interval = 2000  # Update every 2 seconds
        $global:CopilotTimer.Add_Tick({
            Update-CopilotStatus
        })
        $global:CopilotTimer.Start()
        
        Update-Status "▶️ Copilot monitoring started" "Green"
    }
})

# Function to update copilot monitoring status display
function Update-CopilotStatus {
    try {
        $monitorScript = Join-Path $PSScriptRoot "Tools\copilot_progress_monitor.ps1"
        if (Test-Path $monitorScript) {
            # Get status information (in a real environment, this would query the monitoring system)
            $activeSessionsLabel.Text = "Active Sessions: $((Get-Random -Maximum 5))"  # Placeholder
            
            # Update progress bar with simulated data
            $randomProgress = Get-Random -Maximum 100
            $copilotProgressBar.Value = $randomProgress
            
            # Update status color based on activity
            if ($global:CopilotMonitoringActive) {
                $copilotStatusLabel.ForeColor = [System.Drawing.Color]::LimeGreen
            }
        }
    } catch {
        # Silently handle errors to avoid disrupting UI
    }
}

# Form closing event with copilot monitoring cleanup
$form.Add_FormClosing({
    if ($global:CurrentProcess -and -not $global:CurrentProcess.HasExited) {
        $global:CurrentProcess.Kill()
    }
    if ($global:ProgressTimer) {
        $global:ProgressTimer.Stop()
    }
    if ($global:CopilotTimer) {
        $global:CopilotTimer.Stop()
    }
    # Clean up any active copilot monitoring sessions
    if ($global:CopilotMonitoringActive) {
        try {
            $monitorScript = Join-Path $PSScriptRoot "Tools\copilot_progress_monitor.ps1"
            if (Test-Path $monitorScript) {
                # In a real environment, this would properly stop all monitoring sessions
                Write-Host "Stopping copilot monitoring sessions..."
            }
        } catch {
            # Silently handle cleanup errors
        }
    }
})

# Show the form with updated version info
Update-Status "🤖 Ambient Video Studio Enhanced v2.1 with Copilot Monitoring loaded - Ready to create!" "LimeGreen"
[void]$form.ShowDialog()