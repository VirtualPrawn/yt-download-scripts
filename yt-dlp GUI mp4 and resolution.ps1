<#
.SYNOPSIS
GUI YouTube video downloader with URL, resolution, and output directory selection
#>

Add-Type -AssemblyName Microsoft.VisualBasic
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

# =============================================
# CONFIGURATION - EDIT THESE PATHS
# =============================================
$ytdlpPath = "C:\YTDLP\yt-dlp.exe"  # Change this to your actual yt-dlp path
$ffmpegLocation = "bin"               # Change if FFmpeg is elsewhere

# =============================================
# VALIDATE AND UPDATE YT-DLP
# =============================================
if (-not (Test-Path $ytdlpPath)) {
    [System.Windows.MessageBox]::Show(
        "yt-dlp not found at:`n$ytdlpPath`nPlease update the path in the script.",
        "Error: Missing yt-dlp",
        "OK",
        "Error"
    ) | Out-Null
    exit
}

try {
    Write-Host "Checking for yt-dlp updates..." -ForegroundColor Yellow
    & $ytdlpPath -U | Out-Null
    Write-Host "yt-dlp is up-to-date" -ForegroundColor Green
}
catch {
    [System.Windows.MessageBox]::Show(
        "Failed to update yt-dlp:`n$_",
        "Update Error",
        "OK",
        "Error"
    ) | Out-Null
    exit
}

# =============================================
# GET URL INPUT
# =============================================
$url = [Microsoft.VisualBasic.Interaction]::InputBox("Enter the video URL:", "Video URL")

if (-not $url) {
    [System.Windows.MessageBox]::Show("No URL provided. Exiting...", "Error") | Out-Null
    exit
}

# =============================================
# RESOLUTION SELECTION
# =============================================
$resolutions = @(
    [pscustomobject]@{ Resolution = "2160p"; Height = 2160 },
    [pscustomobject]@{ Resolution = "1440p"; Height = 1440 },
    [pscustomobject]@{ Resolution = "1080p"; Height = 1080 },
    [pscustomobject]@{ Resolution = "720p"; Height = 720 },
    [pscustomobject]@{ Resolution = "480p"; Height = 480 },
    [pscustomobject]@{ Resolution = "360p"; Height = 360 }
)

$selectedRes = $resolutions | Out-GridView -Title "Select Video Resolution" -PassThru

if (-not $selectedRes) {
    [System.Windows.MessageBox]::Show("No resolution selected. Exiting...", "Error") | Out-Null
    exit
}

# =============================================
# OUTPUT DIRECTORY SELECTION
# =============================================
$folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
$folderDialog.Description = "Select where to save the video"
$folderDialog.ShowNewFolderButton = $true

if ($folderDialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
    [System.Windows.MessageBox]::Show("No output directory selected. Exiting...", "Error") | Out-Null
    exit
}
$outputDir = $folderDialog.SelectedPath

# =============================================
# BUILD YT-DLP COMMAND
# =============================================
$arguments = @(
    $url,
    "--merge-output-format", "mp4",
    "--ffmpeg-location", $ffmpegLocation,
    "-wi",
    "--all-subs",
    "--add-metadata",
    "--postprocessor-args", "ffmpeg:-c:a mp3",
    "-f", "bv*[height<=$($selectedRes.Height)]+ba/b[height<=$($selectedRes.Height)]",
    "-o", "$outputDir\%(title)s.%(ext)s"  # Output path with automatic filename
)

# =============================================
# RUN DOWNLOAD
# =============================================
try {
    Write-Host "Downloading to: $outputDir" -ForegroundColor Cyan
    & $ytdlpPath $arguments
    [System.Windows.MessageBox]::Show(
        "Video saved to:`n$outputDir",
        "Download Complete",
        "OK",
        "Information"
    ) | Out-Null
}
catch {
    [System.Windows.MessageBox]::Show("Error occurred: $_", "Error") | Out-Null
    exit 1
}