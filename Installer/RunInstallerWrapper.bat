@echo off
REM === RunInstallerWrapper.bat ===
REM Strip alle Git hook arguments zodat ze niet bij je installer komen

:clearArgs
if "%~1"=="" goto start
shift
goto clearArgs

:start
echo [WRAPPER] Starting Build-Installer-Simple.bat...
call "D:\Development\Toxicify\Installer\Build-Installer-Simple.bat"
exit /b %errorlevel%
