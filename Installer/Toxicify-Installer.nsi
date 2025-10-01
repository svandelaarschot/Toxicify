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

; Set installer icon (disabled for now)
; !if /FileExists "logo.ico"
;     !define MUI_ICON "logo.ico"
;     !define MUI_UNICON "logo.ico"
;     Icon "logo.ico"
; !endif

; Pages
!insertmacro MUI_PAGE_WELCOME
!if /FileExists "LICENSE.txt"
    !insertmacro MUI_PAGE_LICENSE "LICENSE.txt"
!endif
!insertmacro MUI_PAGE_DIRECTORY
!define MUI_DIRECTORYPAGE_TEXT_TOP "Toxicify will be installed to your World of Warcraft AddOns folder.$\r$\n$\r$\nIf you have multiple WoW installations, please select the correct one.$\r$\n$\r$\nThe installer has automatically detected the best location."
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

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
    MessageBox MB_OK "Toxicify WoW Addon has been successfully installed!$\r$\n$\r$\nInstallation location: $INSTDIR$\r$\n$\r$\nThe addon will appear in your WoW AddOns list.$\r$\nTo uninstall, simply delete the addon folder from your WoW AddOns directory."
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
    
    ; If no WoW installation found, show error and ask user
    MessageBox MB_YESNO "No World of Warcraft installation detected.$\r$\n$\r$\nWould you like to manually select the WoW AddOns folder?" IDYES ManualSelect IDNO DefaultInstall
    
    ManualSelect:
        ; Let user browse for WoW AddOns folder
        StrCpy $INSTDIR "$PROGRAMFILES\World of Warcraft\_retail_\Interface\AddOns\Toxicify"
        Return
    
    DefaultInstall:
        ; Default to Program Files if user cancels
        StrCpy $INSTDIR "$PROGRAMFILES\${APP_NAME}"
        Return
FunctionEnd

; Function to validate installation directory
Function ValidateInstallDir
    ; Check if the directory looks like a WoW AddOns folder
    StrCpy $R0 "$INSTDIR"
    
    ; If it contains "AddOns" in the path, it's likely correct
    StrCpy $R1 "$INSTDIR" "" -7
    StrCmp $R1 "\AddOns" PathValid CheckToxicify
    
    CheckToxicify:
        ; Check if it's the Toxicify subfolder (which is correct)
        StrCpy $R1 "$INSTDIR" "" -8
        StrCmp $R1 "\Toxicify" PathValid PathInvalid
    
    PathValid:
        Return
        
    PathInvalid:
        ; Check if it's the default Program Files path
        StrCmp $INSTDIR "$PROGRAMFILES\${APP_NAME}" DefaultPath ManualPath
        
    DefaultPath:
        ; This is the fallback path, which is OK
        Return
        
    ManualPath:
        ; Ask user if this is correct
        MessageBox MB_YESNO "The selected directory doesn't appear to be a WoW AddOns folder.$\r$\n$\r$\nSelected: $INSTDIR$\r$\n$\r$\nIs this correct?" IDYES PathValid IDNO PathInvalid
FunctionEnd

; Initialize installer
Function .onInit
    Call DetectWoW
FunctionEnd

; Validate directory before installation
Function .onVerifyInstDir
    Call ValidateInstallDir
FunctionEnd
