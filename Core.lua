-- Core.lua - Toxicify Core functionality and database management
local addonName, ns = ...

-- Initialize namespace if not exists
if not ns then
    ns = {}
end

-- Core namespace
ns.Core = {}

-- Debug helper function
function ns.Core.DebugPrint(message)
    -- Only print if debug is explicitly enabled
    if ToxicifyDB and ToxicifyDB.DebugEnabled == true then
        print("|cff39FF14[Toxicify DEBUG]|r " .. message)
    end
end

-- General footer function
function ns.Core.GetFooterText()
    return "|cffaaaaaaCreated by Alvarín-Silvermoon - v2025|r"
end

-- Shared auto-completion functionality
function ns.Core.CreateAutoCompletion(inputBox, parentFrame)
    -- Suggestion box for auto-completion
    local suggestionBox = CreateFrame("Frame", nil, parentFrame, BackdropTemplateMixin and "BackdropTemplate")
    suggestionBox:SetSize(200, 110) -- max 5 * 20px + marge
    suggestionBox:SetPoint("TOPLEFT", inputBox, "BOTTOMLEFT", 0, -2)
    suggestionBox:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    suggestionBox:SetBackdropColor(0, 0, 0, 0.9)
    suggestionBox:SetFrameStrata("TOOLTIP")
    suggestionBox:Hide()

    local function UpdateSuggestions()
        for _, child in ipairs(suggestionBox.children or {}) do child:Hide() end
        suggestionBox.children = {}

        local text = inputBox:GetText():lower()
        if text == "" then suggestionBox:Hide() return end

        local suggestions = {}

        -- Groepsleden
        for i = 1, GetNumGroupMembers() do
            local unit = (IsInRaid() and ("raid"..i)) or ("party"..i)
            if UnitExists(unit) then
                local name = GetUnitName(unit, true)
                if name and name:lower():find(text) then
                    table.insert(suggestions, name)
                end
            end
        end

        -- Guildleden
        if IsInGuild() then
            for i = 1, GetNumGuildMembers() do
                local name = GetGuildRosterInfo(i)
                if name and name:lower():find(text) then
                    table.insert(suggestions, name)
                end
            end
        end

        -- Friends
        for i = 1, C_FriendList.GetNumFriends() do
            local info = C_FriendList.GetFriendInfoByIndex(i)
            if info and info.name and info.name:lower():find(text) then
                table.insert(suggestions, info.name)
            end
        end

        -- Bouw max 5
        local y = -5
        local count = 0
        for _, name in ipairs(suggestions) do
            count = count + 1
            if count > 5 then break end

            local btn = CreateFrame("Button", nil, suggestionBox, "UIPanelButtonTemplate")
            btn:SetSize(180, 18)
            btn:SetPoint("TOPLEFT", 10, y)
            btn:SetText(name)
            btn:SetScript("OnClick", function()
                inputBox:SetText(name)
                suggestionBox:Hide()
            end)
            table.insert(suggestionBox.children, btn)
            y = y - 20
        end

        if count > 0 then
            suggestionBox:SetHeight(count * 20 + 10)
            suggestionBox:Show()
        else
            suggestionBox:Hide()
        end
    end

    inputBox:SetScript("OnTextChanged", UpdateSuggestions)
    inputBox:SetScript("OnEditFocusLost", function() C_Timer.After(ns.Constants.SUGGESTION_BOX_HIDE_DELAY, function() suggestionBox:Hide() end) end)
    
    return suggestionBox
end

-- Database initialization
ToxicifyDB = ToxicifyDB or {}

