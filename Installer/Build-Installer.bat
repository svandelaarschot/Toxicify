@echo off
echo Building Toxicify Installer...

REM Check if NSIS is installed
where makensis >nul 2>nul
if %errorlevel% neq 0 (
    echo NSIS not found. Attempting to download and install...
    
    REM Create temp directory
    if not exist "%TEMP%\nsis" mkdir "%TEMP%\nsis"
    
    REM Try multiple download methods
    echo Downloading NSIS...
    echo Method 1: Using curl...
    curl -L -o "%TEMP%\nsis\nsis-installer.exe" "https://sourceforge.net/projects/nsis/files/NSIS%203/3.08/nsis-3.08-setup.exe/download" 2>nul
    if %errorlevel% neq 0 (
        echo Method 1 failed. Trying Method 2: PowerShell...
        powershell -Command "try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://sourceforge.net/projects/nsis/files/NSIS%203/3.08/nsis-3.08-setup.exe/download' -OutFile '%TEMP%\nsis\nsis-installer.exe' } catch { exit 1 }" 2>nul
        if %errorlevel% neq 0 (
            echo Method 2 failed. Trying Method 3: Direct download...
            powershell -Command "try { (New-Object System.Net.WebClient).DownloadFile('https://sourceforge.net/projects/nsis/files/NSIS%203/3.08/nsis-3.08-setup.exe/download', '%TEMP%\nsis\nsis-installer.exe') } catch { exit 1 }" 2>nul
        )
    )
    
    if exist "%TEMP%\nsis\nsis-installer.exe" (
        echo Installing NSIS...
        echo Running installer with admin privileges...
        "%TEMP%\nsis\nsis-installer.exe" /S /D=C:\NSIS
        timeout /t 15 /nobreak >nul
        
        REM Add NSIS to PATH for current session
        set "PATH=%PATH%;C:\NSIS"
        set "PATH=%PATH%;C:\Program Files (x86)\NSIS"
        set "PATH=%PATH%;C:\Program Files\NSIS"
        
        REM Check if installation was successful
        where makensis >nul 2>nul
        if %errorlevel% neq 0 (
            echo Trying to find NSIS in common locations...
            if exist "C:\NSIS\makensis.exe" (
                set "PATH=%PATH%;C:\NSIS"
                echo Found NSIS in C:\NSIS
            ) else if exist "C:\Program Files (x86)\NSIS\makensis.exe" (
                set "PATH=%PATH%;C:\Program Files (x86)\NSIS"
                echo Found NSIS in Program Files (x86)
            ) else if exist "C:\Program Files\NSIS\makensis.exe" (
                set "PATH=%PATH%;C:\Program Files\NSIS"
                echo Found NSIS in Program Files
            ) else (
                echo ERROR: NSIS installation failed
                echo Please manually install NSIS from https://nsis.sourceforge.io/
                pause
                exit /b 1
            )
        ) else (
            echo NSIS installed successfully!
        )
        
        REM Final check before proceeding
        where makensis >nul 2>nul
        if %errorlevel% neq 0 (
            echo ERROR: makensis still not found after installation
            echo Please manually install NSIS from https://nsis.sourceforge.io/
            echo Or use Build-Installer-NoDownload.bat for manual installation
            pause
            exit /b 1
        )
    ) else (
        echo ERROR: Failed to download NSIS
        echo.
        echo Alternative methods:
        echo 1. Download NSIS manually from https://nsis.sourceforge.io/
        echo 2. Use Chocolatey: choco install nsis
        echo 3. Use Winget: winget install NSIS.NSIS
        echo.
        echo After installing NSIS, run this script again.
        pause
        exit /b 1
    )
)

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
