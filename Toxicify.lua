local addonName, ns = ...
ToxicifyDB = ToxicifyDB or {}

-- Debug load
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
-- Toxicify UI
---------------------------------------------------
---------------------------------------------------
-- Toxicify UI
---------------------------------------------------
local function CreateToxicifyUI()
    if _G.ToxicifyListFrame then return end -- already created

    local toxicFrame = CreateFrame("Frame", "ToxicifyListFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
    toxicFrame:SetSize(460, 420)
    toxicFrame:SetPoint("CENTER")
    toxicFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 16,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    toxicFrame:Hide()

    -- Title
    local title = toxicFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -15)
    title:SetText("|cff39FF14Toxicify List|r")

    -- Close button
    local closeBtn = CreateFrame("Button", nil, toxicFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", toxicFrame, "TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function() toxicFrame:Hide() end)

    -- Add/Edit section
    local addBox = CreateFrame("EditBox", nil, toxicFrame, "InputBoxTemplate")
    addBox:SetSize(200, 22)
    addBox:SetPoint("TOPLEFT", 20, -45)
    addBox:SetAutoFocus(false)

    local addBtn = CreateFrame("Button", nil, toxicFrame, "UIPanelButtonTemplate")
    addBtn:SetSize(60, 22)
    addBtn:SetPoint("LEFT", addBox, "RIGHT", 10, 0)
    addBtn:SetText("Add")

    local clearBtn = CreateFrame("Button", nil, toxicFrame, "UIPanelButtonTemplate")
    clearBtn:SetSize(100, 22)
    clearBtn:SetPoint("LEFT", addBtn, "RIGHT", 10, 0)
    clearBtn:SetText("Remove All")

    local hideCheck = CreateFrame("CheckButton", nil, toxicFrame, "ChatConfigCheckButtonTemplate")
    hideCheck:SetPoint("TOPLEFT", addBox, "BOTTOMLEFT", 0, -15)
    hideCheck.Text:SetText("Hide toxic groups in Finder")
    hideCheck:SetChecked(ToxicifyDB.HideInFinder or false)
    hideCheck:SetScript("OnClick", function(self)
        ToxicifyDB.HideInFinder = self:GetChecked()
    end)

    -- ScrollFrame for list
    local scroll = CreateFrame("ScrollFrame", nil, toxicFrame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 20, -120)
    scroll:SetPoint("BOTTOMRIGHT", -40, 40)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(360, 200)
    scroll:SetScrollChild(content)

    local function RefreshToxicFrame()
        for _, child in ipairs(content.children or {}) do child:Hide() end
        content.children = {}

        local y = -5
        for name in pairs(ToxicifyDB) do
            if name ~= "minimap" and name ~= "HideInFinder" then
                local row = CreateFrame("Frame", nil, content)
                row:SetSize(320, 22)
                row:SetPoint("TOPLEFT", 0, y)

                local text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                text:SetPoint("LEFT", 5, 0)
                text:SetText(name)

                local delBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                delBtn:SetSize(60, 20)
                delBtn:SetPoint("RIGHT", 0, 0)
                delBtn:SetText("Delete")
                delBtn:SetScript("OnClick", function()
                    ToxicifyDB[name] = nil
                    RefreshToxicFrame()
                end)

                table.insert(content.children, row)
                y = y - 26
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

    -- Footer signature
    local footer = toxicFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    footer:SetPoint("BOTTOM", 0, 12)
    footer:SetText("|cffaaaaaaCreated by Alvarín-Silvermoon - v2025|r")

    toxicFrame.Refresh = RefreshToxicFrame
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
        if not _G.ToxicifyListFrame then
            CreateToxicifyUI()
        end
        if _G.ToxicifyListFrame:IsShown() then
            _G.ToxicifyListFrame:Hide()
        else
            _G.ToxicifyListFrame:Refresh()
            _G.ToxicifyListFrame:Show()
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
-- Group roster updates (covers party/raid/M+)
---------------------------------------------------
local function UpdateGroupMembers()
    if not IsInGroup() then return end
    for i = 1, GetNumGroupMembers() do
        local unit = (IsInRaid() and "raid"..i) or (i == GetNumGroupMembers() and "player" or "party"..i)
        if UnitExists(unit) then
            local name = GetUnitName(unit, true)
            if name and IsToxic(name) then
                local frame = CompactUnitFrame_GetUnitFrame(unit)
                if frame and frame.name and frame.name.SetText then
                    frame.name:SetText("|cffff0000 " .. name .. "|r")
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
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip, data)
    local unit = select(2, tooltip:GetUnit())
    if unit then
        local name = GetUnitName(unit, true)
        if name and IsToxic(name) then
            tooltip:AddLine("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:16:16|t |cffff0000Toxic Player|r")
        end
    end
end)

---------------------------------------------------
-- Modern context menu integration (Dragonflight+)
---------------------------------------------------
local function AddToxicifyContextMenu(_, rootDescription, contextData)
    if not contextData or not contextData.unit then return end
    local unit = contextData.unit
    if not UnitIsPlayer(unit) or UnitIsUnit(unit, "player") then return end

    local playerName = GetUnitName(unit, true)
    if not playerName then return end

    local toxicSubmenu = rootDescription:CreateButton("Toxicify")
    toxicSubmenu:CreateButton(IsToxic(playerName) and "|cffaaaaaaMark player as Toxic|r" or "Mark player as Toxic", function()
        MarkToxic(playerName)
    end)
    toxicSubmenu:CreateButton(IsToxic(playerName) and "Remove from Toxic List" or "|cffaaaaaaRemove from Toxic List|r", function()
        UnmarkToxic(playerName)
    end)
end

Menu.ModifyMenu("MENU_UNIT_PLAYER", AddToxicifyContextMenu)
Menu.ModifyMenu("MENU_UNIT_TARGET", AddToxicifyContextMenu)
Menu.ModifyMenu("MENU_UNIT_FRIEND", AddToxicifyContextMenu)
Menu.ModifyMenu("MENU_UNIT_ENEMY_PLAYER", AddToxicifyContextMenu)

print("|cff39FF14Toxicify:|r Modern context menu integrated (Dragonflight+ API)")