-- Default settings
local function InitializeDefaults()
    if not ToxicifyDB.WhisperMessage then
        ToxicifyDB.WhisperMessage = "U have been marked as Toxic player by - Toxicify Addon"
    end
    
    if ToxicifyDB.WhisperOnMark == nil then
        ToxicifyDB.WhisperOnMark = false
    end
    
    if ToxicifyDB.IgnoreOnMark == nil then
        ToxicifyDB.IgnoreOnMark = false
    end
    
    if ToxicifyDB.HideInFinder == nil then
        ToxicifyDB.HideInFinder = false
    end
    
    if ToxicifyDB.DebugEnabled == nil then
        ToxicifyDB.DebugEnabled = false
    end
    -- Set default party warning setting
    ns.Core.DebugPrint("PartyWarningEnabled before: " .. tostring(ToxicifyDB.PartyWarningEnabled))
    if ToxicifyDB.PartyWarningEnabled == nil then
        ToxicifyDB.PartyWarningEnabled = true
        ns.Core.DebugPrint("Set PartyWarningEnabled to true (was nil)")
    else
        ns.Core.DebugPrint("PartyWarningEnabled already exists: " .. tostring(ToxicifyDB.PartyWarningEnabled))
    end
    
    if ToxicifyDB.LuaErrorsEnabled == nil then
        ToxicifyDB.LuaErrorsEnabled = false
    end
    
    -- Target frame indicator setting
    if ToxicifyDB.TargetFrameIndicatorEnabled == nil then
        ToxicifyDB.TargetFrameIndicatorEnabled = true
    end
    
    -- Popup timer setting
    if ToxicifyDB.PopupTimerSeconds == nil then
        ToxicifyDB.PopupTimerSeconds = 25
    end
    
    -- Check if scriptErrors is enabled in console
    if GetCVar("scriptErrors") == "1" then
        ToxicifyDB.LuaErrorsEnabled = true
    else
        ToxicifyDB.LuaErrorsEnabled = false
    end
    
    if not ToxicifyDB.minimap then
        ToxicifyDB.minimap = { hide = false }
    end
end

-- Core initialization
function ns.Core.Initialize()
    InitializeDefaults()
    
    -- Sync Lua errors setting with scriptErrors
    if ToxicifyDB.LuaErrorsEnabled then
        SetCVar("scriptErrors", "1")
    else
        SetCVar("scriptErrors", "0")
    end
    
    if ToxicifyDB.DebugEnabled then
        print("|cff39FF14Toxicify:|r Debug mode is enabled.")
    end
    
    -- Add context menu marking functionality
    if ns.UI and ns.UI.AddContextMenuMarking then
        ns.UI.AddContextMenuMarking()
    end
    
    print("|cff39FF14Toxicify:|r Addon Loaded.")
end

-- Database access functions
function ns.Core.GetDatabase()
    return ToxicifyDB
end

function ns.Core.SetDatabaseValue(key, value)
    ToxicifyDB[key] = value
end

function ns.Core.GetDatabaseValue(key, defaultValue)
    return ToxicifyDB[key] or defaultValue
end

-- Export functionality
function ns.Core.ExportList()
    local data = {}
    for name, status in pairs(ToxicifyDB) do
        if status == "toxic" or status == "pumper" then
            table.insert(data, name .. ":" .. status)
        end
    end
    local payload = table.concat(data, ";")

    local checksum = 0
    for i = 1, #payload do
        checksum = checksum + string.byte(payload, i)
    end

    return "TOXICIFYv1|" .. payload .. "|" .. checksum
end

-- Import functionality
function ns.Core.ImportList(str)
    if not str or str == "" then return false, "No data" end

    local version, payload, checksum = str:match("^(TOXICIFYv1)|(.+)|(%d+)$")
    if not version then return false, "Invalid format" end

    local calc = 0
    for i = 1, #payload do
        calc = calc + string.byte(payload, i)
    end
    if tostring(calc) ~= checksum then
        return false, "Checksum mismatch"
    end

    local count = 0
    for entry in string.gmatch(payload, "([^;]+)") do
        local name, status = entry:match("([^:]+):([^:]+)")
        if name and status then
            ToxicifyDB[name] = status
            count = count + 1
        end
    end

    return true, count .. " entries imported"
end

