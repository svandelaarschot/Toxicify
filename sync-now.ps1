# Instant Sync to WoW - Super fast
$wowPath = "D:\World of Warcraft\_retail_\Interface\AddOns\Toxicify"

# Copy files instantly
Copy-Item "*.lua" $wowPath -Force -ErrorAction SilentlyContinue
Copy-Item "*.toc" $wowPath -Force -ErrorAction SilentlyContinue  
Copy-Item "Assets\logo.png" $wowPath -Force -ErrorAction SilentlyContinue

Write-Host "Done!" -ForegroundColor Green
