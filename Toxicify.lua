local addonName, ns = ...
ToxicifyDB = ToxicifyDB or {}

-- Debug load
print("|cff39FF14Toxicify:|r Addon is loading...")

---------------------------------------------------
-- Minimap / LibDataBroker knop
---------------------------------------------------
local LDB = LibStub("LibDataBroker-1.1"):NewDataObject("Toxicify", {
    type = "launcher",
    text = "Toxicify",
    icon = "Interface\\Icons\\ability_creature_poison_05", -- giftig icoontje
    OnClick = function(self, button)
        if button == "LeftButton" then
            InterfaceOptionsFrame_OpenToCategory("Toxicify")
            InterfaceOptionsFrame_OpenToCategory("Toxicify") -- dubbel voor bugfix
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
-- Helpers
---------------------------------------------------
local function NormalizePlayerName(playerName)
    return string.lower(playerName)
end

local function IsToxic(playerName)
    if not playerName then return false end
    local normalizedName = NormalizePlayerName(playerName)
    if ToxicifyDB[normalizedName] then return true end
    for storedName, _ in pairs(ToxicifyDB) do
        if type(storedName) == "string" and storedName ~= "minimap" and storedName ~= "HideInFinder" then
            local normalizedStored = NormalizePlayerName(storedName)
            if normalizedStored == normalizedName then return true end
            local storedOnly = string.match(normalizedStored, "^([^-]+)")
            local currentOnly = string.match(normalizedName, "^([^-]+)")
            if storedOnly == currentOnly then return true end
        end
    end
    return false
end

local function MarkToxic(playerName)
    if not playerName or playerName == "" then return end
    ToxicifyDB[NormalizePlayerName(playerName)] = true
    print("|cffff0000Toxicify:|r " .. playerName .. " marked as toxic.")
end

local function UnmarkToxic(playerName)
    if not playerName or playerName == "" then return end
    local norm = NormalizePlayerName(playerName)
    if ToxicifyDB[norm] then
        ToxicifyDB[norm] = nil
        print("|cff00ff00Toxicify:|r " .. playerName .. " removed from toxic list.")
    end
end

---------------------------------------------------
-- Slash commands
---------------------------------------------------
SLASH_TOXICIFY1 = "/toxic"
SlashCmdList["TOXICIFY"] = function(msg)
    local cmd, player = strsplit(" ", msg, 2)
    if cmd == "add" and player then
        MarkToxic(player)
    elseif cmd == "del" and player then
        UnmarkToxic(player)
    elseif cmd == "ui" then
        if _G.ToxicifyListFrame then
            if _G.ToxicifyListFrame:IsShown() then
                _G.ToxicifyListFrame:Hide()
                print("|cff39FF14Toxicify:|r UI hidden")
            else
                _G.ToxicifyListFrame:Show()
                print("|cff39FF14Toxicify:|r UI shown")
            end
        else
            print("|cffff0000Toxicify:|r UI not yet available (only after Group Finder loaded)")
        end
    elseif cmd == "list" then
        print("|cff39FF14Toxicify:|r Toxic list:")
        for name in pairs(ToxicifyDB) do
            if name ~= "minimap" and name ~= "HideInFinder" then
                print(" - " .. name)
            end
        end
    end
end

---------------------------------------------------
-- Party frames
---------------------------------------------------
hooksecurefunc("CompactUnitFrame_UpdateName", function(frame)
    if frame and frame.unit then
        local name = GetUnitName(frame.unit, true)
        if name and IsToxic(name) then
            if frame.name and frame.name.SetText then
                frame.name:SetText("|cffff0000☠ " .. name .. "|r")
            end
        end
    end
end)

---------------------------------------------------
-- Premade Group Finder
---------------------------------------------------
hooksecurefunc("LFGListSearchEntry_Update", function(entry)
    if not entry.resultID then return end
    local info = C_LFGList.GetSearchResultInfo(entry.resultID)
    if info and info.leaderName then
        local leader = Ambiguate(info.leaderName, "short")
        if IsToxic(leader) then
            local text = entry.Name:GetText() or leader
            if text and not text:find("☠") then
                entry.Name:SetText("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:0|t " .. text)
            end
            if ToxicifyDB.HideInFinder then
                entry:SetHeight(1)
                entry:Hide()
            end
        end
    end
end)

---------------------------------------------------
-- Toxicify UI
---------------------------------------------------
local function CreateToxicifyUI()
    if _G.ToxicifyToggleButton then return end

    local toggleBtn = CreateFrame("Button", "ToxicifyToggleButton", LFGListFrame.SearchPanel, "UIPanelButtonTemplate")
    toggleBtn:SetSize(80, 22)
    toggleBtn:SetText("Toxicify")
    if _G.LFGListFrameSearchPanelFilterButton then
        toggleBtn:SetPoint("RIGHT", LFGListFrameSearchPanelFilterButton, "LEFT", -5, 0)
    else
        toggleBtn:SetPoint("LEFT", LFGListFrame.SearchPanel.RefreshButton, "RIGHT", -110, 0)
    end

    local toxicFrame = CreateFrame("Frame", "ToxicifyListFrame", LFGListFrame.SearchPanel, BackdropTemplateMixin and "BackdropTemplate")
    toxicFrame:SetSize(420, 380)
    toxicFrame:SetPoint("TOPLEFT", LFGListFrame.SearchPanel, "TOPRIGHT", 260, 0)
    toxicFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    toxicFrame:Hide()

    local title = toxicFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -10)
    title:SetText("|cff39FF14Toxicify List|r")

    local addBox = CreateFrame("EditBox", nil, toxicFrame, "InputBoxTemplate")
    addBox:SetSize(140, 20)
    addBox:SetPoint("TOPLEFT", 10, -35)
    addBox:SetAutoFocus(false)

    local addBtn = CreateFrame("Button", nil, toxicFrame, "UIPanelButtonTemplate")
    addBtn:SetSize(45, 20)
    addBtn:SetPoint("LEFT", addBox, "RIGHT", 5, 0)
    addBtn:SetText("Add")

    local clearBtn = CreateFrame("Button", nil, toxicFrame, "UIPanelButtonTemplate")
    clearBtn:SetSize(80, 20)
    clearBtn:SetPoint("LEFT", addBtn, "RIGHT", 5, 0)
    clearBtn:SetText("Remove All")

    local hideCheck = CreateFrame("CheckButton", nil, toxicFrame, "ChatConfigCheckButtonTemplate")
    hideCheck:SetPoint("TOPLEFT", addBox, "BOTTOMLEFT", 0, -10)
    hideCheck.Text:SetText("Hide toxic groups in Finder")
    hideCheck:SetChecked(ToxicifyDB.HideInFinder or false)
    hideCheck:SetScript("OnClick", function(self)
        ToxicifyDB.HideInFinder = self:GetChecked()
        print("|cff39FF14Toxicify:|r HideInFinder set to " .. tostring(ToxicifyDB.HideInFinder))
    end)

    local scroll = CreateFrame("ScrollFrame", nil, toxicFrame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 10, -150)
    scroll:SetPoint("BOTTOMRIGHT", -30, 10)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(220, 200)
    scroll:SetScrollChild(content)

    local function RefreshToxicFrame()
        for _, child in ipairs(content.children or {}) do child:Hide() end
        content.children = {}
        local y = -5
        for name in pairs(ToxicifyDB) do
            if name ~= "minimap" and name ~= "HideInFinder" then
                local row = CreateFrame("Frame", nil, content)
                row:SetSize(200, 20)
                row:SetPoint("TOPLEFT", 0, y)
                local text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                text:SetPoint("LEFT", 0, 0)
                text:SetText(name)
                local delBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                delBtn:SetSize(50, 18)
                delBtn:SetPoint("RIGHT", 0, 0)
                delBtn:SetText("Del")
                delBtn:SetScript("OnClick", function()
                    ToxicifyDB[name] = nil
                    RefreshToxicFrame()
                end)
                table.insert(content.children, row)
                y = y - 22
            end
        end
    end

    addBtn:SetScript("OnClick", function()
        local name = addBox:GetText()
        if name and name ~= "" then
            MarkToxic(name)
            addBox:SetText("")
            RefreshToxicFrame()
        end
    end)

    clearBtn:SetScript("OnClick", function()
        ToxicifyDB = { minimap = ToxicifyDB.minimap, HideInFinder = ToxicifyDB.HideInFinder }
        RefreshToxicFrame()
        print("|cff39FF14Toxicify:|r Cleared toxic list")
    end)

    toggleBtn:SetScript("OnClick", function()
        if toxicFrame:IsShown() then
            toxicFrame:Hide()
        else
            RefreshToxicFrame()
            hideCheck:SetChecked(ToxicifyDB.HideInFinder or false)
            toxicFrame:Show()
        end
    end)

    print("|cff39FF14Toxicify:|r UI loaded")
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", function()
    if LFGListFrame and LFGListFrame.SearchPanel then
        CreateToxicifyUI()
    end
end)

