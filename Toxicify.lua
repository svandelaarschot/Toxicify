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
                local frame = CompactUnitFrame_GetUnitFrame(unit)
                if frame and frame.name and frame.name.SetText then
                    frame.name:SetText("|cffff0000 Toxic: " .. name .. "|r")
                end
            end
            if name and ns.IsPumper(name) then
                local frame = CompactUnitFrame_GetUnitFrame(unit)
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
                local frame = CompactUnitFrame_GetUnitFrame(unit)
                if frame and frame.name and frame.name.SetText then
                    frame.name:SetText("|cffff0000 Toxic: " .. name .. "|r")
                end
            end
            if name and ns.IsPumper(name) then
                local frame = CompactUnitFrame_GetUnitFrame(unit)
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
    if not playerName then return nil end
    return string.lower(playerName)
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
            AddIgnore(playerName)
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
        DelIgnore(playerName)
        print("|cffaaaaaaToxicify:|r " .. playerName .. " has also been removed from your Ignore list.")
    end
end

---------------------------------------------------
-- Toxicify UI
---------------------------------------------------
function ns.CreateToxicifyUI()
    if _G.ToxicifyListFrame then return end

    local f = CreateFrame("Frame", "ToxicifyListFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
    f:SetSize(460, 420)
    f:SetPoint("CENTER")
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 16,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    f:Hide()

    -- movable
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetClampedToScreen(true)
    f:SetFrameStrata("DIALOG")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)

    -- title
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -15)
    title:SetText("|cff39FF14Toxicify List|r")

    -- close
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    -- add box
    local addBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    addBox:SetSize(200, 22)
    addBox:SetPoint("TOPLEFT", 20, -45)
    addBox:SetAutoFocus(false)

    local addBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    addBtn:SetSize(60, 22)
    addBtn:SetPoint("LEFT", addBox, "RIGHT", 10, 0)
    addBtn:SetText("Add")

    -- clear
    local clearBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    clearBtn:SetSize(100, 22)
    clearBtn:SetPoint("LEFT", addBtn, "RIGHT", 10, 0)
    clearBtn:SetText("Remove All")

    -- list
    local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 20, -120)
    scroll:SetPoint("BOTTOMRIGHT", -40, 40)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(360, 200)
    scroll:SetScrollChild(content)

    local function Refresh()
        ns.RefreshSharedList(content)
    end

    f.Refresh = Refresh

    addBtn:SetScript("OnClick", function()
        local name = addBox:GetText()
        if name and name ~= "" then
            ns.MarkToxic(name)
            addBox:SetText("")
            Refresh()
        end
    end)

    clearBtn:SetScript("OnClick", function()
        for k in pairs(ToxicifyDB) do
            if type(k) == "string" then ToxicifyDB[k] = nil end
        end
        Refresh()
    end)

    local footer = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    footer:SetPoint("BOTTOM", 0, 12)
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

---------------------------------------------------
-- Premade Groups hook (toxic vs pumper)
---------------------------------------------------
hooksecurefunc("LFGListSearchEntry_Update", function(entry)
    if not entry or not entry.resultID then return end
    local info = C_LFGList.GetSearchResultInfo(entry.resultID)
    if not info or not info.leaderName then return end

    local leader = info.leaderName

    if ns.IsToxic(leader) then
        -- Toxic speler => schedel + rood
        entry.Name:SetText("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:16:16|t " .. info.name)
        entry.Name:SetTextColor(1, 0, 0) -- rood
        entry.Name:SetFontObject("GameFontNormalLarge")
        entry.Name:SetFormattedText("|cffff0000%s|r", entry.Name:GetText())
        entry:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine("Leader: " .. leader)
            GameTooltip:AddLine("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:16:16|t |cffff0000Toxic Player|r")
            GameTooltip:Show()
        end)
        entry:SetScript("OnLeave", function() GameTooltip:Hide() end)

    elseif ns.IsPumper(leader) then
        -- Pumper speler => ster + groen
        entry.Name:SetText("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:16:16|t " .. info.name)
        entry.Name:SetTextColor(0, 1, 0) -- groen
        entry.Name:SetFontObject("GameFontNormalLarge")
        entry.Name:SetFormattedText("|cff00ff00%s|r", entry.Name:GetText())
        entry:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine("Leader: " .. leader)
            GameTooltip:AddLine("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:16:16|t |cff00ff00Pumper|r")
            GameTooltip:Show()
        end)
        entry:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
end)

function ns.RefreshSharedList(content)
    for _, child in ipairs(content.children or {}) do child:Hide() end
    content.children = {}

    local y = -5
    for name, status in pairs(ToxicifyDB) do
        if status == "toxic" or status == "pumper" then
            local row = CreateFrame("Frame", nil, content)
            row:SetSize(320, 22)
            row:SetPoint("TOPLEFT", 0, y)

            local icon = row:CreateTexture(nil, "ARTWORK")
            icon:SetSize(16, 16)
            icon:SetPoint("LEFT", 0, 0)
            if status == "toxic" then
                icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_8") -- skull
            else
                icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_1") -- star
            end

            local text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            text:SetPoint("LEFT", icon, "RIGHT", 6, 0)
            if status == "toxic" then
                text:SetText("|cffff0000" .. name .. " [Toxic]|r")
            else
                text:SetText("|cff00ff00" .. name .. " [Pumper]|r")
            end

            local del = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            del:SetSize(60, 20)
            del:SetPoint("RIGHT", 0, 0)
            del:SetText("Delete")
            del:SetScript("OnClick", function()
                ToxicifyDB[name] = nil
                ns.RefreshSharedList(content)
            end)

            table.insert(content.children, row)
            y = y - 26
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

---------------------------------------------------
-- Export List
---------------------------------------------------
function ns.ExportList()
    local data = {}
    for name, status in pairs(ToxicifyDB) do
        if status == "toxic" or status == "pumper" then
            table.insert(data, name .. ":" .. status)
        end
    end
    local payload = table.concat(data, ";")

    -- simple checksum (sum of byte values)
    local checksum = 0
    for i = 1, #payload do
        checksum = checksum + string.byte(payload, i)
    end

    return "TOXICIFYv1|" .. payload .. "|" .. checksum
end

---------------------------------------------------
-- Import List
---------------------------------------------------
function ns.ImportList(str)
    if not str or str == "" then return false, "No data" end

    local version, payload, checksum = str:match("^(TOXICIFYv1)|(.+)|(%d+)$")
    if not version then return false, "Invalid format" end

    -- validate checksum
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
