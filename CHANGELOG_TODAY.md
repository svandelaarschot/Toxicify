# Toxicify Changelog - October 5, 2025

## 🚀 Major Features Added

### 1. **Click-to-Whisper for Pumper Notifications**
- **Guild Member Online Notifications**: Click on pumper guild member notifications to automatically open a whisper
- **Friend Online Notifications**: Click on pumper friend notifications to automatically open a whisper
- **Visual Indicators**: 
  - Shows "Click to whisper" text for pumper notifications
  - Hover tooltip: "Click to whisper [PlayerName]"
  - Only pumper notifications are clickable (toxic notifications are not)

### 2. **Friend List Online Notifications**
- **WoW Friends**: Notifications when marked WoW friends come online
- **Friend Type Distinction**: Shows "(WoW)" label for regular friends vs "(Battle.net)" for Battle.net friends
- **Separate Toast Frames**: Friend notifications appear below guild notifications
- **Same Styling**: Uses the same subtle, transparent design as guild notifications

### 3. **Enhanced Self-Protection**
- **GUI Protection**: Cannot add yourself through main UI or settings panel buttons
- **Command Protection**: Enhanced existing command protection
- **Context Menu Protection**: Already prevented self-marking through right-click menus
- **Clear Error Messages**: Immediate feedback when trying to mark yourself

## 🎨 UI/UX Improvements

### 1. **More Subtle Notifications**
- **Reduced Background Opacity**: Changed from 0.8 to 0.3 (much more transparent)
- **Subtle Border**: Changed to tooltip-style border with very low opacity (0.2)
- **Smaller Frame**: Reduced size from 350x80 to 320x70 pixels
- **Muted Title**: Changed title color from bright green to subtle gray
- **Smaller Font**: Changed title from "Large" to normal size

### 2. **Improved Toast Positioning**
- **Guild Notifications**: Position at Y -100 (top of screen)
- **Friend Notifications**: Position at Y -180 (below guild notifications)
- **No Overlap**: Multiple notifications stack properly

## 🔧 Technical Fixes

### 1. **Lua Syntax Errors Fixed**
- **Goto Statement Error**: Fixed `'=' expected near 'continue'` error by replacing goto with proper conditional nesting
- **Missing Function Error**: Fixed `attempt to call field 'AddToxicifyContextMenu'` by implementing the missing function
- **Battle.net API Errors**: Fixed multiple Battle.net friend API compatibility issues

