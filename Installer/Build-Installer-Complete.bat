@echo off
REM Complete installer build with zip creation and cleanup
echo Building Toxicify Installer with zip files...

REM Copy logo.ico if it exists
if exist "logo.ico" (
    echo Using existing logo.ico...
) else if exist "logo.png" (
    echo Creating icon from logo...
    powershell -ExecutionPolicy Bypass -File create-icon.ps1
)

REM Build the installer
call Build-Installer-NoDownload.bat

REM Check if installer was created successfully
if not exist "Toxicify WoW Addon.exe" (
    echo ERROR: Installer not created!
    pause
    exit /b 1
)

echo.
echo Cleaning up installer folder...

REM Delete individual files to keep folder clean
del *.lua
del *.toc
del logo.png
del logo.ico
del LICENSE.txt

echo.
echo Creating zip files...

REM Create zip with installer
powershell -Command "Compress-Archive -Path 'Toxicify WoW Addon.exe' -DestinationPath 'Toxicify-Installer.zip' -Force"

REM Create zip with addon files only (copy from main folder)
powershell -Command "Copy-Item '..\*.lua' . -Force; Copy-Item '..\*.toc' . -Force; Copy-Item '..\Assets\logo.png' . -Force; Compress-Archive -Path '*.lua', '*.toc', 'logo.png' -DestinationPath 'Toxicify-Addon.zip' -Force; del *.lua; del *.toc; del logo.png"

echo.
echo SUCCESS: Complete build finished!
echo - Toxicify WoW Addon.exe (Installer)
echo - Toxicify-Installer.zip (Installer + EXE)
echo - Toxicify-Addon.zip (Addon files only)
echo.
pause
