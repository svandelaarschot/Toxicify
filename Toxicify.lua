local addonName, ns = ...
ToxicifyDB = ToxicifyDB or {}

-- Default whisper message
if not ToxicifyDB.WhisperMessage then
    ToxicifyDB.WhisperMessage = "U have been marked as Toxic player by - Toxicify Addon"
end

print("|cff39FF14Toxicify:|r Addon is loading...")

---------------------------------------------------
-- Minimap / LibDataBroker button
---------------------------------------------------
local LDB = LibStub("LibDataBroker-1.1"):NewDataObject("Toxicify", {
    type = "launcher",
    text = "Toxicify",
    icon = "Interface\\Icons\\ability_creature_poison_05", -- poison icon
    OnClick = function(self, button)
        if button == "LeftButton" then
            InterfaceOptionsFrame_OpenToCategory("Toxicify")
            InterfaceOptionsFrame_OpenToCategory("Toxicify") -- double call fixes Blizzard bug
        elseif button == "RightButton" then
            print("|cff39FF14Toxicify:|r Use /toxic add <playername-realm> or open settings.")
        end
    end,
    OnTooltipShow = function(tooltip)
        tooltip:AddLine("|cff39FF14Toxicify|r")
        tooltip:AddLine("Click to open settings")
        tooltip:AddLine("Right click for quick options")
    end,
})

local icon = LibStub("LibDBIcon-1.0", true)
ToxicifyDB.minimap = ToxicifyDB.minimap or { hide = false }
if icon then
    icon:Register("Toxicify", LDB, ToxicifyDB.minimap)
end

---------------------------------------------------
-- Group roster updates (covers party/raid/M+)
---------------------------------------------------
local function UpdateGroupMembers()
    if not IsInGroup() then return end
    for i = 1, GetNumGroupMembers() do
        local unit = (IsInRaid() and "raid"..i) or (i == GetNumGroupMembers() and "player" or "party"..i)
        if UnitExists(unit) then
            local name = GetUnitName(unit, true)
            if name and ns.IsToxic(name) then
                local frame = ns.GetUnitFrame(unit)
                if frame and frame.name and frame.name.SetText then
                    frame.name:SetText("|cffff0000 Toxic: " .. name .. "|r")
                end
            end
            if name and ns.IsPumper(name) then
                local frame = ns.GetUnitFrame(unit)
                if frame and frame.name and frame.name.SetText then
                    frame.name:SetText("|cff00ff00 Pumper: " .. name .. "|r")
                end
            end
        end
    end
end

local rosterFrame = CreateFrame("Frame")
rosterFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
rosterFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
rosterFrame:SetScript("OnEvent", UpdateGroupMembers)

---------------------------------------------------
-- Group Finder Toxicify Button (always create)
---------------------------------------------------
local function CreateGroupFinderButton()
    if _G.ToxicifyToggleButton then return end
    if not (LFGListFrame and LFGListFrame.SearchPanel) then return end

    local toggleBtn = CreateFrame("Button", "ToxicifyToggleButton", LFGListFrame.SearchPanel, "UIPanelButtonTemplate")
    toggleBtn:SetSize(80, 22)
    toggleBtn:SetText("Toxicify")

    -- Plaats hem netjes naast Filter
    if _G.LFGListFrameSearchPanelFilterButton then
        toggleBtn:SetPoint("LEFT", LFGListFrameSearchPanelFilterButton, "RIGHT", 5, 0)
    else
        toggleBtn:SetPoint("LEFT", LFGListFrame.SearchPanel.RefreshButton, "RIGHT", -110, 0)
    end

    toggleBtn:SetScript("OnClick", function()
        if not _G.ToxicifyListFrame then
            ns.CreateToxicifyUI()
        end
        if _G.ToxicifyListFrame:IsShown() then
            _G.ToxicifyListFrame:Hide()
        else
            _G.ToxicifyListFrame:Refresh()
            _G.ToxicifyListFrame:Show()
        end
    end)
