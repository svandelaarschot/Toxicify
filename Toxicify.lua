local addonName, ns = ...
ToxicifyDB = ToxicifyDB or {}

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
local function IsToxic(playerName)
    return ToxicifyDB[playerName] == true
end

local function MarkToxic(playerName)
    ToxicifyDB[playerName] = true
    print("|cffff0000Toxicify:|r " .. playerName .. " marked as toxic.")
end

local function UnmarkToxic(playerName)
    ToxicifyDB[playerName] = nil
    print("|cff00ff00Toxicify:|r " .. playerName .. " removed from toxic list.")
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
    elseif cmd == "list" then
        print("Toxic list:")
        for name in pairs(ToxicifyDB) do
            print(" - " .. name)
        end
    else
        print("|cffffd700Toxicify commands:|r")
        print("/toxic add <playername-realm> - mark player as toxic")
        print("/toxic del <playername-realm> - remove player")
        print("/toxic list - show list")
    end
end

---------------------------------------------------
-- Party/Group UI hook
---------------------------------------------------
hooksecurefunc("CompactUnitFrame_UpdateName", function(frame)
    if frame and frame.unit then
        local name = GetUnitName(frame.unit, true)
        if name and IsToxic(name) then
            frame.name:SetText("|cffff0000☠ " .. name .. "|r")
        end
    end
end)

---------------------------------------------------
-- Premade Group Finder hook
---------------------------------------------------
hooksecurefunc("LFGListSearchEntry_Update", function(entry)
    if not entry.resultID then return end
    local searchResultInfo = C_LFGList.GetSearchResultInfo(entry.resultID)
    if searchResultInfo and searchResultInfo.leaderName then
        local leader = Ambiguate(searchResultInfo.leaderName, "short")
        if ToxicifyDB[leader] then
            local text = entry.Name:GetText() or leader
            if text and not text:find("ToxicIcon") then
                local skull = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:0|t"
                entry.Name:SetText(skull .. " " .. text)
            end
            if ToxicifyDB.HideInFinder then
                entry:SetHeight(1)
                entry:Hide()
            end
        end
    end
end)

---------------------------------------------------
-- Group Finder knop + Toxicify lijst
---------------------------------------------------
local function CreateToxicifyUI()
    if _G.ToxicifyToggleButton then return end -- al gemaakt

    -- Knop naast filter
    local toggleBtn = CreateFrame("Button", "ToxicifyToggleButton", LFGListFrame.SearchPanel, "UIPanelButtonTemplate")
    toggleBtn:SetSize(80, 22)
    toggleBtn:SetText("Toxicify")

    if _G.LFGListFrameSearchPanelFilterButton then
        toggleBtn:SetPoint("RIGHT", LFGListFrameSearchPanelFilterButton, "LEFT", -5, 0)
    else
        toggleBtn:SetPoint("LEFT", LFGListFrame.SearchPanel.RefreshButton, "RIGHT", -110, 0)
    end

    -- Toxic lijstframe (rechts van panel)
    local toxicFrame = CreateFrame("Frame", "ToxicifyListFrame", LFGListFrame.SearchPanel, BackdropTemplateMixin and "BackdropTemplate")
    toxicFrame:SetSize(420, 300)
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

    ---------------------------------------------------
    -- Add + Remove All knoppen
    ---------------------------------------------------
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

    ---------------------------------------------------
    -- Scrollframe
    ---------------------------------------------------
    local scroll = CreateFrame("ScrollFrame", nil, toxicFrame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 10, -70)
    scroll:SetPoint("BOTTOMRIGHT", -30, 10)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(220, 200)
    scroll:SetScrollChild(content)

    ---------------------------------------------------
    -- Functies
    ---------------------------------------------------
    local function RefreshToxicFrame()
        for _, child in ipairs(content.children or {}) do
            child:Hide()
        end
        content.children = {}

        local y = -5
        for name in pairs(ToxicifyDB) do
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

    addBtn:SetScript("OnClick", function()
        local name = addBox:GetText()
        if name and name ~= "" then
            ToxicifyDB[name] = true
            addBox:SetText("")
            RefreshToxicFrame()
            print("|cff39FF14Toxicify:|r Added " .. name)
        end
    end)

    clearBtn:SetScript("OnClick", function()
        ToxicifyDB = {}
        RefreshToxicFrame()
        print("|cff39FF14Toxicify:|r Cleared toxic list")
    end)

    ---------------------------------------------------
    -- Toggle gedrag
    ---------------------------------------------------
    toggleBtn:SetScript("OnClick", function()
        if toxicFrame:IsShown() then
            toxicFrame:Hide()
        else
            RefreshToxicFrame()
            toxicFrame:Show()
        end
    end)

    print("Toxicify: Toxicify UI loaded")
end

-- Zorg dat UI er komt zodra speler in de wereld is
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", function()
    if LFGListFrame and LFGListFrame.SearchPanel then
        CreateToxicifyUI()
    end
end)

---------------------------------------------------
-- Extra hooks (apart gehouden van de UI code)
---------------------------------------------------

-- Zorgt dat party/raid frames toxic icon krijgen
hooksecurefunc("CompactUnitFrame_UpdateName", function(frame)
    if not frame or not frame.unit then return end
    local name = GetUnitName(frame.unit, true)
    if name and IsToxic(name) then
        if frame.Name and frame.Name.SetText then
            frame.Name:SetText("|cffff0000☠ " .. name .. "|r")
        elseif frame.name and frame.name.SetText then
            frame.name:SetText("|cffff0000☠ " .. name .. "|r")
        end
    end
end)

-- Voeg "☠ Toxic Player" toe aan tooltips
GameTooltip:HookScript("OnTooltipSetUnit", function(tooltip)
    local _, unit = tooltip:GetUnit()
    if unit then
        local name = GetUnitName(unit, true)
        if name and IsToxic(name) then
            tooltip:AddLine("|cffff0000☠ Toxic Player|r")
            tooltip:Show()
        end
    end
end)
