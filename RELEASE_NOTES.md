# Toxicify Release Notes

## Version 2.2 - Options Refactoring Update
*Released: December 2024*

### 🚀 Major Changes

#### **Options System Refactoring**
- **Split Options.lua into multiple focused files** for better maintainability and organization
- **Improved code structure** with dedicated files for each settings tab
- **Enhanced developer experience** with cleaner, more focused code files

### 📁 New File Structure

#### **New Options Files:**
- `OptionsCore.lua` - Shared utilities and Binder system for all option panels
- `OptionsRoot.lua` - Main description panel with addon overview
- `OptionsGeneral.lua` - General settings (warnings, timers, debug options)
- `OptionsList.lua` - Toxic & Pumper List Management panel
- `OptionsIO.lua` - Import/Export functionality panel
- `OptionsWhisper.lua` - Whisper & Ignore Settings panel
- `Options.lua` - Main registration file (now much smaller and focused)

### 🔧 Technical Improvements

#### **Options Panel Enhancements:**
- **Fixed toxic list display issue** - List now appears immediately when opening settings
- **Improved scroll frame sizing** - Increased width from 500px to 630px for better visibility
- **Enhanced refresh mechanism** - Added proper timing and multiple refresh attempts
- **Better error handling** - Added debug output and fallback mechanisms

#### **Code Organization:**
- **Modular design** - Each settings tab is now in its own file
- **Shared utilities** - Common functionality centralized in OptionsCore.lua
- **Proper loading order** - Updated TOC file with correct file sequence
- **Maintained functionality** - All existing features preserved

### 🐛 Bug Fixes

- **Fixed toxic list not appearing** in settings until switching tabs
- **Improved timing issues** with UI refresh calls
- **Enhanced scroll frame positioning** and sizing
- **Better content frame initialization** for list display

### 📋 File Changes

#### **Modified Files:**
- `Toxicify.toc` - Updated to include new option files in correct order
- `Options.lua` - Refactored to main registration file (reduced from 527 to 36 lines)

#### **New Files Added:**
- `OptionsCore.lua` (128 lines) - Shared utilities and Binder system
- `OptionsRoot.lua` (63 lines) - Main description panel
- `OptionsGeneral.lua` (143 lines) - General settings panel
- `OptionsList.lua` (115 lines) - List management panel
- `OptionsIO.lua` (65 lines) - Import/Export panel
- `OptionsWhisper.lua` (85 lines) - Whisper settings panel

### 🎯 Benefits

#### **For Developers:**
- **Easier maintenance** - Each settings tab can be modified independently
- **Better code organization** - Clear separation of concerns
- **Reduced file complexity** - No more 500+ line monolithic options file
- **Improved debugging** - Issues can be isolated to specific panels

#### **For Users:**
- **Same functionality** - All existing features work exactly as before
- **Better performance** - More efficient loading and refresh mechanisms
- **Improved reliability** - Fixed display issues with toxic list
- **Enhanced user experience** - List appears immediately in settings

### 🔄 Migration Notes

- **No user action required** - All settings and data preserved
- **Automatic upgrade** - Changes are transparent to users
- **Backward compatibility** - All existing functionality maintained
- **No data loss** - All toxic/pumper lists and settings remain intact

### 📊 Statistics

- **Code reduction:** Main Options.lua reduced from 527 to 36 lines (93% reduction)
- **File organization:** 1 large file split into 7 focused files
- **Maintainability:** Each settings tab now in dedicated file
- **Performance:** Improved loading and refresh timing

---

*This update focuses on code organization and maintainability while preserving all existing functionality and improving the user experience.*