end

---------------------------------------------------
-- Loader to wait for Blizzard’s GroupFinder UI
---------------------------------------------------
local gfLoader = CreateFrame("Frame")
gfLoader:RegisterEvent("ADDON_LOADED")
gfLoader:RegisterEvent("PLAYER_ENTERING_WORLD")
gfLoader:RegisterEvent("LFG_LIST_SEARCH_RESULTS_RECEIVED")
gfLoader:SetScript("OnEvent", function(self, event, addon)
    if event == "PLAYER_ENTERING_WORLD"
       or event == "LFG_LIST_SEARCH_RESULTS_RECEIVED"
       or (event == "ADDON_LOADED" and addon == "Blizzard_LookingForGroupUI") then
        C_Timer.After(1, function()
            if LFGListFrame and LFGListFrame.SearchPanel then
                CreateGroupFinderButton()
            end
        end)
    end
end)

---------------------------------------------------
-- Group roster updates (covers party/raid/M+)
---------------------------------------------------
local function UpdateGroupMembers()
    if not IsInGroup() then return end
    for i = 1, GetNumGroupMembers() do
        local unit = (IsInRaid() and "raid"..i) or (i == GetNumGroupMembers() and "player" or "party"..i)
        if UnitExists(unit) then
            local name = GetUnitName(unit, true)
            if name and ns.IsToxic(name) then
                local frame = ns.GetUnitFrame(unit)
                if frame and frame.name and frame.name.SetText then
                    frame.name:SetText("|cffff0000 Toxic: " .. name .. "|r")
                end
            end
            if name and ns.IsPumper(name) then
                local frame = ns.GetUnitFrame(unit)
                if frame and frame.name and frame.name.SetText then
                    frame.name:SetText("|cff00ff00 Pumper: " .. name .. "|r")
                end
            end
        end
    end
end

local rosterFrame = CreateFrame("Frame")
rosterFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
rosterFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
rosterFrame:SetScript("OnEvent", UpdateGroupMembers)

---------------------------------------------------
-- Helpers
---------------------------------------------------
function ns.NormalizePlayerName(playerName)
    if not playerName or playerName == "" then return nil end

    -- split Name-Realm
    local name, realm = strsplit("-", playerName, 2)
    name = name:gsub("^%l", string.upper) -- hoofdletter eerste letter
    realm = realm or GetNormalizedRealmName()

    return name .. "-" .. realm
end

function ns.IsPumper(playerName)
    if not playerName then return false end
    return ToxicifyDB[ns.NormalizePlayerName(playerName)] == "pumper"
end

function ns.IsToxic(playerName)
    if not playerName then return false end
    return ToxicifyDB[ns.NormalizePlayerName(playerName)] == "toxic"
end

function ns.MarkPumper(playerName)
    local norm = ns.NormalizePlayerName(playerName)
    if norm then
        ToxicifyDB[norm] = "pumper"
        print("|cff00ff00Toxicify:|r " .. playerName .. " marked as Pumper.")
    end
end

function ns.MarkToxic(playerName)
    local norm = ns.NormalizePlayerName(playerName)
    if norm then
        ToxicifyDB[norm] = "toxic"
        print("|cffff0000Toxicify:|r " .. playerName .. " marked as Toxic.")
        if ToxicifyDB.WhisperOnMark then
            local msg = ToxicifyDB.WhisperMessage or "U have been marked as Toxic player by - Toxicify Addon"
            SendChatMessage(msg, "WHISPER", nil, playerName)
        end
        -- Ignore
        if ToxicifyDB.IgnoreOnMark then
            C_FriendList.AddIgnore(playerName)
            print("|cffaaaaaaToxicify:|r " .. playerName .. " has also been added to your Ignore list.")
        end
    end
end

