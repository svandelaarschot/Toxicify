@echo off
echo Building Toxicify Installer...

REM Check if NSIS is installed
where makensis >nul 2>nul
if %errorlevel% neq 0 (
    echo NSIS is not installed.
    echo.
    echo Please install NSIS using one of these methods:
    echo.
    echo 1. Download from: https://nsis.sourceforge.io/
    echo 2. Use Chocolatey: choco install nsis
    echo 3. Use Winget: winget install NSIS.NSIS
    echo 4. Use Scoop: scoop install nsis
    echo.
    echo After installing NSIS, run this script again.
    pause
    exit /b 1
)

echo NSIS found! Building installer...

REM Create installer directory
if not exist "Installer" mkdir Installer

REM Copy required files to installer directory
echo Copying files...
copy "Commands.lua" "Installer\" >nul
copy "Constants.lua" "Installer\" >nul
copy "Core.lua" "Installer\" >nul
copy "Events.lua" "Installer\" >nul
copy "GroupFinder.lua" "Installer\" >nul
copy "Minimap.lua" "Installer\" >nul
copy "Options.lua" "Installer\" >nul
copy "Player.lua" "Installer\" >nul
copy "Toxicify.lua" "Installer\" >nul
copy "UI.lua" "Installer\" >nul
copy "Toxicify.toc" "Installer\" >nul

REM Copy logo for installer icon
if exist "Assets\logo.png" (
    copy "Assets\logo.png" "Installer\logo.png" >nul
    echo Logo copied for installer icon
) else (
    echo WARNING: logo.png not found in Assets folder
)

REM Create license file
echo Creating license file...
echo Toxicify Addon License > Installer\LICENSE.txt
echo. >> Installer\LICENSE.txt
echo This addon is provided as-is for educational purposes. >> Installer\LICENSE.txt
echo Use at your own risk. >> Installer\LICENSE.txt

REM Compile NSIS installer
echo Compiling installer...

REM Try to find makensis in common locations
set "MAKENSIS_PATH="
if exist "C:\NSIS\makensis.exe" (
    set "MAKENSIS_PATH=C:\NSIS\makensis.exe"
) else if exist "C:\Program Files (x86)\NSIS\makensis.exe" (
    set "MAKENSIS_PATH=C:\Program Files (x86)\NSIS\makensis.exe"
) else if exist "C:\Program Files\NSIS\makensis.exe" (
    set "MAKENSIS_PATH=C:\Program Files\NSIS\makensis.exe"
) else (
    echo ERROR: makensis.exe not found in any common location
    echo Please install NSIS manually from https://nsis.sourceforge.io/
    pause
    exit /b 1
)

echo Using makensis from: %MAKENSIS_PATH%
"%MAKENSIS_PATH%" "Installer\Toxicify-Installer.nsi"

if %errorlevel% equ 0 (
    echo.
    echo SUCCESS: Installer created successfully!
    echo Output: Installer\Toxicify-Installer.exe
) else (
    echo.
    echo ERROR: Failed to compile installer
)

pause
