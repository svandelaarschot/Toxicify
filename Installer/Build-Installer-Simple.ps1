# Toxicify Installer Builder (Simple Version)
# PowerShell script for creating Windows installer without auto-download

param(
    [switch]$Clean,
    [switch]$Verbose
)

Write-Host "Building Toxicify Installer..." -ForegroundColor Green

# Check if NSIS is installed
try {
    $null = Get-Command makensis -ErrorAction Stop
    Write-Host "NSIS found" -ForegroundColor Green
} catch {
    Write-Host "NSIS is not installed." -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install NSIS using one of these methods:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Download from: https://nsis.sourceforge.io/" -ForegroundColor Gray
    Write-Host "2. Use Chocolatey: choco install nsis" -ForegroundColor Gray
    Write-Host "3. Use Winget: winget install NSIS.NSIS" -ForegroundColor Gray
    Write-Host "4. Use Scoop: scoop install nsis" -ForegroundColor Gray
    Write-Host ""
    Write-Host "After installing NSIS, run this script again." -ForegroundColor Yellow
    exit 1
}

# Clean previous build if requested
if ($Clean) {
    Write-Host "Cleaning previous build..." -ForegroundColor Yellow
    Remove-Item "Installer\*.lua" -Force -ErrorAction SilentlyContinue
    Remove-Item "Installer\*.toc" -Force -ErrorAction SilentlyContinue
    Remove-Item "Installer\*.exe" -Force -ErrorAction SilentlyContinue
}

# Create installer directory
if (-not (Test-Path "Installer")) {
    New-Item -ItemType Directory -Path "Installer" | Out-Null
}

# Copy required files
Write-Host "Copying files..." -ForegroundColor Cyan
$files = @(
    "Commands.lua",
    "Constants.lua", 
    "Core.lua",
    "Events.lua",
    "GroupFinder.lua",
    "Minimap.lua",
    "Options.lua",
    "Player.lua",
    "Toxicify.lua",
    "UI.lua",
    "Toxicify.toc"
)

foreach ($file in $files) {
    if (Test-Path $file) {
        Copy-Item $file "Installer\" -Force
        if ($Verbose) { Write-Host "  Copied: $file" -ForegroundColor Gray }
    } else {
        Write-Host "WARNING: $file not found" -ForegroundColor Yellow
    }
}

# Copy logo for installer icon
if (Test-Path "Assets\logo.png") {
    Copy-Item "Assets\logo.png" "Installer\logo.png" -Force
    Write-Host "Logo copied for installer icon" -ForegroundColor Green
} else {
    Write-Host "WARNING: logo.png not found in Assets folder" -ForegroundColor Yellow
}

# Create license file
Write-Host "Creating license file..." -ForegroundColor Cyan
@"
Toxicify Addon License

This addon is provided as-is for educational purposes.
Use at your own risk.

Features:
- Mark players as Toxic or Pumper
- Highlight toxic players in Party/Raid frames
- Filter toxic groups in Premade Groups
- Warning popup when joining parties with toxic players
- Target frame indicator for toxic/pumper players
- Auto-close timer for warning popups
- Import/Export toxic player lists
- Context menu integration for easy marking

For support, visit: https://github.com/your-repo/toxicify
"@ | Out-File "Installer\LICENSE.txt" -Encoding UTF8

# Compile NSIS installer
Write-Host "Compiling installer..." -ForegroundColor Cyan
try {
    & makensis "Installer\Toxicify-Installer.nsi"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "SUCCESS: Installer created successfully!" -ForegroundColor Green
        Write-Host "Output: Installer\Toxicify-Installer.exe" -ForegroundColor Green
        
        # Show file size
        $installerPath = "Installer\Toxicify-Installer.exe"
        if (Test-Path $installerPath) {
            $size = (Get-Item $installerPath).Length
            $sizeKB = [math]::Round($size / 1KB, 2)
            Write-Host "Size: $sizeKB KB" -ForegroundColor Gray
        }
    } else {
        Write-Host "ERROR: Failed to compile installer" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "ERROR: Failed to run makensis" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

Write-Host "Build completed!" -ForegroundColor Green