function ns.UnmarkToxic(playerName)
    local norm = ns.NormalizePlayerName(playerName)
    if norm and ToxicifyDB[norm] then
        ToxicifyDB[norm] = nil
        print("|cffaaaaaaToxicify:|r " .. playerName .. " removed from list.")
    end
    -- Remove from ignore if option is enabled
    if ToxicifyDB.IgnoreOnMark then
        C_FriendList.DelIgnore(playerName)
        print("|cffaaaaaaToxicify:|r " .. playerName .. " has also been removed from your Ignore list.")
    end
end

function ns.CreateToxicifyUI()
    if _G.ToxicifyListFrame then return end

    local f = CreateFrame("Frame", "ToxicifyListFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
    f:SetSize(620, 500)
    f:SetPoint("CENTER")
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 16,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    f:Hide()

    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetClampedToScreen(true)
    f:SetFrameStrata("DIALOG")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)

    -- Title
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -15)
    title:SetText("|cff39FF14Toxicify List|r")

    -- Close button
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    -- Player label
    local playerLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    playerLabel:SetPoint("TOPLEFT", 20, -50)
    playerLabel:SetText("Player:")

    -- Add box
    local addBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    addBox:SetSize(200, 22)
    addBox:SetPoint("LEFT", playerLabel, "RIGHT", 10, 0)
    addBox:SetAutoFocus(false)

    -- Dropdown voor Toxic/Pumper
    local roleDrop = CreateFrame("Frame", "ToxicifyRoleDrop", f, "UIDropDownMenuTemplate")
    roleDrop:SetPoint("LEFT", addBox, "RIGHT", -15, -3)
    UIDropDownMenu_SetWidth(roleDrop, 100)
    UIDropDownMenu_SetText(roleDrop, "Toxic")

    UIDropDownMenu_Initialize(roleDrop, function(self, level)
        local info = UIDropDownMenu_CreateInfo()

        info.text = "Toxic"
        info.func = function() UIDropDownMenu_SetText(roleDrop, "Toxic") end
        UIDropDownMenu_AddButton(info)

        info.text = "Pumper"
        info.func = function() UIDropDownMenu_SetText(roleDrop, "Pumper") end
        UIDropDownMenu_AddButton(info)
    end)

    -- Add button
    local addBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    addBtn:SetSize(60, 22)
    addBtn:SetPoint("LEFT", roleDrop, "RIGHT", 10, 0)
    addBtn:SetText("Add")

    -- Remove all
    local clearBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    clearBtn:SetSize(100, 22)
    clearBtn:SetPoint("LEFT", addBtn, "RIGHT", 10, 0)
    clearBtn:SetText("Remove All")

    -- Suggestion box (max 5)
    local suggestionBox = CreateFrame("Frame", nil, f, BackdropTemplateMixin and "BackdropTemplate")
    suggestionBox:SetSize(200, 110) -- max 5 * 20px + marge
    suggestionBox:SetPoint("TOPLEFT", addBox, "BOTTOMLEFT", 0, -2)
    suggestionBox:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground", -- zwarte achtergrond
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    suggestionBox:SetBackdropColor(0, 0, 0, 0.9) -- echt zwart met lichte transparantie
    suggestionBox:SetFrameStrata("TOOLTIP")      -- altijd bovenop
    suggestionBox:Hide()

    local function UpdateSuggestions()
        for _, child in ipairs(suggestionBox.children or {}) do child:Hide() end
        suggestionBox.children = {}

        local text = addBox:GetText():lower()
        if text == "" then suggestionBox:Hide() return end

        local suggestions = {}

        -- Groepsleden
        for i = 1, GetNumGroupMembers() do
            local unit = (IsInRaid() and "raid"..i) or "party"..i
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
                addBox:SetText(name)
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

    addBox:SetScript("OnTextChanged", UpdateSuggestions)
    addBox:SetScript("OnEditFocusLost", function() C_Timer.After(0.2, function() suggestionBox:Hide() end) end)

    -- Filter toxic groups checkbox
    local hideToxicCheck = CreateFrame("CheckButton", nil, f, "InterfaceOptionsCheckButtonTemplate")
    hideToxicCheck:SetPoint("TOPLEFT", addBox, "BOTTOMLEFT", 0, -15)
    hideToxicCheck.Text:SetText("Hide toxic groups in Premade Groups")
    hideToxicCheck:SetChecked(ToxicifyDB.HideInFinder or false)
    hideToxicCheck:SetScript("OnClick", function(self)
        ToxicifyDB.HideInFinder = self:GetChecked()
        if LFGListFrame and LFGListFrame.SearchPanel then
            LFGListSearchPanel_UpdateResultList(LFGListFrame.SearchPanel)
        end
    end)

    -- Search row
    local searchLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    searchLabel:SetPoint("TOPLEFT", hideToxicCheck, "BOTTOMLEFT", 0, -15)
    searchLabel:SetText("Search:")

    local searchBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    searchBox:SetSize(220, 22)
    searchBox:SetPoint("LEFT", searchLabel, "RIGHT", 10, 0)
    searchBox:SetAutoFocus(false)
    searchBox:SetScript("OnTextChanged", function(self) f:Refresh() end)

    -- List
    local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", searchLabel, "BOTTOMLEFT", 0, -10)
    scroll:SetPoint("BOTTOMRIGHT", -30, 50)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(460, 300)
    scroll:SetScrollChild(content)

    local function Refresh()
        ns.RefreshSharedList(content, searchBox:GetText():lower())
    end
    f.Refresh = Refresh

    -- Buttons logic
    addBtn:SetScript("OnClick", function()
        local name = addBox:GetText()
        if name and name ~= "" then
            local role = UIDropDownMenu_GetText(roleDrop)
            if role == "Toxic" then
                ns.MarkToxic(name)
            else
                ns.MarkPumper(name)
            end
            addBox:SetText("")
            suggestionBox:Hide()
            Refresh()
        end
    end)

    clearBtn:SetScript("OnClick", function()
        for k in pairs(ToxicifyDB) do
            if type(k) == "string" then ToxicifyDB[k] = nil end
        end
        Refresh()
    end)

    -- ReloadUI button rechtsonder
    local reloadBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    reloadBtn:SetSize(80, 22)
    reloadBtn:SetPoint("BOTTOMRIGHT", -20, 15)
    reloadBtn:SetText("ReloadUI")
    reloadBtn:SetScript("OnClick", function() ReloadUI() end)

    -- Footer
    local footer = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    footer:SetPoint("BOTTOMLEFT", 20, 20)
    footer:SetText("|cffaaaaaaCreated by Alvarín-Silvermoon - v2025|r")
