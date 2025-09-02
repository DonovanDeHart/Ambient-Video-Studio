# GPU-Enhanced Ambient Video Studio GUI
# Multi-GPU video processing with hardware acceleration monitoring

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms.DataVisualization

# Import GPU manager
$gpuManagerPath = Join-Path $PSScriptRoot "Tools\gpu_manager.ps1"
if (Test-Path $gpuManagerPath) {
    . $gpuManagerPath
}

# Global variables for GPU monitoring
$global:CurrentProcess = $null
$global:ProgressTimer = $null
$global:GPUMonitorTimer = $null
$global:LogBuffer = @()
$global:SelectedGPU = -1
$global:GPUList = @()

# Main Form - Enhanced for GPU features
$form = New-Object System.Windows.Forms.Form
$form.Text = "🚀 Ambient Video Studio - GPU Accelerated"
$form.Size = New-Object System.Drawing.Size(1100, 900)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
$form.ForeColor = [System.Drawing.Color]::White
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.MinimizeBox = $false

# Title Section
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "🚀 Ambient Video Studio - GPU Accelerated"
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
$titleLabel.Location = New-Object System.Drawing.Point(20, 20)
$titleLabel.Size = New-Object System.Drawing.Size(600, 40)
$form.Controls.Add($titleLabel)

$subtitleLabel = New-Object System.Windows.Forms.Label
$subtitleLabel.Text = "Hardware-Accelerated 8-10 Hour Ambient Video Creation"
$subtitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11)
$subtitleLabel.ForeColor = [System.Drawing.Color]::LightGray
$subtitleLabel.Location = New-Object System.Drawing.Point(20, 60)
$subtitleLabel.Size = New-Object System.Drawing.Size(500, 30)
$form.Controls.Add($subtitleLabel)

# GPU Status Panel
$gpuStatusPanel = New-Object System.Windows.Forms.GroupBox
$gpuStatusPanel.Text = "🎮 GPU Status & Configuration"
$gpuStatusPanel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$gpuStatusPanel.ForeColor = [System.Drawing.Color]::White
$gpuStatusPanel.Location = New-Object System.Drawing.Point(20, 100)
$gpuStatusPanel.Size = New-Object System.Drawing.Size(1050, 120)
$form.Controls.Add($gpuStatusPanel)

# GPU Detection Button
$detectGPUButton = New-Object System.Windows.Forms.Button
$detectGPUButton.Text = "🔍 Detect GPUs"
$detectGPUButton.Location = New-Object System.Drawing.Point(20, 30)
$detectGPUButton.Size = New-Object System.Drawing.Size(120, 30)
$detectGPUButton.BackColor = [System.Drawing.Color]::FromArgb(76, 175, 80)
$detectGPUButton.ForeColor = [System.Drawing.Color]::White
$detectGPUButton.FlatStyle = "Flat"
$gpuStatusPanel.Controls.Add($detectGPUButton)

# GPU Selection ComboBox
$gpuLabel = New-Object System.Windows.Forms.Label
$gpuLabel.Text = "Select GPU:"
$gpuLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$gpuLabel.ForeColor = [System.Drawing.Color]::White
$gpuLabel.Location = New-Object System.Drawing.Point(160, 35)
$gpuLabel.Size = New-Object System.Drawing.Size(80, 20)
$gpuStatusPanel.Controls.Add($gpuLabel)

$gpuComboBox = New-Object System.Windows.Forms.ComboBox
$gpuComboBox.Location = New-Object System.Drawing.Point(240, 33)
$gpuComboBox.Size = New-Object System.Drawing.Size(300, 23)
$gpuComboBox.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
$gpuComboBox.ForeColor = [System.Drawing.Color]::White
$gpuComboBox.DropDownStyle = "DropDownList"
$gpuStatusPanel.Controls.Add($gpuComboBox)

