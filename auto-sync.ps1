# Auto Sync to WoW - Runs automatically
$wowPath = "D:\World of Warcraft\_retail_\Interface\AddOns\Toxicify"

# Copy files silently
Copy-Item "*.lua" $wowPath -Force -ErrorAction SilentlyContinue
Copy-Item "*.toc" $wowPath -Force -ErrorAction SilentlyContinue  
Copy-Item "Assets\logo.png" $wowPath -Force -ErrorAction SilentlyContinue
