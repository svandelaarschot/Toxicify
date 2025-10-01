@echo off
REM Git push with automatic sync to WoW
set "WOW_PATH=D:\World of Warcraft\_retail_\Interface\AddOns\Toxicify"

REM Quick sync before push
copy "*.lua" "%WOW_PATH%\" >nul 2>&1
copy "*.toc" "%WOW_PATH%\" >nul 2>&1
copy "Assets\logo.png" "%WOW_PATH%\" >nul 2>&1

REM Now push
git push %*
