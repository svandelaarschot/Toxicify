# Toxicify Auto-Sync and Installer Builder
# Git pre-commit hook (PowerShell version) that automatically syncs addon files and rebuilds installer
# when Lua files are changed

Write-Host "Checking for Lua file changes..." -ForegroundColor Cyan

# Get list of staged files
$stagedFiles = git diff --cached --name-only

# Check if any .lua files are being committed
$luaChanges = $false
foreach ($file in $stagedFiles) {
    if ($file -like "*.lua") {
        $luaChanges = $true
        Write-Host "Lua file changed: $file" -ForegroundColor Yellow
    }
}

# If no Lua changes, exit early
if (-not $luaChanges) {
    Write-Host "No Lua file changes detected. Skipping auto-sync." -ForegroundColor Green
    exit 0
}

Write-Host "Lua changes detected! Starting auto-sync and installer rebuild..." -ForegroundColor Green

# Get the project root directory
$projectRoot = git rev-parse --show-toplevel
Set-Location $projectRoot

Write-Host "Project root: $projectRoot" -ForegroundColor Gray

# Function to sync files to installer directory
function Sync-ToInstaller {
    Write-Host "Syncing addon files to installer directory..." -ForegroundColor Cyan
    
    # Create installer directory if it doesn't exist
    if (-not (Test-Path "Installer")) {
        New-Item -ItemType Directory -Path "Installer" | Out-Null
    }
    
    # Copy all Lua and TOC files to installer directory
    $files = @(
        "Commands.lua", "Constants.lua", "Core.lua", "Events.lua", 
        "GroupFinder.lua", "Minimap.lua", "Options.lua", "Player.lua", 
        "Toxicify.lua", "UI.lua", "Toxicify.toc"
    )
    
    foreach ($file in $files) {
        if (Test-Path $file) {
            Copy-Item $file "Installer\" -Force
            Write-Host "  Copied: $file" -ForegroundColor Gray
        } else {
            Write-Host "  $file not found" -ForegroundColor Yellow
        }
    }
    
    # Copy logo if it exists
    if (Test-Path "Assets/logo.png") {
        Copy-Item "Assets/logo.png" "Installer/" -Force
        Write-Host "  Copied: logo.png" -ForegroundColor Gray
    }
    
    Write-Host "Files synced to installer directory" -ForegroundColor Green
}

# Function to sync files to WoW AddOns directory
function Sync-ToWoWAddOns {
    Write-Host "Syncing addon files to WoW AddOns directory..." -ForegroundColor Cyan
    
    # Define WoW AddOns path
    $wowAddOnsPath = "D:\World of Warcraft\_retail_\Interface\AddOns\Toxicify"
    
    # Check if WoW AddOns directory exists
    if (-not (Test-Path "D:\World of Warcraft\_retail_\Interface\AddOns")) {
        Write-Host "WoW AddOns directory not found: D:\World of Warcraft\_retail_\Interface\AddOns" -ForegroundColor Yellow
        Write-Host "Please check your WoW installation path" -ForegroundColor Gray
        return
    }
    
    # Create Toxicify addon directory if it doesn't exist
    if (-not (Test-Path $wowAddOnsPath)) {
        New-Item -ItemType Directory -Path $wowAddOnsPath -Force | Out-Null
        Write-Host "Created WoW AddOns directory: $wowAddOnsPath" -ForegroundColor Green
    }
    
    # Copy all Lua and TOC files to WoW AddOns directory
    $files = @(
        "Commands.lua", "Constants.lua", "Core.lua", "Events.lua", 
        "GroupFinder.lua", "Minimap.lua", "Options.lua", "Player.lua", 
        "Toxicify.lua", "UI.lua", "Toxicify.toc"
    )
    
    foreach ($file in $files) {
        if (Test-Path $file) {
            Copy-Item $file $wowAddOnsPath -Force
            Write-Host "  Copied to WoW: $file" -ForegroundColor Gray
        } else {
            Write-Host "  $file not found" -ForegroundColor Yellow
        }
    }
    
    # Copy logo if it exists
    if (Test-Path "Assets/logo.png") {
        Copy-Item "Assets/logo.png" $wowAddOnsPath -Force
        Write-Host "  Copied to WoW: logo.png" -ForegroundColor Gray
    }
    
    Write-Host "Files synced to WoW AddOns directory" -ForegroundColor Green
    Write-Host "Addon is now available in WoW!" -ForegroundColor Green
}

# Function to rebuild installer
function Rebuild-Installer {
    Write-Host "Rebuilding installer..." -ForegroundColor Cyan
    
    Set-Location "Installer"
    
    # Check if NSIS is available
    try {
        $null = Get-Command makensis -ErrorAction Stop
        Write-Host "NSIS found, building installer..." -ForegroundColor Green
        
        & makensis "Toxicify-Installer.nsi"
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Installer built successfully: Toxicify WoW Addon.exe" -ForegroundColor Green
            
            # Show file size
            if (Test-Path "Toxicify WoW Addon.exe") {
                $size = (Get-Item "Toxicify WoW Addon.exe").Length
                $sizeKB = [math]::Round($size / 1KB, 2)
                Write-Host "Installer size: $sizeKB KB" -ForegroundColor Gray
            }
        } else {
            Write-Host "Failed to build installer" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "NSIS not found. Installer not rebuilt." -ForegroundColor Yellow
        Write-Host "To enable auto-installer building, install NSIS:" -ForegroundColor Cyan
        Write-Host "   - Download from: https://nsis.sourceforge.io/" -ForegroundColor Gray
        Write-Host "   - Or use: choco install nsis" -ForegroundColor Gray
        Write-Host "   - Or use: winget install NSIS.NSIS" -ForegroundColor Gray
    }
    
    Set-Location ".."
}

# Function to update installer files in git
function Update-InstallerFiles {
    Write-Host "Adding updated installer files to commit..." -ForegroundColor Cyan
    
    # Add the synced files to the commit
    Get-ChildItem "Installer\*.lua", "Installer\*.toc", "Installer\*.png" -ErrorAction SilentlyContinue | ForEach-Object {
        git add $_.FullName
        Write-Host "  Added: $($_.Name)" -ForegroundColor Gray
    }
    
    # Add the rebuilt installer if it exists
    if (Test-Path "Installer/Toxicify WoW Addon.exe") {
        git add "Installer/Toxicify WoW Addon.exe"
        Write-Host "Updated installer added to commit" -ForegroundColor Green
    }
    
    Write-Host "Installer files staged for commit" -ForegroundColor Green
}

# Main execution
Write-Host "Starting auto-sync process..." -ForegroundColor Green

# Sync files to installer directory
Sync-ToInstaller

# Sync files to WoW AddOns directory
Sync-ToWoWAddOns

# Rebuild installer
Rebuild-Installer

# Update git with new files
Update-InstallerFiles

Write-Host "Auto-sync completed successfully!" -ForegroundColor Green
Write-Host "Installer files have been updated and staged for commit." -ForegroundColor Green
Write-Host "Addon files have been synced to WoW!" -ForegroundColor Green