-- Debug command to test guild menu types
SLASH_TOXICIFY_GUILD_TEST1 = "/toxicifyguildtest"
SLASH_TOXICIFY_GUILD_TEST2 = "/tguildtest"
SlashCmdList["TOXICIFY_GUILD_TEST"] = function()
    ns.Core.DebugPrint("Testing guild menu types...")
    
    local guildMenuTypes = {
        "MENU_UNIT_GUILD", "MENU_UNIT_GUILD_MEMBER", "MENU_UNIT_GUILD_OFFICER", 
        "MENU_UNIT_GUILD_LEADER", "MENU_UNIT_GUILD_ONLINE", "MENU_UNIT_GUILD_OFFLINE", 
        "MENU_UNIT_GUILD_RANK", "MENU_UNIT_GUILD_ROSTER", "MENU_UNIT_GUILD_LIST", 
        "MENU_UNIT_GUILD_PANEL", "MENU_UNIT_GUILD_FRAME"
    }
    
    -- Test numeric guild menu types
    for i = 1, 10 do
        table.insert(guildMenuTypes, "MENU_UNIT_GUILD" .. i)
    end
    
    for _, menuType in ipairs(guildMenuTypes) do
        local success, error = pcall(function()
            -- Try to modify the menu to see if it exists
            Menu.ModifyMenu(menuType, function() end)
            ns.Core.DebugPrint(menuType .. " - Available (can modify)")
        end)
        
        if not success then
            ns.Core.DebugPrint(menuType .. " - Error: " .. tostring(error))
        end
    end
end

-- Simple debug command for guild testing
SLASH_TOXICIFY_DEBUG1 = "/toxicdebug"
SlashCmdList["TOXICIFY_DEBUG"] = function()
    ns.Core.DebugPrint("Toxicify Debug Commands:")
    ns.Core.DebugPrint("/toxicifyguildtest - Test guild menu types")
    ns.Core.DebugPrint("/tguildtest - Test guild menu types (short)")
    ns.Core.DebugPrint("/toxic debug - Toggle debug mode")
end

-- Simple test to see if guild menu types work
SLASH_TOXICIFY_SIMPLE_TEST1 = "/tsimple"
SlashCmdList["TOXICIFY_SIMPLE_TEST"] = function()
    ns.Core.DebugPrint("Testing simple guild menu types...")
    
    local testMenuTypes = {
        "MENU_UNIT_GUILD", "MENU_UNIT_PLAYER", "MENU_UNIT_TARGET"
    }
    
    for _, menuType in ipairs(testMenuTypes) do
        local success, error = pcall(function()
            Menu.ModifyMenu(menuType, function() end)
            ns.Core.DebugPrint(menuType .. " - Works!")
        end)
        
        if not success then
            ns.Core.DebugPrint(menuType .. " - Error: " .. tostring(error))
        end
    end
end

-- Test guild context menu registration
SLASH_TOXICIFY_GUILD_REGISTER1 = "/tguildregister"
SlashCmdList["TOXICIFY_GUILD_REGISTER"] = function()
    ns.Core.DebugPrint("Testing guild menu registration...")
    
    local guildMenuTypes = {
        "MENU_UNIT_GUILD", "MENU_UNIT_GUILD_MEMBER", "MENU_UNIT_GUILD_OFFICER", 
        "MENU_UNIT_GUILD_LEADER", "MENU_UNIT_GUILD_ONLINE", "MENU_UNIT_GUILD_OFFLINE", 
        "MENU_UNIT_GUILD_RANK"
    }
    
    for _, menuType in ipairs(guildMenuTypes) do
        local success, error = pcall(function()
            Menu.ModifyMenu(menuType, function() end)
            ns.Core.DebugPrint(menuType .. " - Registration successful!")
        end)
        
        if not success then
            ns.Core.DebugPrint(menuType .. " - Registration failed: " .. tostring(error))
        end
    end
end

-- Initialize on load
ns.Core.Initialize()