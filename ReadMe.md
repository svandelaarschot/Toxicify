# Toxicify

**Keep your runs clean and fun — mark toxic players and highlight the pumpers!**

Toxicify helps you keep track of players you encounter in dungeons, raids, PvP, or the Group Finder. With one click or command, you can tag a player as **Toxic** (to avoid them in the future) or as a **Pumper** (great teammates you want to remember).

Once added, players are clearly highlighted in your party/raid frames, tooltips, and the Group Finder. You'll never forget who ruined your key — or who carried it!

***

## ✨ Features

### 📝 Toxic & Pumper Lists

*   Mark players manually with `/toxic add Name-Realm` or via right-click context menus.
*   Automatically highlight them with **icons** and **color-coded names** (red for Toxic, green for Pumper).
*   **Target frame indicator** - See Toxic/Pumper status directly on the target frame.

### 🔎 Group Finder Integration

*   Group leaders are flagged in the **Premade Groups UI**.
*   Toxic leaders get a **skull icon** and red name.
*   Pumper leaders get a **star icon** and green name.
*   Optionally filter out Toxic groups entirely with one checkbox.

### 👥 Party & Raid Frame Highlighting

*   Toxic players in your group show as **"Toxic: Name"** in red.
*   Pumpers show as **"Pumper: Name"** in green.

### 🧾 Tooltip Enhancements

*   Hovering over a player shows a Toxic/Pumper icon and label in their tooltip.

### 🎯 Target Frame Indicator

*   **Target frame overlay** - Shows Toxic/Pumper status directly above the target frame.
*   **Real-time updates** - Updates immediately when targeting a new player.
*   **Visual indicators** - Red "TOXIC" with skull icon, green "PUMPER" with star icon.
*   **Clean design** - Subtle overlay that doesn't interfere with the target frame.

### 💬 Whisper & Ignore Options

*   Automatically whisper toxic players with a customizable message.
*   Optionally add them directly to your **Ignore List**.

### ⚠️ Toxic Player Warnings

*   **Automatic popup warning** when toxic players join your group.
*   Shows a detailed list of toxic players with countdown timer.
*   Option to leave group directly from the warning popup.
*   Warning only appears when you're actually in a party with toxic players.
*   **Customizable Auto-Close timer** - Set how long the warning stays open (1-300 seconds).
*   Use `/toxic testwarning` to manually test the warning popup.
*   Use `/toxic partywarning` to toggle automatic warnings on/off.

### 🔄 Import & Export

*   Share your lists with friends using a secure **export string with checksum validation**.
*   Import shared lists easily in-game.

### 🖥️ Custom UI Window

*   Manage your Toxic & Pumper lists with a dedicated UI.
*   Includes:  
    *   Search bar with real-time filtering.
    *   Auto-completion from your group, guild, and friends.
    *   Dropdown to change between Toxic and Pumper status.
    *   **Remove All** button.
    *   **ReloadUI** button for quick resets.

### ⚙️ Quality of Life

*   LibDataBroker minimap icon for quick access.
*   Slash commands for all major features.
*   Clean design with tooltips and confirmations.
*   Debug mode for troubleshooting.

***

## 🔧 Slash Commands

### Basic Commands
*   `/toxic add <name-realm>` → Add a Toxic
*   `/toxic addpumper <name-realm>` → Add a Pumper
*   `/toxic del <name-realm>` → Remove player from list
*   `/toxic list` → Show current list

### Import/Export
*   `/toxic export` → Export your list
*   `/toxic import <string>` → Import a shared list

### UI & Settings
*   `/toxic ui` → Open the Toxicify list window
*   `/toxic settings` → Open addon settings
*   `/toxic config` → Open addon settings (alias)

### Warning System
*   `/toxic testwarning` → Show test warning popup
*   `/toxic partywarning` → Toggle automatic warnings on/off

### Debug & Advanced
*   `/toxic debug` → Toggle debug mode (shows in main chat)
*   `/toxic luaerrors` → Toggle Lua errors (requires debug mode)
*   `/toxic contextmenu` → Activate context menu marking

***

## ⚙️ Settings

Access settings via `/toxic settings` or the Interface Options:

### General Settings
*   **Hide Toxic Groups** - Filter out groups with toxic leaders in Premade Groups
*   **Party Warning** - Show warning popup when joining parties with toxic players
*   **Target Frame Indicator** - Show toxic/pumper status above the target frame when targeting players
*   **Auto-Close Timer** - Set how long the warning popup stays open (1-300 seconds, default: 25)
*   **Whisper Message** - Customize the message sent to toxic players
*   **Whisper on Mark** - Automatically whisper when marking someone as toxic
*   **Ignore on Mark** - Add toxic players to your ignore list

### Debug Settings
*   **Debug Mode** - Show detailed debug information in chat
*   **Lua Errors** - Enable/disable Lua error reporting (requires debug mode)

### Minimap
*   **Show/Hide Minimap Icon** - Toggle the minimap button

***

## 💡 Example Use Cases

*   **Avoid that one player who always leaves keys** - Mark them as Toxic and never group with them again
*   **Remember great teammates** - Mark skilled players as Pumpers to invite them again
*   **Share lists with guildmates** - Export your lists so your guild can avoid the same toxic players
*   **Auto-ignore toxic players** - Set Toxicify to automatically add toxic players to your ignore list
*   **Get warned about toxic groups** - Enable party warnings to know when toxic players join your group
*   **Quick target identification** - See immediately if a targeted player is Toxic or Pumper without hovering

***

## 🚀 Getting Started

1. **Install the addon** - Place in your AddOns folder
2. **Mark your first player** - Use `/toxic add PlayerName-Realm` or right-click on a player
3. **Test the warning** - Use `/toxic testwarning` to see how the warning popup works
4. **Customize settings** - Use `/toxic settings` to configure the addon to your preferences
5. **Share with friends** - Use `/toxic export` to share your lists

***

## 🔧 Troubleshooting

### Debug Mode
Enable debug mode with `/toxic debug` to see detailed information about:
*   When players are detected as toxic/pumper
*   When warnings are triggered
*   Event handling and group updates

### Common Issues
*   **Warning not showing** - Check if party warnings are enabled with `/toxic partywarning`
*   **Players not highlighting** - Make sure they're marked correctly with `/toxic list`
*   **Import not working** - Check the export string format and try again

### Support
*   Use `/toxic debug` to enable debug mode for troubleshooting
*   Check the chat for debug messages when issues occur
*   Use `/toxic testwarning` to test the warning system

***

⚔️ **Created by Alvarín-Silvermoon (EU)**