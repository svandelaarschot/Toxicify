; Toxicify Addon Installer
; NSIS Script for creating Windows installer

!define APP_NAME "Toxicify WoW Addon"
!define APP_VERSION "1.0.0"
!define APP_PUBLISHER "Alvarín-Silvermoon"
!define APP_COMPANY "MythicPlus Rocks"
!define APP_URL "https://github.com/your-repo/toxicify"

; Modern UI
!include "MUI2.nsh"

; General Settings
Name "${APP_NAME}"
OutFile "Toxicify WoW Addon.exe"
InstallDir "$PROGRAMFILES\${APP_NAME}"
RequestExecutionLevel admin

; Version Information
VIProductVersion "${APP_VERSION}.0"
VIAddVersionKey "ProductName" "${APP_NAME}"
VIAddVersionKey "ProductVersion" "${APP_VERSION}"
VIAddVersionKey "CompanyName" "${APP_COMPANY}"
VIAddVersionKey "LegalCopyright" "© 2025 ${APP_COMPANY}"
VIAddVersionKey "FileDescription" "${APP_NAME} Installer"
VIAddVersionKey "FileVersion" "${APP_VERSION}"

; Interface Settings
!define MUI_ABORTWARNING

; Set installer icon
!if /FileExists "logo.ico"
    !define MUI_ICON "logo.ico"
    !define MUI_UNICON "logo.ico"
    Icon "logo.ico"
!endif

; Pages
!insertmacro MUI_PAGE_WELCOME
!define MUI_WELCOMEPAGE_TITLE "Welcome to Toxicify WoW Addon Setup"
!define MUI_WELCOMEPAGE_TEXT "This wizard will guide you through the installation of Toxicify, a powerful World of Warcraft addon.$\r$\n$\r$\nToxicify enhances your WoW experience with:$\r$\n• Advanced player tracking and monitoring$\r$\n• Modern, customizable user interface$\r$\n• Group finder integration$\r$\n• Real-time player statistics$\r$\n• Easy configuration options$\r$\n$\r$\nClick Next to continue with the installation."
!if /FileExists "LICENSE.txt"
    !insertmacro MUI_PAGE_LICENSE "LICENSE.txt"
!endif
!insertmacro MUI_PAGE_DIRECTORY
!define MUI_DIRECTORYPAGE_TEXT_TOP "Toxicify is a powerful World of Warcraft addon that enhances your gameplay experience.$\r$\n$\r$\nFeatures:$\r$\n• Advanced player tracking and monitoring$\r$\n• Customizable UI with modern design$\r$\n• Group finder integration$\r$\n• Real-time player statistics$\r$\n• Easy-to-use configuration options$\r$\n$\r$\nThe installer will create a 'Toxicify' folder in your WoW AddOns directory.$\r$\nIf you have multiple WoW installations, please select the correct AddOns folder."
!define MUI_DIRECTORYPAGE_VALIDATE ""
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!define MUI_FINISHPAGE_TITLE "Installation Complete"
!define MUI_FINISHPAGE_TEXT "Toxicify has been successfully installed!$\r$\n$\r$\nTo use the addon:$\r$\n1. Launch World of Warcraft$\r$\n2. Go to AddOns menu in character selection$\r$\n3. Enable Toxicify$\r$\n4. Log in and enjoy the enhanced experience!$\r$\n$\r$\nFor support and updates, visit our website or contact the developer."

; No uninstaller pages needed

; Languages
!insertmacro MUI_LANGUAGE "English"

; Installer Sections
Section "Toxicify Addon" SecMain
    ; Create the addon directory
    CreateDirectory "$INSTDIR"
    SetOutPath "$INSTDIR"
    
    ; Install only .lua and .toc files
    File "Commands.lua"
    File "Constants.lua"
    File "Core.lua"
    File "Events.lua"
    File "GroupFinder.lua"
    File "Minimap.lua"
    File "Options.lua"
    File "Player.lua"
    File "Toxicify.lua"
    File "UI.lua"
    File "Toxicify.toc"
    
    ; Copy logo for uninstaller (only if exists)
    !if /FileExists "logo.ico"
        File "logo.ico"
    !else if /FileExists "logo.png"
        File "logo.png"
    !endif
    
    ; No uninstaller or registry entries needed
    
    ; Show success message
    MessageBox MB_OK "Toxicify has been successfully installed!$\r$\n$\r$\nInstallation location: $INSTDIR$\r$\n$\r$\nTo use the addon:$\r$\n1. Launch World of Warcraft$\r$\n2. Go to AddOns menu in character selection$\r$\n3. Enable Toxicify$\r$\n4. Log in and enjoy the enhanced experience!$\r$\n$\r$\nTo uninstall, simply delete the addon folder from your WoW AddOns directory."
