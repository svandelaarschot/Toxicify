@echo off
REM Drop all arguments passed from git
:loop
if "%~1"=="" goto start
shift
goto loop

:start
call "D:\Development\Toxicify\Installer\Build-Installer-Simple.bat"
exit /b %errorlevel%