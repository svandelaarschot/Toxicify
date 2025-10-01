@echo off
REM Toxicify Auto-Sync and Installer Builder
REM Git pre-commit hook (CMD version) that works with GitKraken
REM This version uses CMD instead of PowerShell for better compatibility

echo Checking for Lua file changes...

REM Get list of staged files
for /f "delims=" %%i in ('git diff --cached --name-only') do (
    set "file=%%i"
    if "!file:~-4!"==".lua" (
        set "LUA_CHANGES=true"
        echo Lua file changed: !file!
    )
)

REM If no Lua changes, exit early
if not defined LUA_CHANGES (
    echo No Lua file changes detected. Skipping auto-sync.
    exit /b 0
)

echo Lua changes detected! Starting auto-sync and installer rebuild...

REM Get the project root directory
for /f "delims=" %%i in ('git rev-parse --show-toplevel') do set "PROJECT_ROOT=%%i"
cd /d "%PROJECT_ROOT%"

echo Project root: %PROJECT_ROOT%

REM Create installer directory if it doesn't exist
if not exist "Installer" mkdir Installer

echo Syncing addon files to installer directory...

REM Copy all Lua and TOC files to installer directory
copy "Commands.lua" "Installer\" >nul 2>&1 && echo   Copied: Commands.lua || echo   Commands.lua not found
copy "Constants.lua" "Installer\" >nul 2>&1 && echo   Copied: Constants.lua || echo   Constants.lua not found
copy "Core.lua" "Installer\" >nul 2>&1 && echo   Copied: Core.lua || echo   Core.lua not found
copy "Events.lua" "Installer\" >nul 2>&1 && echo   Copied: Events.lua || echo   Events.lua not found
copy "GroupFinder.lua" "Installer\" >nul 2>&1 && echo   Copied: GroupFinder.lua || echo   GroupFinder.lua not found
copy "Minimap.lua" "Installer\" >nul 2>&1 && echo   Copied: Minimap.lua || echo   Minimap.lua not found
copy "Options.lua" "Installer\" >nul 2>&1 && echo   Copied: Options.lua || echo   Options.lua not found
copy "Player.lua" "Installer\" >nul 2>&1 && echo   Copied: Player.lua || echo   Player.lua not found
copy "Toxicify.lua" "Installer\" >nul 2>&1 && echo   Copied: Toxicify.lua || echo   Toxicify.lua not found
copy "UI.lua" "Installer\" >nul 2>&1 && echo   Copied: UI.lua || echo   UI.lua not found
copy "Toxicify.toc" "Installer\" >nul 2>&1 && echo   Copied: Toxicify.toc || echo   Toxicify.toc not found

REM Copy logo if it exists
if exist "Assets\logo.png" (
    copy "Assets\logo.png" "Installer\" >nul 2>&1 && echo   Copied: logo.png || echo   Could not copy logo.png
)

echo Files synced to installer directory

echo Syncing addon files to WoW AddOns directory...

REM Define WoW AddOns path
set "WOW_ADDONS_PATH=D:\World of Warcraft\_retail_\Interface\AddOns\Toxicify"

REM Check if WoW AddOns directory exists
if not exist "D:\World of Warcraft\_retail_\Interface\AddOns" (
    echo WoW AddOns directory not found: D:\World of Warcraft\_retail_\Interface\AddOns
    echo Please check your WoW installation path
    goto :skip_wow_sync
)

REM Create Toxicify addon directory if it doesn't exist
if not exist "!WOW_ADDONS_PATH!" (
    mkdir "!WOW_ADDONS_PATH!" >nul 2>&1
    echo Created WoW AddOns directory: !WOW_ADDONS_PATH!
)

REM Copy all Lua and TOC files to WoW AddOns directory
copy "Commands.lua" "!WOW_ADDONS_PATH!\" >nul 2>&1 && echo   Copied to WoW: Commands.lua || echo   Commands.lua not found
copy "Constants.lua" "!WOW_ADDONS_PATH!\" >nul 2>&1 && echo   Copied to WoW: Constants.lua || echo   Constants.lua not found
copy "Core.lua" "!WOW_ADDONS_PATH!\" >nul 2>&1 && echo   Copied to WoW: Core.lua || echo   Core.lua not found
copy "Events.lua" "!WOW_ADDONS_PATH!\" >nul 2>&1 && echo   Copied to WoW: Events.lua || echo   Events.lua not found
copy "GroupFinder.lua" "!WOW_ADDONS_PATH!\" >nul 2>&1 && echo   Copied to WoW: GroupFinder.lua || echo   GroupFinder.lua not found
copy "Minimap.lua" "!WOW_ADDONS_PATH!\" >nul 2>&1 && echo   Copied to WoW: Minimap.lua || echo   Minimap.lua not found
copy "Options.lua" "!WOW_ADDONS_PATH!\" >nul 2>&1 && echo   Copied to WoW: Options.lua || echo   Options.lua not found
copy "Player.lua" "!WOW_ADDONS_PATH!\" >nul 2>&1 && echo   Copied to WoW: Player.lua || echo   Player.lua not found
copy "Toxicify.lua" "!WOW_ADDONS_PATH!\" >nul 2>&1 && echo   Copied to WoW: Toxicify.lua || echo   Toxicify.lua not found
copy "UI.lua" "!WOW_ADDONS_PATH!\" >nul 2>&1 && echo   Copied to WoW: UI.lua || echo   UI.lua not found
copy "Toxicify.toc" "!WOW_ADDONS_PATH!\" >nul 2>&1 && echo   Copied to WoW: Toxicify.toc || echo   Toxicify.toc not found

REM Copy logo if it exists
if exist "Assets\logo.png" (
    copy "Assets\logo.png" "!WOW_ADDONS_PATH!\" >nul 2>&1 && echo   Copied to WoW: logo.png || echo   Could not copy logo.png
)

echo Files synced to WoW AddOns directory
echo Addon is now available in WoW!

:skip_wow_sync

echo Rebuilding installer...

cd Installer

REM Check if NSIS is available
where makensis >nul 2>&1
if %errorlevel% equ 0 (
    echo NSIS found, building installer...
    makensis Toxicify-Installer.nsi
    
    if %errorlevel% equ 0 (
        echo Installer built successfully: Toxicify WoW Addon.exe
        
        REM Show file size if it exists
        if exist "Toxicify WoW Addon.exe" (
            for %%A in ("Toxicify WoW Addon.exe") do (
                set /a "size=%%~zA/1024"
                echo Installer size: !size! KB
            )
        )
    ) else (
        echo Failed to build installer
        cd ..
        exit /b 1
    )
) else (
    echo NSIS not found. Installer not rebuilt.
    echo To enable auto-installer building, install NSIS:
    echo    - Download from: https://nsis.sourceforge.io/
    echo    - Or use: choco install nsis
    echo    - Or use: winget install NSIS.NSIS
)

cd ..

echo Adding updated installer files to commit...

REM Add the synced files to the commit
git add Installer\*.lua Installer\*.toc Installer\*.png 2>nul

REM Add the rebuilt installer if it exists
if exist "Installer\Toxicify WoW Addon.exe" (
    git add "Installer\Toxicify WoW Addon.exe" 2>nul
    echo Updated installer added to commit
)

echo Installer files staged for commit

echo Auto-sync completed successfully!
echo Installer files have been updated and staged for commit.
echo Addon files have been synced to WoW!

exit /b 0
