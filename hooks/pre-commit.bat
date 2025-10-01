@echo off
REM Toxicify Git Hook Wrapper for GitKraken
REM This wrapper ensures GitKraken can execute the hook

REM Get the directory where this script is located
set "HOOK_DIR=%~dp0"

REM Run the actual hook script
call "%HOOK_DIR%pre-commit.cmd"

REM Exit with the same code as the hook
exit /b %errorlevel%