# Toxicify Installation Guide

This guide will help you install the Toxicify addon for World of Warcraft.

## Prerequisites

- World of Warcraft installed on your system
- Windows operating system
- Administrator privileges (recommended)

## Installation Methods

### Method 1: Automatic Installation (Recommended)

#### Option A: Batch Script (Simple)
1. Download the `Install-Toxicify.bat` file
2. Place it in the same folder as the Toxicify addon files
3. Right-click on `Install-Toxicify.bat` and select "Run as administrator"
4. Follow the on-screen instructions

#### Option B: PowerShell Script (Advanced)
1. Download the `Install-Toxicify.ps1` file
2. Place it in the same folder as the Toxicify addon files
3. Right-click on PowerShell and select "Run as administrator"
4. Navigate to the folder containing the installer
5. Run: `.\Install-Toxicify.ps1`

**PowerShell Parameters:**
- `-WoWPath "C:\Path\To\WoW\AddOns"` - Specify custom WoW AddOns path
- `-Silent` - Run without user prompts
- `-Force` - Overwrite existing installation

**Examples:**
```powershell
# Basic installation
.\Install-Toxicify.ps1

# Silent installation to specific path
.\Install-Toxicify.ps1 -WoWPath "D:\WoW\AddOns" -Silent

# Force overwrite existing installation
.\Install-Toxicify.ps1 -Force
```

### Method 2: Manual Installation

1. Locate your World of Warcraft installation folder
2. Navigate to `_retail_\Interface\AddOns\`
3. Create a new folder named `Toxicify`
4. Copy all addon files into the `Toxicify` folder
5. Start World of Warcraft and enable the addon

## Finding Your WoW Installation

The installer will automatically search for common WoW installation paths:

- `C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns`
- `C:\Program Files\World of Warcraft\_retail_\Interface\AddOns`
- `D:\World of Warcraft\_retail_\Interface\AddOns`
- `E:\World of Warcraft\_retail_\Interface\AddOns`
- `F:\World of Warcraft\_retail_\Interface\AddOns`

If your WoW installation is in a different location, you can specify the custom path during installation.

## File Structure

After installation, your addon folder should contain:

```
Toxicify/
├── Toxicify.toc          # Addon metadata
├── Core.lua              # Core functionality
├── Constants.lua         # Configuration constants
├── Player.lua            # Player management
├── Events.lua            # Event handling
├── Commands.lua          # Slash commands
├── UI.lua                # User interface
├── Options.lua           # Settings panel
├── GroupFinder.lua       # Group finder integration
├── Minimap.lua           # Minimap button
├── ReadMe.md             # Documentation
├── Assets/               # Images and resources
└── Install-Toxicify.*    # Installation scripts
```

## Troubleshooting

### Installation Fails
- **Run as Administrator**: Right-click the installer and select "Run as administrator"
- **Check Path**: Ensure the installer is in the same folder as the Toxicify addon files
- **Antivirus**: Temporarily disable antivirus software if it blocks the installation
- **Permissions**: Check that you have write permissions to the WoW AddOns folder

### Addon Not Appearing in Game
1. **Check Installation Path**: Verify files are in the correct `Toxicify` folder
2. **Enable Addon**: Go to Character Selection → AddOns → Enable Toxicify
3. **Check Interface Version**: Ensure the addon is compatible with your WoW version
4. **Reload UI**: Use `/reload` command in-game

### PowerShell Execution Policy Error
If you get a PowerShell execution policy error, run this command as administrator:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## Uninstallation

To remove the addon:
1. Navigate to your WoW AddOns folder
2. Delete the `Toxicify` folder
3. Restart World of Warcraft

## Support

If you encounter issues:
1. Check the installation log for error messages
2. Verify all required files are present
3. Ensure WoW is not running during installation
4. Try running the installer as administrator

## Features

Once installed, Toxicify provides:
- **Toxic/Pumper Lists**: Mark players as toxic or pumper
- **Group Finder Integration**: See toxic leaders in premade groups
- **Party Warnings**: Get warned when toxic players join your group
- **Target Frame Indicator**: See toxic/pumper status on target frame
- **Tooltip Integration**: Hover information for players
- **Import/Export**: Share lists with friends
- **Customizable Settings**: Adjust warning messages and timers

## Getting Started

After installation:
1. Start World of Warcraft
2. Enable the Toxicify addon in the AddOns menu
3. Use `/toxic` to see available commands
4. Use `/toxic settings` to configure the addon
5. Start marking players as toxic or pumper!

## License

This addon is provided as-is for personal use. Please respect other players and use responsibly.