---------------------------------------------------
-- Group roster updates (covers M+ too)
---------------------------------------------------
local function UpdateGroupMembers()
    if not IsInGroup() then return end

    for i = 1, GetNumGroupMembers() do
        local unit = (IsInRaid() and "raid"..i) or (i == GetNumGroupMembers() and "player" or "party"..i)
        if UnitExists(unit) then
            local name = GetUnitName(unit, true)
            if name and IsToxic(name) then
                -- add skull icon to nameplate/party/raid frame
                local frame = CompactUnitFrame_GetUnitFrame(unit)
                if frame and frame.name and frame.name.SetText then
                    frame.name:SetText("|cffff0000☠ " .. name .. "|r")
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
-- Tooltip
---------------------------------------------------
---------------------------------------------------
-- Voeg "Toxic Player" toe aan tooltips (Dragonflight API)
---------------------------------------------------
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip, data)
    local unit = select(2, tooltip:GetUnit())
    if unit then
        local name = GetUnitName(unit, true)
        if name and IsToxic(name) then
            -- Raid Target Skull icon (size 16x16) + text
            tooltip:AddLine("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:16:16|t |cffff0000Toxic Player|r")
        end
    end
end)

---------------------------------------------------
-- Modern context menu integratie (Dragonflight+)
---------------------------------------------------
local function AddToxicifyContextMenu(_, rootDescription, contextData)
    if not contextData or not contextData.unit then return end

    local unit = contextData.unit
    if not UnitIsPlayer(unit) or UnitIsUnit(unit, "player") then return end

    local playerName = GetUnitName(unit, true)
    if not playerName then return end

    -- Submenu aanmaken
    local toxicSubmenu = rootDescription:CreateButton("Toxicify")

    -- Voeg optie toe: markeren
    toxicSubmenu:CreateButton(IsToxic(playerName) and "|cffaaaaaaMark player as Toxic|r"
        or "Mark player as Toxic", function()
        MarkToxic(playerName)
    end)

    -- Voeg optie toe: unmark
    toxicSubmenu:CreateButton(IsToxic(playerName) and "Remove from Toxic List"
        or "|cffaaaaaaRemove from Toxic List|r", function()
        UnmarkToxic(playerName)
    end)
end

-- Register de extensie in alle unit menus
Menu.ModifyMenu("MENU_UNIT_PLAYER", AddToxicifyContextMenu)
Menu.ModifyMenu("MENU_UNIT_TARGET", AddToxicifyContextMenu)
Menu.ModifyMenu("MENU_UNIT_FRIEND", AddToxicifyContextMenu)
Menu.ModifyMenu("MENU_UNIT_ENEMY_PLAYER", AddToxicifyContextMenu)

print("|cff39FF14Toxicify:|r Modern context menu integrated (Dragonflight+ API)")