end

---------------------------------------------------
-- /toxic command
---------------------------------------------------
SLASH_TOXICIFY1 = "/toxic"
SlashCmdList["TOXICIFY"] = function(msg)
    local cmd, arg1, arg2 = strsplit(" ", msg, 3)
    cmd = string.lower(cmd or "")

    if cmd == "add" and arg1 then
        ns.MarkToxic(arg1)
    elseif cmd == "addpumper" and arg1 then
        ns.MarkPumper(arg1)
    elseif cmd == "del" and arg1 then
        ns.UnmarkToxic(arg1)
    elseif cmd == "list" then
        print("|cff39FF14Toxicify:|r Current list:")
        for name, status in pairs(ToxicifyDB) do
            if status then
                print(" - " .. name .. " (" .. status .. ")")
            end
        end
    elseif cmd == "export" then
        ns.ShowIOPopup("export")
    elseif cmd == "import" then
        ns.ShowIOPopup("import")
    elseif cmd == "ui" then
        if not _G.ToxicifyListFrame then ns.CreateToxicifyUI() end
        if _G.ToxicifyListFrame:IsShown() then
            _G.ToxicifyListFrame:Hide()
        else
            _G.ToxicifyListFrame:Refresh()
            _G.ToxicifyListFrame:Show()
        end
    else
        print("|cff39FF14Toxicify Commands:|r")
        print("/toxic add <name-realm>        - Mark player as Toxic")
        print("/toxic addpumper <name-realm>  - Mark player as Pumper")
        print("/toxic del <name-realm>        - Remove player from list")
        print("/toxic list                    - Show current list")
        print("/toxic export                  - Export list (string)")
        print("/toxic import <string>         - Import list from string")
        print("/toxic ui                      - Toggle Toxicify list window")
    end
