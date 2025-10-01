# Toxicify Installer

This directory contains the installer files for the Toxicify addon.

## Files Included

- **Toxicify-Installer.nsi** - NSIS installer script
- **Build-Installer.bat** - Batch script to build installer
- **Build-Installer.ps1** - PowerShell script to build installer
- **README-Installer.md** - This documentation

## Prerequisites

### For Building the Installer

1. **NSIS (Nullsoft Scriptable Install System)**
   - Download from: https://nsis.sourceforge.io/
   - Install with default settings
   - Make sure `makensis.exe` is in your PATH

2. **Required Files**
   - All .lua files from the main addon directory
   - Toxicify.toc file
   - logo.png (optional, for installer icon)

### For Using the Installer

- Windows 7 or later
- World of Warcraft installation
- Administrator privileges (for installation)

## Building the Installer

### Method 1: Batch Script (Auto-download NSIS)
```cmd
cd Installer
Build-Installer.bat
```

### Method 2: Batch Script (Simple - Manual NSIS)
```cmd
cd Installer
Build-Installer-Simple.bat
```

### Method 3: PowerShell Script (Auto-download NSIS)
```powershell
# Basic build
.\Build-Installer.ps1

# Clean build (removes previous files)
.\Build-Installer.ps1 -Clean

# Verbose output
.\Build-Installer.ps1 -Verbose

# Clean and verbose
.\Build-Installer.ps1 -Clean -Verbose
```

### Method 4: PowerShell Script (Simple - Manual NSIS)
```powershell
# Basic build
.\Build-Installer-Simple.ps1

# Clean build
.\Build-Installer-Simple.ps1 -Clean

# Verbose output
.\Build-Installer-Simple.ps1 -Verbose
```

## What the Installer Does

### Files Installed
The installer only includes the essential addon files:
- **Commands.lua** - Slash commands
- **Constants.lua** - Configuration constants
- **Core.lua** - Core functionality
- **Events.lua** - Event handling
- **GroupFinder.lua** - Group Finder integration
- **Minimap.lua** - Minimap button
- **Options.lua** - Settings interface
- **Player.lua** - Player management
- **Toxicify.lua** - Main addon file
- **UI.lua** - User interface
- **Toxicify.toc** - Addon metadata

### Files Excluded
The installer deliberately excludes:
- Assets/ folder (images, documentation)
- ReadMe.md files
- Screenshots/
- Installer/ folder
- Any other non-essential files

### Installation Process
1. **WoW Detection**: Automatically detects WoW installation paths
2. **Directory Creation**: Creates proper AddOns directory structure
3. **File Installation**: Copies only .lua and .toc files
4. **Windows Registration**: Registers addon in Windows Programs and Features
5. **Desktop Shortcut**: Creates desktop shortcut for easy access
6. **Registry Entries**: Creates proper uninstaller entries with icon
7. **Uninstaller**: Provides clean removal option from Windows Programs

## Supported WoW Versions

The installer detects and supports:
- **Retail**: `World of Warcraft\_retail_\Interface\AddOns`
- **Classic**: `World of Warcraft\_classic_\Interface\AddOns`
- **Classic Era**: `World of Warcraft\_classic_era_\Interface\AddOns`

## Troubleshooting

### Build Issues
- **NSIS not found**: Install NSIS and add to PATH
- **Missing files**: Ensure all .lua files are in the main directory
- **Permission denied**: Run as administrator

### Installation Issues
- **WoW not detected**: Manually select installation directory
- **Permission denied**: Run installer as administrator
- **Addon not loading**: Check WoW addon settings

## Customization

### Modifying the Installer
Edit `Toxicify-Installer.nsi` to:
- Change installer appearance
- Add more files
- Modify installation paths
- Customize uninstaller

### Adding Files
To include additional files:
1. Add file copy commands in the `SecMain` section
2. Add file deletion commands in the `Uninstall` section
3. Rebuild the installer

## Output

After successful build:
- **Toxicify WoW Addon.exe** - Ready-to-distribute installer with custom icon
- **Size**: Typically 50-100 KB (only includes .lua files)
- **Compatibility**: Windows 7+ with WoW installation
- **Icon**: Uses Toxicify logo from Assets/logo.png

## Windows Programs Integration

### What Gets Registered
- **Display Name**: "Toxicify WoW Addon"
- **Version**: 1.0.0
- **Publisher**: Toxicify Team
- **Icon**: Toxicify logo
- **Description**: "World of Warcraft addon for marking toxic and pumper players"
- **Install Location**: Shows where addon is installed
- **Uninstall**: Can be removed from Windows Programs and Features

### Desktop Shortcut
- **Name**: "Toxicify WoW Addon"
- **Icon**: Toxicify logo
- **Function**: Opens uninstaller for easy removal
- **Location**: Desktop

### Uninstall Process
1. **Windows Programs**: Go to Settings > Apps > Apps & features
2. **Find**: "Toxicify WoW Addon" in the list
3. **Uninstall**: Click uninstall button
4. **Clean Removal**: All files and registry entries removed
5. **Confirmation**: Success message shown

## Distribution

The generated `Toxicify WoW Addon.exe` can be:
- Shared with other players
- Uploaded to addon websites
- Distributed via Discord/Guild channels
- Included in addon packs

## Support

For issues with the installer:
1. Check NSIS installation
2. Verify all source files are present
3. Run with administrator privileges
4. Check Windows Event Viewer for errors
