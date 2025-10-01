@echo off
REM Git commit with automatic sync to WoW
set "WOW_PATH=D:\World of Warcraft\_retail_\Interface\AddOns\Toxicify"

REM Commit first
git commit %*

REM Quick sync after commit
copy "*.lua" "%WOW_PATH%\" >nul 2>&1
copy "*.toc" "%WOW_PATH%\" >nul 2>&1
copy "Assets\logo.png" "%WOW_PATH%\" >nul 2>&1