end

---------------------------------------------------
-- Import/Export Popup
---------------------------------------------------
function ns.ShowIOPopup(mode, data)
    if not _G.ToxicifyIOFrame then
        local f = CreateFrame("Frame", "ToxicifyIOFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
        f:SetSize(500, 300)
        f:SetPoint("CENTER")
        f:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 16,
            insets = { left = 8, right = 8, top = 8, bottom = 8 }
        })
        f:SetFrameStrata("DIALOG")
        f:Hide()

        -- Titel
        f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        f.title:SetPoint("TOP", 0, -15)

        -- EditBox + Scroll
        f.scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
        f.scroll:SetPoint("TOPLEFT", 20, -50)
        f.scroll:SetPoint("BOTTOMRIGHT", -40, 50)

        f.editBox = CreateFrame("EditBox", nil, f.scroll)
        f.editBox:SetMultiLine(true)
        f.editBox:SetFontObject("ChatFontNormal")
        f.editBox:SetWidth(420)
        f.editBox:SetAutoFocus(false)
        f.scroll:SetScrollChild(f.editBox)

        -- Buttons
        f.closeBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        f.closeBtn:SetSize(100, 22)
        f.closeBtn:SetPoint("BOTTOMRIGHT", -20, 15)
        f.closeBtn:SetText("Close")
        f.closeBtn:SetScript("OnClick", function() f:Hide() end)

        f.actionBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        f.actionBtn:SetSize(100, 22)
        f.actionBtn:SetPoint("RIGHT", f.closeBtn, "LEFT", -10, 0)

        _G.ToxicifyIOFrame = f
    end

    local f = _G.ToxicifyIOFrame
    f:Show()
    f.editBox:SetText("")
    f.editBox:HighlightText()

    if mode == "export" then
        f.title:SetText("|cff39FF14Toxicify|r - Export List")
        f.editBox:SetText(ns.ExportList())
        f.editBox:HighlightText()
        f.actionBtn:SetText("Copy")
        f.actionBtn:SetScript("OnClick", function()
            f.editBox:HighlightText()
            print("|cff39FF14Toxicify:|r Copy the string with CTRL+C.")
        end)
    elseif mode == "import" then
        f.title:SetText("|cff39FF14Toxicify|r - Import List")
        f.actionBtn:SetText("Import")
        f.actionBtn:SetScript("OnClick", function()
            local ok, result = ns.ImportList(f.editBox:GetText())
            if ok then
                print("|cff39FF14Toxicify:|r Import success: " .. result)
                if _G.ToxicifyListFrame and _G.ToxicifyListFrame.Refresh then
                    _G.ToxicifyListFrame:Refresh()
                end
            else
                print("|cffff0000Toxicify:|r Import failed: " .. result)
            end
        end)
    end
end

