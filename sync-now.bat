@echo off
REM Instant Sync to WoW - No Git, just copy files

set "WOW_PATH=D:\World of Warcraft\_retail_\Interface\AddOns\Toxicify"

REM Copy files instantly
copy "*.lua" "%WOW_PATH%\" >nul
copy "*.toc" "%WOW_PATH%\" >nul
copy "Assets\logo.png" "%WOW_PATH%\" >nul

echo Done!