# Multi-GPU Checkbox
$multiGPUCheckbox = New-Object System.Windows.Forms.CheckBox
$multiGPUCheckbox.Text = "Use Multi-GPU Processing"
$multiGPUCheckbox.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$multiGPUCheckbox.ForeColor = [System.Drawing.Color]::White
$multiGPUCheckbox.Location = New-Object System.Drawing.Point(560, 35)
$multiGPUCheckbox.Size = New-Object System.Drawing.Size(200, 20)
$gpuStatusPanel.Controls.Add($multiGPUCheckbox)

# Quality Profile Selection
$qualityLabel = New-Object System.Windows.Forms.Label
$qualityLabel.Text = "Quality:"
$qualityLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$qualityLabel.ForeColor = [System.Drawing.Color]::White
$qualityLabel.Location = New-Object System.Drawing.Point(780, 35)
$qualityLabel.Size = New-Object System.Drawing.Size(60, 20)
$gpuStatusPanel.Controls.Add($qualityLabel)

$qualityComboBox = New-Object System.Windows.Forms.ComboBox
$qualityComboBox.Location = New-Object System.Drawing.Point(840, 33)
$qualityComboBox.Size = New-Object System.Drawing.Size(100, 23)
$qualityComboBox.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
$qualityComboBox.ForeColor = [System.Drawing.Color]::White
$qualityComboBox.DropDownStyle = "DropDownList"
$qualityComboBox.Items.AddRange(@("fast", "balanced", "quality"))
$qualityComboBox.SelectedIndex = 1
$gpuStatusPanel.Controls.Add($qualityComboBox)

# GPU Info Display
$gpuInfoLabel = New-Object System.Windows.Forms.Label
$gpuInfoLabel.Text = "Click 'Detect GPUs' to scan for NVIDIA hardware acceleration"
$gpuInfoLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$gpuInfoLabel.ForeColor = [System.Drawing.Color]::LightGray
$gpuInfoLabel.Location = New-Object System.Drawing.Point(20, 70)
$gpuInfoLabel.Size = New-Object System.Drawing.Size(1000, 40)
$gpuStatusPanel.Controls.Add($gpuInfoLabel)

# GPU Detection Function
$detectGPUButton.Add_Click({
    Update-Status "🔍 Detecting NVIDIA GPUs..." "Yellow"
    
    try {
        $global:GPUList = Get-NvidiaGPUs
        
        if ($global:GPUList.Count -eq 0) {
            $gpuInfoLabel.Text = "❌ No NVIDIA GPUs detected - CPU encoding will be used"
            $gpuInfoLabel.ForeColor = [System.Drawing.Color]::Orange
            $gpuComboBox.Items.Clear()
            $gpuComboBox.Items.Add("CPU Only")
            $gpuComboBox.SelectedIndex = 0
            $multiGPUCheckbox.Enabled = $false
            Update-Status "⚠️ No NVIDIA GPUs found - using CPU encoding" "Orange"
        } else {
            $gpuComboBox.Items.Clear()
            $gpuComboBox.Items.Add("Auto-Select Optimal GPU")
            
            foreach ($gpu in $global:GPUList) {
                $gpuComboBox.Items.Add("GPU $($gpu.Index): $($gpu.Name) ($($gpu.MemoryFree)MB free)")
            }
            
            $gpuComboBox.SelectedIndex = 0
            
            $gpuInfoText = "✅ Found $($global:GPUList.Count) NVIDIA GPU(s): "
            $gpuNames = $global:GPUList | ForEach-Object { "$($_.Name) (GPU $($_.Index))" }
            $gpuInfoText += ($gpuNames -join ", ")
            $gpuInfoLabel.Text = $gpuInfoText
            $gpuInfoLabel.ForeColor = [System.Drawing.Color]::LimeGreen
            
            if ($global:GPUList.Count -gt 1) {
                $multiGPUCheckbox.Enabled = $true
                $multiGPUCheckbox.Text = "Use Multi-GPU Processing (Recommended)"
            } else {
                $multiGPUCheckbox.Enabled = $false
                $multiGPUCheckbox.Text = "Multi-GPU Processing (Need 2+ GPUs)"
            }
            
            Update-Status "✅ Detected $($global:GPUList.Count) GPU(s) - hardware acceleration ready!" "LimeGreen"
        }
    } catch {
        $gpuInfoLabel.Text = "❌ Error detecting GPUs: $($_.Exception.Message)"
        $gpuInfoLabel.ForeColor = [System.Drawing.Color]::Red
        Update-Status "❌ GPU detection failed" "Red"
    }
})