hooksecurefunc("LFGListSearchEntry_Update", function(entry)
    if not entry or not entry.resultID then return end
    local info = C_LFGList.GetSearchResultInfo(entry.resultID)
    if not info or not info.leaderName then return end

    local leader = info.leaderName

    -- Reset group name
    entry.Name:SetText(info.name)

    -- === LEADER HIGHLIGHT ===
    if ns.IsToxic(leader) then
        entry.Name:SetText("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:14:14|t |cffff0000"..info.name.."|r")
    elseif ns.IsPumper(leader) then
        entry.Name:SetText("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:14:14|t |cff00ff00"..info.name.."|r")
    end

    -- === CLASS ICON OVERLAY ===
    if entry.DataDisplay and entry.DataDisplay.Enumerate and entry.DataDisplay.Enumerate.MemberFrames then
        local leaderButton = entry.DataDisplay.Enumerate.MemberFrames[1]
        if leaderButton then
            -- Toxic overlay
            if not leaderButton.ToxicOverlay then
                leaderButton.ToxicOverlay = leaderButton:CreateTexture(nil, "OVERLAY")
                leaderButton.ToxicOverlay:SetSize(14, 14)
                leaderButton.ToxicOverlay:SetPoint("TOPRIGHT", leaderButton, "TOPRIGHT", -1, -1)
                leaderButton.ToxicOverlay:Hide()
            end
            -- Pumper overlay
            if not leaderButton.PumperOverlay then
                leaderButton.PumperOverlay = leaderButton:CreateTexture(nil, "OVERLAY")
                leaderButton.PumperOverlay:SetSize(14, 14)
                leaderButton.PumperOverlay:SetPoint("BOTTOMRIGHT", leaderButton, "BOTTOMRIGHT", -1, 1)
                leaderButton.PumperOverlay:Hide()
            end

            -- Reset
            leaderButton.ToxicOverlay:Hide()
            leaderButton.PumperOverlay:Hide()

            -- Apply
            if ns.IsToxic(leader) then
                leaderButton.ToxicOverlay:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_8")
                leaderButton.ToxicOverlay:Show()
            elseif ns.IsPumper(leader) then
                leaderButton.PumperOverlay:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_1")
                leaderButton.PumperOverlay:Show()
            end
        end
    end
end)
function ns.RefreshSharedList(content, filterText)
    for _, child in ipairs(content.children or {}) do child:Hide() end
    content.children = {}

    filterText = filterText and filterText:lower() or ""

    local y = -5
    for name, status in pairs(ToxicifyDB) do
        if (status == "toxic" or status == "pumper") 
           and (filterText == "" or name:lower():find(filterText, 1, true)) then

            local row = CreateFrame("Frame", nil, content)
            row:SetSize(520, 26)
            row:SetPoint("TOPLEFT", 0, y)

            -- Icon
            local icon = row:CreateTexture(nil, "ARTWORK")
            icon:SetSize(16, 16)
            icon:SetPoint("LEFT", 0, 0)

            -- Editable name field
            local nameBox = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
            nameBox:SetSize(180, 22)
            nameBox:SetPoint("LEFT", icon, "RIGHT", 6, 0)
            nameBox:SetAutoFocus(false)
            nameBox:SetText(name)

            -- Dropdown
            local drop = CreateFrame("Frame", nil, row, "UIDropDownMenuTemplate")
            drop:SetPoint("LEFT", nameBox, "RIGHT", -10, -3)
            UIDropDownMenu_SetWidth(drop, 100)

            local function UpdateVisual()
                if ToxicifyDB[name] == "toxic" then
                    icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_8")
                    nameBox:SetTextColor(1, 0, 0) -- rood
                else
                    icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_1")
                    nameBox:SetTextColor(0, 1, 0) -- groen
                end
            end

            UIDropDownMenu_Initialize(drop, function(self, level)
                local info = UIDropDownMenu_CreateInfo()

                info.text = "Toxic"
                info.func = function()
                    ToxicifyDB[name] = "toxic"
                    UpdateVisual()
                end
                UIDropDownMenu_AddButton(info)

                info.text = "Pumper"
                info.func = function()
                    ToxicifyDB[name] = "pumper"
                    UpdateVisual()
                end
                UIDropDownMenu_AddButton(info)
            end)

            UIDropDownMenu_SetText(drop, status == "toxic" and "Toxic" or "Pumper")
            UpdateVisual()

            -- Save button
            local save = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            save:SetSize(60, 22)
            save:SetPoint("LEFT", drop, "RIGHT", 10, 0)
            save:SetText("Save")
            save:SetScript("OnClick", function()
                local newName = ns.NormalizePlayerName(nameBox:GetText())
                if newName and newName ~= name then
                    local role = ToxicifyDB[name]
                    ToxicifyDB[name] = nil
                    ToxicifyDB[newName] = role
                end
                ns.RefreshSharedList(content, filterText)
            end)

            -- Delete button
            local del = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            del:SetSize(60, 22)
            del:SetPoint("LEFT", save, "RIGHT", 10, 0)
            del:SetText("Delete")
            del:SetScript("OnClick", function()
                ToxicifyDB[name] = nil
                ns.RefreshSharedList(content, filterText)
            end)

            table.insert(content.children, row)
            y = y - 28
        end
    end
