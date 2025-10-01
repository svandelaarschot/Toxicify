@echo off
REM Quick Sync to WoW - Batch version for GitKraken compatibility

echo Quick syncing to WoW...

set "WOW_PATH=D:\World of Warcraft\_retail_\Interface\AddOns\Toxicify"

REM Quick copy all files
copy "*.lua" "%WOW_PATH%\" >nul 2>&1
copy "*.toc" "%WOW_PATH%\" >nul 2>&1
copy "Assets\logo.png" "%WOW_PATH%\" >nul 2>&1

echo Synced to WoW!
