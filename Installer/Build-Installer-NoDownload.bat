@echo off
echo Building Toxicify Installer...

REM Check if NSIS is installed
where makensis >nul 2>nul
if %errorlevel% neq 0 (
    echo NSIS not found in PATH. Checking common locations...
    
    REM Try to find makensis in common locations
    set "MAKENSIS_PATH="
    if exist "C:\NSIS\makensis.exe" (
        set "MAKENSIS_PATH=C:\NSIS\makensis.exe"
        echo Found NSIS in C:\NSIS
    ) else if exist "C:\Program Files (x86)\NSIS\makensis.exe" (
        set "MAKENSIS_PATH=C:\Program Files (x86)\NSIS\makensis.exe"
        echo Found NSIS in Program Files (x86)
    ) else if exist "C:\Program Files\NSIS\makensis.exe" (
        set "MAKENSIS_PATH=C:\Program Files\NSIS\makensis.exe"
        echo Found NSIS in Program Files
    ) else (
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
        echo.
        echo Press any key to exit...
        pause >nul
        exit /b 1
    )
)

echo NSIS found! Building installer...

REM Create installer directory
if not exist "Installer" mkdir Installer

REM Copy required files to installer directory
echo Copying files...
copy "..\Commands.lua" "." >nul
copy "..\Constants.lua" "." >nul
copy "..\Core.lua" "." >nul
copy "..\Events.lua" "." >nul
copy "..\GroupFinder.lua" "." >nul
copy "..\Minimap.lua" "." >nul
copy "..\Options.lua" "." >nul
copy "..\Player.lua" "." >nul
copy "..\Toxicify.lua" "." >nul
copy "..\UI.lua" "." >nul
copy "..\Toxicify.toc" "." >nul
echo Lua and TOC files copied successfully

REM Copy logo for installer icon (only if it's a .ico file)
if exist "..\Assets\logo.ico" (
    copy "..\Assets\logo.ico" "logo.ico" >nul
    echo Logo copied for installer icon
) else (
    echo INFO: No .ico logo found, installer will use default icon
)

REM Create license file
echo Creating license file...
echo Toxicify Addon License > LICENSE.txt
echo. >> LICENSE.txt
echo This addon is provided as-is for educational purposes. >> LICENSE.txt
echo Use at your own risk. >> LICENSE.txt

REM Compile NSIS installer
echo Compiling installer...

REM Try to find makensis in common locations
if "%MAKENSIS_PATH%"=="" (
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
)

echo Using makensis from: %MAKENSIS_PATH%
"%MAKENSIS_PATH%" "Toxicify-Installer.nsi"

if %errorlevel% equ 0 (
    echo.
    echo SUCCESS: Installer created successfully!
    echo Output: Toxicify WoW Addon.exe
    echo.
    echo The installer is ready to distribute!
) else (
    echo.
    echo ERROR: Failed to compile installer
    echo Check the error messages above for details.
)

echo.
echo Press any key to exit...
pause >nul