end

-- Add Toxic
local addToxicBtn = CreateFrame("Button", nil, generalPanel, "UIPanelButtonTemplate")
addToxicBtn:SetSize(100, 22)
addToxicBtn:SetPoint("LEFT", input, "RIGHT", 5, 0)
addToxicBtn:SetText("Add Toxic")
addToxicBtn:SetScript("OnClick", function()
    local name = input:GetText()
    if name and name ~= "" then
        ns.MarkToxic(name)
        input:SetText("")
        RefreshList()
    end
end)

-- Add Pumper
local addPumperBtn = CreateFrame("Button", nil, generalPanel, "UIPanelButtonTemplate")
addPumperBtn:SetSize(100, 22)
addPumperBtn:SetPoint("LEFT", addToxicBtn, "RIGHT", 5, 0)
addPumperBtn:SetText("Add Pumper")
addPumperBtn:SetScript("OnClick", function()
    local name = input:GetText()
    if name and name ~= "" then
        ns.MarkPumper(name)
        input:SetText("")
        RefreshList()
    end
end)

---------------------------------------------------
-- Tooltip
---------------------------------------------------
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip, data)
    local unit = select(2, tooltip:GetUnit())
    if unit then
        local name = GetUnitName(unit, true)
        if ns.IsToxic(name) then
            tooltip:AddLine("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:16:16|t |cffff0000Toxic Player|r ")
        elseif ns.IsPumper(name) then
            tooltip:AddLine("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:16:16|t |cff00ff00Pumper|r ")
        end
    end
end)

---------------------------------------------------
-- Helper: Find Compact UnitFrame for a unit
---------------------------------------------------
function ns.GetUnitFrame(unit)
    if not C_CompactUnitFrame or not C_CompactUnitFrame.GetAllFrames then
        return nil
    end

    for _, frame in ipairs(C_CompactUnitFrame.GetAllFrames()) do
        if frame and frame.unit == unit then
            return frame
        end
    end

    return nil
end

---------------------------------------------------
-- Modern context menu
---------------------------------------------------
local function AddToxicifyContextMenu(_, rootDescription, contextData)
    if not contextData or not contextData.unit then return end
    local playerName = GetUnitName(contextData.unit, true)
    if not playerName then return end

    local toxicSubmenu = rootDescription:CreateButton("Toxicify")
    toxicSubmenu:CreateButton("Mark player as Toxic", function() ns.MarkToxic(playerName) end)
    toxicSubmenu:CreateButton("Mark player as Pumper", function() ns.MarkPumper(playerName) end)
    toxicSubmenu:CreateButton("Remove from List", function() ns.UnmarkToxic(playerName) end)
end

Menu.ModifyMenu("MENU_UNIT_PLAYER", AddToxicifyContextMenu)
Menu.ModifyMenu("MENU_UNIT_TARGET", AddToxicifyContextMenu)
Menu.ModifyMenu("MENU_UNIT_FRIEND", AddToxicifyContextMenu)
Menu.ModifyMenu("MENU_UNIT_ENEMY_PLAYER", AddToxicifyContextMenu)
-- Export List
function ns.ExportList()
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

-- Import List
function ns.ImportList(str)
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