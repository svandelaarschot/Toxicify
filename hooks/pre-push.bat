@echo off
REM === Git pre-push hook (Windows/GitKraken compatible) ===

set "WOW_PATH=D:\World of Warcraft\_retail_\Interface\AddOns\Toxicify"
set "INSTALLER_PATH=D:\Development\Toxicify\Installer\Build-Installer-Simple.bat"
set "LOG_FILE=%~dp0prepush.log"

echo [HOOK] Pre-push started at %date% %time% > "%LOG_FILE%"

REM 1) Run installer (ignore Git arguments)
echo [HOOK] Running installer: %INSTALLER_PATH% >> "%LOG_FILE%"
call "%INSTALLER_PATH%" >> "%LOG_FILE%" 2>&1
if errorlevel 1 (
    echo [HOOK] Installer failed, aborting push. >> "%LOG_FILE%"
    exit /b 1
)

REM 2) Copy addon files
echo [HOOK] Copying addon files to WoW folder... >> "%LOG_FILE%"
copy "*.lua" "%WOW_PATH%\" >> "%LOG_FILE%" 2>&1
copy "*.toc" "%WOW_PATH%\" >> "%LOG_FILE%" 2>&1
copy "Assets\logo.png" "%WOW_PATH%\" >> "%LOG_FILE%" 2>&1

echo [HOOK] Pre-push finished successfully. >> "%LOG_FILE%"
exit 0
