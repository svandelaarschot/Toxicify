# Toxicify Sync to WoW Script
# Run this script to manually sync addon files to WoW AddOns directory

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "    Toxicify Sync to WoW" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Define WoW AddOns path
$wowAddOnsPath = "D:\World of Warcraft\_retail_\Interface\AddOns\Toxicify"

# Check if WoW AddOns directory exists
if (-not (Test-Path "D:\World of Warcraft\_retail_\Interface\AddOns")) {
    Write-Host "WoW AddOns directory not found: D:\World of Warcraft\_retail_\Interface\AddOns" -ForegroundColor Red
    Write-Host "Please check your WoW installation path" -ForegroundColor Yellow
    exit 1
}

# Create Toxicify addon directory if it doesn't exist
if (-not (Test-Path $wowAddOnsPath)) {
    New-Item -ItemType Directory -Path $wowAddOnsPath -Force | Out-Null
    Write-Host "Created WoW AddOns directory: $wowAddOnsPath" -ForegroundColor Green
}

Write-Host "Syncing addon files to WoW AddOns directory..." -ForegroundColor Yellow

# Copy all Lua and TOC files to WoW AddOns directory
$files = @(
    "Commands.lua", "Constants.lua", "Core.lua", "Events.lua", 
    "GroupFinder.lua", "Minimap.lua", "Options.lua", "Player.lua", 
    "Toxicify.lua", "UI.lua", "Toxicify.toc"
)

$copiedCount = 0
foreach ($file in $files) {
    if (Test-Path $file) {
        Copy-Item $file $wowAddOnsPath -Force
        Write-Host "  ✅ Copied: $file" -ForegroundColor Green
        $copiedCount++
    } else {
        Write-Host "  ⚠️  $file not found" -ForegroundColor Yellow
    }
}

# Copy logo if it exists
if (Test-Path "Assets/logo.png") {
    Copy-Item "Assets/logo.png" $wowAddOnsPath -Force
    Write-Host "  ✅ Copied: logo.png" -ForegroundColor Green
    $copiedCount++
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "    Sync Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Files synced: $copiedCount" -ForegroundColor Green
Write-Host "Addon is now available in WoW!" -ForegroundColor Green
Write-Host "Location: $wowAddOnsPath" -ForegroundColor Gray
