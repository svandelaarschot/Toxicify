# Toxicify Installer Builder
# PowerShell script for creating Windows installer

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
    Write-Host "NSIS not found. Attempting to download and install..." -ForegroundColor Yellow
    
    # Create temp directory
    $tempDir = "$env:TEMP\nsis"
    if (-not (Test-Path $tempDir)) {
        New-Item -ItemType Directory -Path $tempDir | Out-Null
    }
    
    # Download NSIS installer
    $nsisUrl = "https://sourceforge.net/projects/nsis/files/NSIS%203/3.08/nsis-3.08-setup.exe/download"
    $nsisInstaller = "$tempDir\nsis-installer.exe"
    
    try {
        Write-Host "Downloading NSIS..." -ForegroundColor Cyan
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $nsisUrl -OutFile $nsisInstaller -UseBasicParsing
        
        if (Test-Path $nsisInstaller) {
            Write-Host "Installing NSIS..." -ForegroundColor Cyan
            Start-Process -FilePath $nsisInstaller -ArgumentList "/S" -Wait
            
            # Add NSIS to PATH for current session
            $env:PATH += ";C:\Program Files (x86)\NSIS"
            
            # Check if installation was successful
            try {
                $null = Get-Command makensis -ErrorAction Stop
                Write-Host "NSIS installed successfully!" -ForegroundColor Green
            } catch {
                Write-Host "ERROR: NSIS installation failed" -ForegroundColor Red
                Write-Host "Please manually install NSIS from https://nsis.sourceforge.io/" -ForegroundColor Yellow
                exit 1
            }
        } else {
            Write-Host "ERROR: Failed to download NSIS" -ForegroundColor Red
            Write-Host "Please manually install NSIS from https://nsis.sourceforge.io/" -ForegroundColor Yellow
            exit 1
        }
    } catch {
        Write-Host "ERROR: Failed to download NSIS" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        Write-Host "Alternative installation methods:" -ForegroundColor Yellow
        Write-Host "1. Download NSIS manually from https://nsis.sourceforge.io/" -ForegroundColor Gray
        Write-Host "2. Use Chocolatey: choco install nsis" -ForegroundColor Gray
        Write-Host "3. Use Winget: winget install NSIS.NSIS" -ForegroundColor Gray
        Write-Host "4. Use Scoop: scoop install nsis" -ForegroundColor Gray
        Write-Host ""
        Write-Host "After installing NSIS, run this script again." -ForegroundColor Yellow
        exit 1
    }
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
