@echo off
setlocal enabledelayedexpansion

echo.
echo ========================================
echo    Toxicify Addon Installer
echo ========================================
echo.

:: Check if running as administrator
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Running with administrator privileges...
) else (
    echo WARNING: Not running as administrator. Some operations may fail.
    echo.
)

:: Default WoW installation paths
set "WOW_PATHS[0]=C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns"
set "WOW_PATHS[1]=C:\Program Files\World of Warcraft\_retail_\Interface\AddOns"
set "WOW_PATHS[2]=D:\World of Warcraft\_retail_\Interface\AddOns"
set "WOW_PATHS[3]=E:\World of Warcraft\_retail_\Interface\AddOns"
set "WOW_PATHS[4]=F:\World of Warcraft\_retail_\Interface\AddOns"

:: Find existing WoW installations
echo Searching for World of Warcraft installations...
echo.

set "FOUND_PATHS="
set "PATH_COUNT=0"

for /L %%i in (0,1,4) do (
    if exist "!WOW_PATHS[%%i]!" (
        set /a PATH_COUNT+=1
        set "FOUND_PATHS=!FOUND_PATHS!%%i "
        echo [!PATH_COUNT!] !WOW_PATHS[%%i]!
    )
)

echo.

:: If no paths found, ask for custom path
if %PATH_COUNT% == 0 (
    echo No standard WoW installations found.
    echo.
    set /p "CUSTOM_PATH=Please enter the full path to your WoW AddOns folder: "
    if exist "!CUSTOM_PATH!" (
        set "TARGET_PATH=!CUSTOM_PATH!"
    ) else (
        echo ERROR: Path does not exist: !CUSTOM_PATH!
        pause
        exit /b 1
    )
) else (
    :: Let user choose from found paths
    echo Please select your WoW installation:
    echo.
    set /p "CHOICE=Enter the number (1-%PATH_COUNT%) or 'c' for custom path: "
    
    if /i "!CHOICE!" == "c" (
        set /p "CUSTOM_PATH=Please enter the full path to your WoW AddOns folder: "
        if exist "!CUSTOM_PATH!" (
            set "TARGET_PATH=!CUSTOM_PATH!"
        ) else (
            echo ERROR: Path does not exist: !CUSTOM_PATH!
            pause
            exit /b 1
        )
    ) else (
        :: Validate choice
        set "VALID_CHOICE=0"
        for %%p in (!FOUND_PATHS!) do (
            if "%%p" == "!CHOICE!" (
                set "VALID_CHOICE=1"
                set "TARGET_PATH=!WOW_PATHS[!CHOICE!]!"
            )
        )
        
        if !VALID_CHOICE! == 0 (
            echo ERROR: Invalid choice. Please run the installer again.
            pause
            exit /b 1
        )
    )
)

echo.
echo Selected path: !TARGET_PATH!
echo.

:: Check if target directory exists and is writable
if not exist "!TARGET_PATH!" (
    echo ERROR: Target directory does not exist: !TARGET_PATH!
    pause
    exit /b 1
)

:: Test write permissions
echo Testing write permissions...
echo test > "!TARGET_PATH!\test_write.tmp" 2>nul
if exist "!TARGET_PATH!\test_write.tmp" (
    del "!TARGET_PATH!\test_write.tmp"
    echo Write permissions: OK
) else (
    echo ERROR: Cannot write to target directory. Please run as administrator.
    pause
    exit /b 1
)

:: Get the directory where this script is located
set "SCRIPT_DIR=%~dp0"
set "SOURCE_DIR=%SCRIPT_DIR%Toxicify"

:: Check if source directory exists
if not exist "%SOURCE_DIR%" (
    echo ERROR: Toxicify source directory not found: %SOURCE_DIR%
    echo Please make sure this installer is in the same folder as the Toxicify addon.
    pause
    exit /b 1
)

:: Create target directory if it doesn't exist
set "TARGET_ADDON_DIR=!TARGET_PATH!\Toxicify"
if not exist "!TARGET_ADDON_DIR!" (
    echo Creating addon directory...
    mkdir "!TARGET_ADDON_DIR!"
    if !errorLevel! neq 0 (
        echo ERROR: Failed to create addon directory.
        pause
        exit /b 1
    )
)

:: Copy files
echo.
echo Installing Toxicify addon...
echo Source: %SOURCE_DIR%
echo Target: !TARGET_ADDON_DIR!
echo.

:: Copy all files from source to target
xcopy "%SOURCE_DIR%\*" "!TARGET_ADDON_DIR!\" /E /I /H /Y /Q
if !errorLevel! neq 0 (
    echo ERROR: Failed to copy addon files.
    pause
    exit /b 1
)

:: Verify installation
echo Verifying installation...
if exist "!TARGET_ADDON_DIR!\Toxicify.toc" (
    echo ✓ Toxicify.toc found
) else (
    echo ✗ ERROR: Toxicify.toc not found after installation
    pause
    exit /b 1
)

if exist "!TARGET_ADDON_DIR!\Core.lua" (
    echo ✓ Core.lua found
) else (
    echo ✗ ERROR: Core.lua not found after installation
    pause
    exit /b 1
)

:: Set file permissions (optional)
echo Setting file permissions...
icacls "!TARGET_ADDON_DIR!" /grant Everyone:F /T /Q >nul 2>&1

echo.
echo ========================================
echo    Installation Complete!
echo ========================================
echo.
echo Toxicify has been successfully installed to:
echo !TARGET_ADDON_DIR!
echo.
echo You can now start World of Warcraft and enable the addon.
echo.
echo Installation files copied:
for %%f in ("!TARGET_ADDON_DIR!\*.lua") do echo   - %%~nxf
for %%f in ("!TARGET_ADDON_DIR!\*.toc") do echo   - %%~nxf
for %%f in ("!TARGET_ADDON_DIR!\*.md") do echo   - %%~nxf
for %%f in ("!TARGET_ADDON_DIR!\*.png") do echo   - %%~nxf
echo.

:: Ask if user wants to open the addon folder
set /p "OPEN_FOLDER=Would you like to open the addon folder? (y/n): "
if /i "!OPEN_FOLDER!" == "y" (
    explorer "!TARGET_ADDON_DIR!"
)

echo.
echo Thank you for using Toxicify!
echo.
pause