### 2. **Event System Improvements**
- **Invalid Events Removed**: Removed non-existent Battle.net friend events
- **Periodic Checking**: Added 30-second timer for Battle.net friend monitoring (since events don't work)
- **Self-Exclusion**: Added proper self-exclusion from guild and friend online notifications

### 3. **Context Menu System**
- **Missing Function**: Implemented `AddToxicifyContextMenu` function
- **Self-Protection**: Context menus don't show Toxicify options when right-clicking yourself
- **Smart Options**: Shows different options based on player status (marked vs unmarked)
- **Tooltip Fix**: Fixed `attempt to call local 'func' (a string value)` error by converting tooltip strings to functions

## 🐛 Bug Fixes

### 1. **API Compatibility Issues**
- **Battle.net Events**: Fixed `Attempt to register unknown event` errors
- **Battle.net Functions**: Fixed `attempt to call field 'GetNumFriends'` errors
- **Simplified Approach**: Removed problematic Battle.net API calls, focused on working features

### 2. **Notification System**
- **Self-Notifications**: Fixed issue where you could get notifications about yourself coming online
- **Duplicate Prevention**: Enhanced duplicate notification prevention
- **Cache Management**: Improved online notification cache handling

### 3. **Command System**
- **Syntax Error**: Fixed `'=' expected near 'for'` error in Commands.lua (removed extra "www" text)
- **Missing Command**: Added `/toxic testfriendtoast` command for testing friend notifications

### 4. **Context Menu System**
- **Tooltip Error**: Fixed `attempt to call local 'func' (a string value)` error by converting tooltip strings to functions
- **Menu API Compatibility**: Updated tooltip calls to use proper function format expected by Menu API

## 📋 New Commands

### Testing Commands
- `/toxic testfriendtoast` - Test WoW friend notification toasts
- `/toxic testguildtoast` - Test guild member notification toasts (existing, enhanced)

### Help Text Updates
- Added `/toxic testfriendtoast` to help command output
- Updated descriptions to clarify WoW friends vs Battle.net friends

## 🛡️ Security & Protection

### 1. **Complete Self-Marking Prevention**
- **Commands**: `/toxic add`, `/toxic addpumper`, `/toxic del` all prevent self-marking
- **GUI**: Main UI and settings panel buttons prevent self-marking
- **Context Menus**: No Toxicify options appear when right-clicking yourself

### 2. **Error Prevention**
- **Name Validation**: Checks both full name (with realm) and short name
- **Clear Feedback**: Immediate error messages when attempting self-marking
- **Consistent Behavior**: Same protection across all interfaces

## 🔄 System Architecture

### 1. **Event Handling**
- **Guild Events**: `GUILD_ROSTER_UPDATE` for guild member monitoring
- **Friend Events**: `FRIENDLIST_UPDATE` for WoW friend monitoring
- **Periodic Checking**: 30-second timer for comprehensive monitoring
- **Chat Events**: Enhanced chat message filtering for online/offline detection

### 2. **Notification Framework**
- **Separate Toast Frames**: Different frames for guild vs friend notifications
- **Click Handling**: Mouse events for pumper notification interactions
- **Auto-Hide Timers**: 5-second auto-hide for all notifications
- **Tooltip Integration**: Hover tooltips for better UX

## 📊 Performance Improvements

### 1. **Efficient Monitoring**
- **Cached Results**: Prevents duplicate notifications within same session
- **Selective Checking**: Only checks when guild toast notifications are enabled
- **Optimized Loops**: Improved friend and guild member checking loops

### 2. **Memory Management**
- **Timer Cleanup**: Proper cleanup of notification timers
- **Cache Management**: Efficient online notification cache handling
- **Event Cleanup**: Proper event registration and cleanup

## 🎯 User Experience

### 1. **Intuitive Interactions**
- **Click-to-Whisper**: Natural interaction for pumper notifications
- **Visual Feedback**: Clear indication of clickable vs non-clickable notifications
- **Error Prevention**: Proactive prevention of common mistakes (self-marking)

### 2. **Consistent Design**
- **Unified Styling**: All notifications use the same subtle, professional design
- **Clear Labels**: Distinct labeling for different notification types
- **Responsive Layout**: Proper positioning and stacking of multiple notifications

## 🔮 Future Considerations

### 1. **Battle.net Integration**
- **API Research**: May revisit Battle.net friend integration when API stabilizes
- **Alternative Methods**: Could explore alternative approaches for Battle.net friend monitoring

### 2. **Enhanced Features**
- **Custom Messages**: Could add customizable whisper messages for pumper notifications
- **Notification Settings**: Could add more granular notification preferences
- **Advanced Filtering**: Could add more sophisticated friend/guild filtering options

---

## 📝 Summary

Today's session focused on enhancing the user experience with click-to-whisper functionality, expanding friend list monitoring, and implementing comprehensive self-protection. The addon now provides a more intuitive and robust experience while maintaining its core functionality of tracking toxic and pumper players.

**Key Achievements:**
- ✅ Click-to-whisper for pumper notifications
- ✅ Friend list online monitoring
- ✅ Complete self-marking protection
- ✅ More subtle notification design
- ✅ Fixed all Lua syntax and API errors
- ✅ Enhanced context menu system

**Files Modified:**
- `Events.lua` - Major enhancements to notification system and event handling
- `Commands.lua` - Added test commands and enhanced help text
- `UI.lua` - Added self-protection to GUI buttons
- `Options.lua` - Added self-protection to settings panel buttons

**Total Changes:** 16+ major improvements and bug fixes