# Enhanced Status Panel
$statusPanel = New-Object System.Windows.Forms.Panel
$statusPanel.Location = New-Object System.Drawing.Point(20, 820)
$statusPanel.Size = New-Object System.Drawing.Size(1050, 60)
$statusPanel.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$statusPanel.BorderStyle = "FixedSingle"
$form.Controls.Add($statusPanel)

# Status Label
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "GPU-Enhanced Ambient Video Studio ready"
$statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$statusLabel.ForeColor = [System.Drawing.Color]::LimeGreen
$statusLabel.Location = New-Object System.Drawing.Point(10, 10)
$statusLabel.Size = New-Object System.Drawing.Size(700, 25)
$statusPanel.Controls.Add($statusLabel)

# Progress Bar
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(10, 35)
$progressBar.Size = New-Object System.Drawing.Size(1030, 20)
$progressBar.Style = "Continuous"
$progressBar.Value = 0
$statusPanel.Controls.Add($progressBar)

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
    
    $form.Refresh()
}

# Enhanced script runner with GPU support
function Start-EnhancedScript {
    param([string]$videoPath, [string]$audioPath, [int]$hours, [string]$outputPath)
    
    try {
        $gpuArgs = @()
        
        # Determine GPU configuration
        if ($global:GPUList.Count -gt 0) {
            if ($gpuComboBox.SelectedIndex -eq 0) {
                # Auto-select
                $gpuArgs += @("-TargetGPU", "-1")
            } else {
                # Specific GPU selected
                $selectedGPUIndex = $gpuComboBox.SelectedIndex - 1
                $gpuArgs += @("-TargetGPU", $selectedGPUIndex)
            }
            
            if ($multiGPUCheckbox.Checked -and $global:GPUList.Count -gt 1) {
                $gpuArgs += "-UseMultiGPU"
            }
            
            $gpuArgs += @("-Quality", $qualityComboBox.SelectedItem)
        }
        
        $arguments = @(
            "-VideoInput", "`"$videoPath`""
            "-AudioInput", "`"$audioPath`""
            "-DurationHours", $hours
            "-OutputPath", "`"$outputPath`""
            "-Verbose"
        ) + $gpuArgs
        
        $scriptPath = Join-Path $PSScriptRoot "Tools\enhanced_video_creator.ps1"
        
        if (-not (Test-Path $scriptPath)) {
            Update-Status "❌ Enhanced video creator not found" "Red"
            return
        }
        
        Update-Status "🚀 Starting GPU-accelerated video creation..." "Yellow" 10
        $progressBar.Style = "Marquee"
        
        # Start GPU-accelerated process
        $processArgs = @("-ExecutionPolicy", "Bypass", "-File", $scriptPath) + $arguments
        $global:CurrentProcess = Start-Process -FilePath "powershell.exe" -ArgumentList $processArgs -NoNewWindow -PassThru
        
        # Start enhanced progress timer with GPU monitoring
        $global:ProgressTimer = New-Object System.Windows.Forms.Timer
        $global:ProgressTimer.Interval = 500
        $progressStep = 0
        
        $global:ProgressTimer.Add_Tick({
            if ($global:CurrentProcess -and -not $global:CurrentProcess.HasExited) {
                $script:progressStep++
                $currentProgress = 10 + ($script:progressStep * 0.5)
                if ($currentProgress -le 95) {
                    $progressBar.Value = [int]$currentProgress
                }
                
                # Update GPU info occasionally
                if ($script:progressStep % 10 -eq 0) {
                    Update-GPUStats
                }
            } else {
                $global:ProgressTimer.Stop()
                $progressBar.Style = "Continuous"
                
                if ($global:CurrentProcess.ExitCode -eq 0) {
                    Update-Status "✅ GPU-accelerated video creation completed successfully!" "LimeGreen" 100
                } else {
                    Update-Status "⚠️ Video creation finished with warnings" "Orange" 100
                }
                
                $global:CurrentProcess = $null
            }
        })
        $global:ProgressTimer.Start()
        
    } catch {
        $progressBar.Style = "Continuous"
        Update-Status "❌ Error during GPU processing: $($_.Exception.Message)" "Red"
    }
}

function Update-GPUStats {
    if ($global:GPUList.Count -gt 0) {
        try {
            $currentGPUs = Get-NvidiaGPUs
            $utilizationText = ""
            foreach ($gpu in $currentGPUs) {
                $utilizationText += "GPU$($gpu.Index): $($gpu.Utilization)% "
            }
            Update-Status "🎮 Processing with GPU acceleration - $utilizationText" "Cyan"
        } catch {
            # Ignore GPU stat errors during processing
        }
    }
}

# === QUICK START SECTION ===
$quickStartGroup = New-Object System.Windows.Forms.GroupBox
$quickStartGroup.Text = "🎬 GPU-Accelerated Video Creation"
$quickStartGroup.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$quickStartGroup.ForeColor = [System.Drawing.Color]::White
$quickStartGroup.Location = New-Object System.Drawing.Point(20, 240)
$quickStartGroup.Size = New-Object System.Drawing.Size(1050, 140)
$form.Controls.Add($quickStartGroup)

# Video Input
$videoLabel = New-Object System.Windows.Forms.Label
$videoLabel.Text = "Video File:"
$videoLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$videoLabel.ForeColor = [System.Drawing.Color]::White
$videoLabel.Location = New-Object System.Drawing.Point(20, 30)
$videoLabel.Size = New-Object System.Drawing.Size(80, 20)
$quickStartGroup.Controls.Add($videoLabel)

$videoTextBox = New-Object System.Windows.Forms.TextBox
$videoTextBox.Location = New-Object System.Drawing.Point(100, 28)
$videoTextBox.Size = New-Object System.Drawing.Size(600, 23)
$videoTextBox.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
$videoTextBox.ForeColor = [System.Drawing.Color]::White
$videoTextBox.PlaceholderText = "Select video file for GPU processing..."
$quickStartGroup.Controls.Add($videoTextBox)

$videoBrowseButton = New-Object System.Windows.Forms.Button
$videoBrowseButton.Text = "Browse..."
$videoBrowseButton.Location = New-Object System.Drawing.Point(710, 27)
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
        Update-Status "📹 Video selected for GPU processing: $([System.IO.Path]::GetFileName($openFileDialog.FileName))" "Cyan"
    }
})

# Audio Input
$audioLabel = New-Object System.Windows.Forms.Label
$audioLabel.Text = "Audio File:"
$audioLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$audioLabel.ForeColor = [System.Drawing.Color]::White
$audioLabel.Location = New-Object System.Drawing.Point(20, 65)
$audioLabel.Size = New-Object System.Drawing.Size(80, 20)
$quickStartGroup.Controls.Add($audioLabel)

$audioTextBox = New-Object System.Windows.Forms.TextBox
$audioTextBox.Location = New-Object System.Drawing.Point(100, 63)
$audioTextBox.Size = New-Object System.Drawing.Size(600, 23)
$audioTextBox.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
$audioTextBox.ForeColor = [System.Drawing.Color]::White
$audioTextBox.PlaceholderText = "Select audio file..."
$quickStartGroup.Controls.Add($audioTextBox)

$audioBrowseButton = New-Object System.Windows.Forms.Button
$audioBrowseButton.Text = "Browse..."
$audioBrowseButton.Location = New-Object System.Drawing.Point(710, 62)
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
        Update-Status "🔊 Audio selected: $([System.IO.Path]::GetFileName($openFileDialog.FileName))" "Cyan"
    }
})

# Duration Input
$durationLabel = New-Object System.Windows.Forms.Label
$durationLabel.Text = "Hours:"
$durationLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$durationLabel.ForeColor = [System.Drawing.Color]::White
$durationLabel.Location = New-Object System.Drawing.Point(800, 30)
$durationLabel.Size = New-Object System.Drawing.Size(50, 20)
$quickStartGroup.Controls.Add($durationLabel)

$durationTextBox = New-Object System.Windows.Forms.NumericUpDown
$durationTextBox.Location = New-Object System.Drawing.Point(850, 28)
$durationTextBox.Size = New-Object System.Drawing.Size(60, 23)
$durationTextBox.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
$durationTextBox.ForeColor = [System.Drawing.Color]::White
$durationTextBox.Minimum = 1
$durationTextBox.Maximum = 24
$durationTextBox.Value = 8
$quickStartGroup.Controls.Add($durationTextBox)

# Create Video Button - Enhanced for GPU
$createVideoButton = New-Object System.Windows.Forms.Button
$createVideoButton.Text = "🚀 CREATE WITH GPU ACCELERATION"
$createVideoButton.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$createVideoButton.Location = New-Object System.Drawing.Point(800, 55)
$createVideoButton.Size = New-Object System.Drawing.Size(230, 35)
$createVideoButton.BackColor = [System.Drawing.Color]::FromArgb(76, 175, 80)
$createVideoButton.ForeColor = [System.Drawing.Color]::White
$createVideoButton.FlatStyle = "Flat"
$quickStartGroup.Controls.Add($createVideoButton)

$createVideoButton.Add_Click({
    if (-not $videoTextBox.Text -or -not $audioTextBox.Text) {
        Update-Status "❌ Please select both video and audio files" "Red"
        return
    }
    
    if (-not (Test-Path $videoTextBox.Text) -or -not (Test-Path $audioTextBox.Text)) {
        Update-Status "❌ One or both files don't exist" "Red"
        return
    }
    
    $outputPath = Join-Path $PSScriptRoot "Output\gpu_ambient_video_$($durationTextBox.Value)hrs.mp4"
    Start-EnhancedScript $videoTextBox.Text $audioTextBox.Text $durationTextBox.Value $outputPath
})

# Performance Info Section
$perfGroup = New-Object System.Windows.Forms.GroupBox
$perfGroup.Text = "⚡ GPU Performance Information"
$perfGroup.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$perfGroup.ForeColor = [System.Drawing.Color]::White
$perfGroup.Location = New-Object System.Drawing.Point(20, 400)
$perfGroup.Size = New-Object System.Drawing.Size(1050, 100)
$form.Controls.Add($perfGroup)

$perfInfoLabel = New-Object System.Windows.Forms.Label
$perfInfoLabel.Text = "🎯 Your RTX 5080 & RTX 5060 Ti Setup:`n" +
                     "• Expected Processing Speed: 5-15x faster than CPU`n" +
                     "• Best Quality Profile: 'balanced' for optimal speed/quality ratio`n" +
                     "• Multi-GPU: Use for maximum performance on complex projects"
$perfInfoLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$perfInfoLabel.ForeColor = [System.Drawing.Color]::LightGray
$perfInfoLabel.Location = New-Object System.Drawing.Point(20, 25)
$perfInfoLabel.Size = New-Object System.Drawing.Size(1000, 60)
$perfGroup.Controls.Add($perfInfoLabel)

# Auto-detect GPUs on startup
$form.Add_Shown({
    Update-Status "🚀 GPU-Enhanced Ambient Video Studio loaded - detecting hardware..." "Yellow"
    $detectGPUButton.PerformClick()
})

# Form closing event
$form.Add_FormClosing({
    if ($global:CurrentProcess -and -not $global:CurrentProcess.HasExited) {
        $global:CurrentProcess.Kill()
    }
    if ($global:ProgressTimer) {
        $global:ProgressTimer.Stop()
    }
    if ($global:GPUMonitorTimer) {
        $global:GPUMonitorTimer.Stop()
    }
})

# Show the form
[void]$form.ShowDialog()