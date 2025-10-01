# Quick Sync to WoW - Fast version
Write-Host "Quick syncing to WoW..." -ForegroundColor Green

$wowPath = "D:\World of Warcraft\_retail_\Interface\AddOns\Toxicify"

# Quick copy all files
Copy-Item "*.lua" $wowPath -Force -ErrorAction SilentlyContinue
Copy-Item "*.toc" $wowPath -Force -ErrorAction SilentlyContinue
Copy-Item "Assets\logo.png" $wowPath -Force -ErrorAction SilentlyContinue

Write-Host "✅ Synced to WoW!" -ForegroundColor Green
