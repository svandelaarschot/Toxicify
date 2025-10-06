-- Core.lua - Toxicify Core functionality and database management
local addonName, ns = ...

-- Gebruik de gedeelde namespace-tabel die WoW doorgeeft
-- Maak géén nieuwe lokale ns aan (anders zien andere files 'm niet).
ns.Core = ns.Core or {}

-- SavedVariables root
ToxicifyDB = ToxicifyDB or {}

-- Eénmalige init guard om dubbele initialisatie te voorkomen
ns.Core._initialized = ns.Core._initialized or false

-- =========================================
-- Debug helper
-- =========================================
function ns.Core.DebugPrint(message, forcePrint)
    if (ToxicifyDB and ToxicifyDB.DebugEnabled == true) or forcePrint then
        print("|cff39FF14[Toxicify DEBUG]|r " .. tostring(message))
    end
end

-- =========================================
-- Test warning popup
-- =========================================
function ns.Core.TestWarningPopup()
    local testPlayers = {"TestPlayer1", "TestPlayer2"}
    if ns.Events and ns.Events.ShowToxicWarningPopup then
        ns.Events.ShowToxicWarningPopup(testPlayers)
    else
        print("|cffff0000Toxicify:|r Events module not loaded!")
    end
end

-- =========================================
-- Footer
-- =========================================
function ns.Core.GetFooterText()
    return "|cffaaaaaaCreated by Alvarín-Silvermoon - v2025|r"
end

-- =========================================
-- Shared auto-completion (UI helper)
-- =========================================
function ns.Core.CreateAutoCompletion(inputBox, parentFrame)
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
            suggestionBox.children[#suggestionBox.children+1] = btn
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
    inputBox:SetScript("OnEditFocusLost", function()
        local delay = (ns.Constants and ns.Constants.SUGGESTION_BOX_HIDE_DELAY) or 0.05
        C_Timer.After(delay, function() suggestionBox:Hide() end)
    end)

    return suggestionBox
end

-- =========================================
-- Defaults
-- =========================================
local function InitializeDefaults()
    -- Maak root als die niet bestaat (defensive)
    ToxicifyDB = ToxicifyDB or {}

    if ToxicifyDB.WhisperMessage == nil then
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

    if ToxicifyDB.PartyWarningEnabled == nil then
        ToxicifyDB.PartyWarningEnabled = true
    end

    if ToxicifyDB.LuaErrorsEnabled == nil then
        -- Alleen defaulten op basis van huidige CVar als er nog geen user setting is
        ToxicifyDB.LuaErrorsEnabled = (GetCVar("scriptErrors") == "1")
    end

    if ToxicifyDB.TargetFrameIndicatorEnabled == nil then
        ToxicifyDB.TargetFrameIndicatorEnabled = true
    end

    if ToxicifyDB.PopupTimerSeconds == nil then
        ToxicifyDB.PopupTimerSeconds = 25
    end

    if not ToxicifyDB.minimap then
        ToxicifyDB.minimap = { hide = false }
    end
end

-- =========================================
-- Core Initialize (aanroepen NA ADDON_LOADED)
-- =========================================
function ns.Core.Initialize()
    if ns.Core._initialized then
        return
    end
    ns.Core._initialized = true

    InitializeDefaults()

    -- CVar sync: volg de opgeslagen user setting
    if ToxicifyDB.LuaErrorsEnabled then
        SetCVar("scriptErrors", "1")
    else
        SetCVar("scriptErrors", "0")
    end

    if ns.UI and ns.UI.AddContextMenuMarking then
        ns.UI.AddContextMenuMarking()
    end

    -- Debug dump nu SavedVariables zeker geladen zijn
    print("|cff39FF14Toxicify:|r CORE.LUA LOADED!")
    print("|cff39FF14Toxicify:|r Database contents:")
    if ToxicifyDB and next(ToxicifyDB) then
        for k, v in pairs(ToxicifyDB) do
            print("  " .. tostring(k) .. " = " .. tostring(v))
        end
    else
        print("  Database is empty or nil!")
    end

    print("|cff39FF14Toxicify:|r Addon Loaded.")
end

-- =========================================
-- DB accessors
-- =========================================
function ns.Core.GetDatabase()
    return ToxicifyDB
end

function ns.Core.SetDatabaseValue(key, value)
    ToxicifyDB[key] = value
end

function ns.Core.GetDatabaseValue(key, defaultValue)
    local v = ToxicifyDB[key]
    if v == nil then return defaultValue end
    return v
end

-- =========================================
-- Base64 helpers
-- =========================================
local base64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function base64encode(data)
    return ((data:gsub('.', function(x)
        local r, b = '', x:byte()
        for i = 8, 1, -1 do r = r .. (b % 2^i - b % 2^(i-1) > 0 and '1' or '0') end
        return r
    end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c = 0
        for i = 1, 6 do c = c + (x:sub(i,i) == '1' and 2^(6-i) or 0) end
        return base64chars:sub(c+1, c+1)
    end) .. ({ '', '==', '=' })[#data % 3 + 1])
end

local function base64decode(data)
    data = string.gsub(data, '[^'..base64chars..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r, f = '', (base64chars:find(x) - 1)
        for i = 6, 1, -1 do r = r .. (f % 2^i - f % 2^(i-1) > 0 and '1' or '0') end
        return r
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c = 0
        for i = 1, 8 do c = c + (x:sub(i,i) == '1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end

-- =========================================
-- Export / Import
-- =========================================
function ns.Core.ExportList()
    local data = {}
    for name, status in pairs(ToxicifyDB) do
        if status == "toxic" or status == "pumper" then
            data[#data+1] = name .. ":" .. status
        end
    end
    local payload = table.concat(data, ";")

    local checksum = 0
    for i = 1, #payload do
        checksum = checksum + string.byte(payload, i)
    end

    local dataString = "TOXICIFYv2|" .. payload .. "|" .. checksum
    local encoded = base64encode(dataString)

    return "TX:" .. encoded
end

function ns.Core.ImportList(str)
    if not str or str == "" then
        return false, "No data provided"
    end

    str = str:gsub("^%s+", ""):gsub("%s+$", "")
    ns.Core.DebugPrint("Importing data: " .. str:sub(1, 30) .. "...")

    local encoded = str:match("^TX:(.+)$")
    if encoded then
        ns.Core.DebugPrint("Using new secure format")
        local ok, decoded = pcall(base64decode, encoded)
        if not ok or not decoded or decoded == "" then
            return false, "Invalid encoding - data may be corrupted"
        end

        local version, payload, checksum = decoded:match("^(TOXICIFYv2)|(.+)|(%d+)$")
        if not version then
            return false, "Invalid data format"
        end

        local calc = 0
        for i = 1, #payload do
            calc = calc + string.byte(payload, i)
        end
        if tostring(calc) ~= checksum then
            return false, "Data corruption detected"
        end

        local count = 0
        for entry in string.gmatch(payload, "([^;]+)") do
            local name, status = entry:match("([^:]+):([^:]+)")
            if name and status and (status == "toxic" or status == "pumper") then
                ToxicifyDB[name] = status
                count = count + 1
                ns.Core.DebugPrint("Imported: " .. name .. " as " .. status)
            end
        end

        return true, count .. " players imported successfully"
    else
        ns.Core.DebugPrint("Using legacy format")
        local version, payload, checksum = str:match("^(TOXICIFYv1)|(.+)|(%d+)$")
        if not version then
            return false, "Invalid format - not a Toxicify export string"
        end

        local calc = 0
        for i = 1, #payload do
            calc = calc + string.byte(payload, i)
        end
        if tostring(calc) ~= checksum then
            return false, "Data verification failed"
        end

        local count = 0
        for entry in string.gmatch(payload, "([^;]+)") do
            local name, status = entry:match("([^:]+):([^:]+)")
            if name and status then
                ToxicifyDB[name] = status
                count = count + 1
                ns.Core.DebugPrint("Imported: " .. name .. " as " .. status)
            end
        end

        return true, count .. " players imported (legacy format)"
    end
end

-- =========================================
-- Clipboard helpers
-- =========================================
function ns.Core.CopyToClipboard(text)
    if C_System and C_System.SetClipboard then
        C_System.SetClipboard(text)
        ns.Core.DebugPrint("Copied to clipboard: " .. text:sub(1, 30) .. "...")
        return true
    end
    ns.Core.DebugPrint("Clipboard copy failed - C_System.SetClipboard not available")
    return false
end

function ns.Core.GetFromClipboard()
    if C_System and C_System.GetClipboard then
        local clipboardData = C_System.GetClipboard()
        ns.Core.DebugPrint("Retrieved from clipboard: " .. (clipboardData and clipboardData:sub(1, 30) or "nil") .. "...")
        return clipboardData
    end
    ns.Core.DebugPrint("Clipboard read failed - C_System.GetClipboard not available")
    return ""
end

-- =========================================
-- Event driver: init op juiste moment
-- =========================================
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGOUT")

frame:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" and name == addonName then
        -- SavedVariables zijn nu beschikbaar
        ToxicifyDB = ToxicifyDB or {}
        ns.Core.Initialize()
    elseif event == "PLAYER_LOGOUT" then
        -- WoW schrijft SavedVariables automatisch weg.
        -- Zorg dat ToxicifyDB geen frames/userdata bevat.
    end
end)

-- Let op: GEEN directe ns.Core.Initialize() call hier!
-- We initialiseren uitsluitend via ADDON_LOADED.