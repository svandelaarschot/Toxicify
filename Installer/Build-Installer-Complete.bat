@echo off
REM Complete build with zip creation and cleanup

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

REM Create zip with addon files only (copy from main folder)
powershell -Command "Copy-Item '..\*.lua' . -Force; Copy-Item '..\*.toc' . -Force; Copy-Item '..\Assets\logo.png' . -Force; Compress-Archive -Path '*.lua', '*.toc', 'logo.png' -DestinationPath 'Toxicify-Addon.zip' -Force; del *.lua; del *.toc; del logo.png"

echo.
echo SUCCESS: Complete build finished!
echo - Toxicify-Addon.zip (Addon files only)
echo.
pause
