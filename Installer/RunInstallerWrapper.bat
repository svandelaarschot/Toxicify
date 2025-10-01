@echo off
REM === Wrapper to prevent Git hook arguments from breaking installer ===

REM Verwijder alle arguments (refs/heads/main etc)
:clearArgs
if "%~1"=="" goto start
shift
goto clearArgs

:start
echo [WRAPPER] Starting Build-Installer-Simple.bat...
call "D:\Development\Toxicify\Installer\Build-Installer-Simple.bat"
exit /b %errorlevel%
