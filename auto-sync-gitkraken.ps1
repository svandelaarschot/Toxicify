# Auto sync for GitKraken - Run this manually after push
$wowPath = "D:\World of Warcraft\_retail_\Interface\AddOns\Toxicify"

Write-Host "Syncing to WoW..." -ForegroundColor Green

# Copy all files
Copy-Item "*.lua" $wowPath -Force
Copy-Item "*.toc" $wowPath -Force  
Copy-Item "Assets\logo.png" $wowPath -Force

Write-Host "✅ Files synced to WoW!" -ForegroundColor Green
Write-Host "Location: $wowPath" -ForegroundColor Yellow
