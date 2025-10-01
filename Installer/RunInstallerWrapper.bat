@echo off
REM Wrapper to run Build-Installer-Simple.bat without Git hook arguments
call "D:\Development\Toxicify\Installer\Build-Installer-Simple.bat"
exit /b %errorlevel%