SectionEnd

; No uninstaller section needed

; Function to detect WoW installation
Function DetectWoW
    ; Check common WoW installation paths
    ; Retail WoW paths
    IfFileExists "$PROGRAMFILES\World of Warcraft\_retail_\Interface\AddOns" 0 +3
        StrCpy $INSTDIR "$PROGRAMFILES\World of Warcraft\_retail_\Interface\AddOns\Toxicify"
        Return
    
    IfFileExists "$PROGRAMFILES64\World of Warcraft\_retail_\Interface\AddOns" 0 +3
        StrCpy $INSTDIR "$PROGRAMFILES64\World of Warcraft\_retail_\Interface\AddOns\Toxicify"
        Return
    
    ; Classic WoW paths
    IfFileExists "$PROGRAMFILES\World of Warcraft\_classic_\Interface\AddOns" 0 +3
        StrCpy $INSTDIR "$PROGRAMFILES\World of Warcraft\_classic_\Interface\AddOns\Toxicify"
        Return
    
    IfFileExists "$PROGRAMFILES64\World of Warcraft\_classic_\Interface\AddOns" 0 +3
        StrCpy $INSTDIR "$PROGRAMFILES64\World of Warcraft\_classic_\Interface\AddOns\Toxicify"
        Return
    
    ; Classic Era WoW paths
    IfFileExists "$PROGRAMFILES\World of Warcraft\_classic_era_\Interface\AddOns" 0 +3
        StrCpy $INSTDIR "$PROGRAMFILES\World of Warcraft\_classic_era_\Interface\AddOns\Toxicify"
        Return
    
    IfFileExists "$PROGRAMFILES64\World of Warcraft\_classic_era_\Interface\AddOns" 0 +3
        StrCpy $INSTDIR "$PROGRAMFILES64\World of Warcraft\_classic_era_\Interface\AddOns\Toxicify"
        Return
    
    ; Check common alternative drive locations
    IfFileExists "D:\World of Warcraft\_retail_\Interface\AddOns" 0 +3
        StrCpy $INSTDIR "D:\World of Warcraft\_retail_\Interface\AddOns\Toxicify"
        Return
    
    IfFileExists "E:\World of Warcraft\_retail_\Interface\AddOns" 0 +3
        StrCpy $INSTDIR "E:\World of Warcraft\_retail_\Interface\AddOns\Toxicify"
        Return
    
    IfFileExists "F:\World of Warcraft\_retail_\Interface\AddOns" 0 +3
        StrCpy $INSTDIR "F:\World of Warcraft\_retail_\Interface\AddOns\Toxicify"
        Return
    
    ; If no WoW installation found, set a default path
    StrCpy $INSTDIR "$PROGRAMFILES\World of Warcraft\_retail_\Interface\AddOns\Toxicify"
    Return
FunctionEnd

; Function to validate installation directory
Function ValidateInstallDir
    ; Always allow installation - we'll create the directory if needed
    ; Ensure the path ends with Toxicify subfolder
    StrCpy $R0 "$INSTDIR"
    StrCpy $R1 "$INSTDIR" "" -8
    StrCmp $R1 "\Toxicify" PathValid AddToxicify
    
    AddToxicify:
        ; Add Toxicify subfolder if not present
        StrCpy $INSTDIR "$INSTDIR\Toxicify"
    
    PathValid:
        Return
FunctionEnd

; Initialize installer
Function .onInit
    Call DetectWoW
FunctionEnd

; Validate directory before installation
Function .onVerifyInstDir
    Call ValidateInstallDir
FunctionEnd
