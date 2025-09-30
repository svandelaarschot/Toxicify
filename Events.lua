-- Events.lua - Event handling and group roster updates
local addonName, ns = ...

-- Events namespace
ns.Events = {}

-- Update group members (party/raid/M+)
function ns.Events.UpdateGroupMembers()
    ns.Core.DebugPrint("UpdateGroupMembers called")
    
    local toxicPlayers = {}
    local pumperPlayers = {}
    
    -- Check yourself first
    local playerName = GetUnitName("player", true)
    ns.Core.DebugPrint("Player name: " .. tostring(playerName))
    if playerName and ns.Player.IsToxic(playerName) then
        ns.Core.DebugPrint("Player is toxic!")
        table.insert(toxicPlayers, playerName)
    end
    if playerName and ns.Player.IsPumper(playerName) then
        ns.Core.DebugPrint("Player is pumper!")
        table.insert(pumperPlayers, playerName)
    end
    
    -- Check group members if in group
    if IsInGroup() then
        for i = 1, GetNumGroupMembers() do
            local unit = (IsInRaid() and "raid"..i) or (i == GetNumGroupMembers() and "player" or "party"..i)
            if UnitExists(unit) then
                local name = GetUnitName(unit, true)
                if name and ns.Player.IsToxic(name) then
                    table.insert(toxicPlayers, name)
                    local frame = ns.UI.GetUnitFrame(unit)
                    if frame and frame.name and frame.name.SetText then
                        frame.name:SetText("|cffff0000 Toxic: " .. name .. "|r")
                    end
                end
                if name and ns.Player.IsPumper(name) then
                    table.insert(pumperPlayers, name)
                    local frame = ns.UI.GetUnitFrame(unit)
                    if frame and frame.name and frame.name.SetText then
                        frame.name:SetText("|cff00ff00 Pumper: " .. name .. "|r")
                    end
                end
            end
        end
    end
    
    -- Only set default if not already configured by user
    if ToxicifyDB.PartyWarningEnabled == nil then
        ns.Core.DebugPrint("Setting default PartyWarningEnabled to true (was nil)")
        ToxicifyDB.PartyWarningEnabled = true
    end
    
    -- Show warning if toxic/pumper players found and warning is enabled
    ns.Core.DebugPrint("PartyWarningEnabled: " .. tostring(ToxicifyDB.PartyWarningEnabled))
    ns.Core.DebugPrint("ToxicifyDB table dump:")
    for k, v in pairs(ToxicifyDB) do
        if type(v) == "boolean" then
            ns.Core.DebugPrint("  " .. tostring(k) .. " = " .. tostring(v))
        end
    end
    ns.Core.DebugPrint("Toxic players count: " .. #toxicPlayers)
    ns.Core.DebugPrint("Pumper players count: " .. #pumperPlayers)
    
    if ToxicifyDB.PartyWarningEnabled and (#toxicPlayers > 0 or #pumperPlayers > 0) then
        -- Show popup warning (only once per session)
        if not _G.ToxicifyWarningShown then
            ns.Events.ShowToxicWarningPopup(toxicPlayers, pumperPlayers)
            _G.ToxicifyWarningShown = true
        end
    else
        ns.Core.DebugPrint("No warning shown - conditions not met")
    end
end

-- Show toxic warning popup
function ns.Events.ShowToxicWarningPopup(toxicPlayers, pumperPlayers)
    if _G.ToxicifyWarningFrame then
        _G.ToxicifyWarningFrame:Hide()
    end
    
    local frame = CreateFrame("Frame", "ToxicifyWarningFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
    frame:SetSize(400, 300)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(1000)
    
    -- Backdrop
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 16,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    frame:SetBackdropColor(0, 0, 0, 0.8)
    
    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -20)
    title:SetText("|cffff0000⚠ TOXIC PLAYERS DETECTED ⚠|r")
    
    -- Content
    local content = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    content:SetPoint("TOP", title, "BOTTOM", 0, -20)
    content:SetWidth(350)
    content:SetJustifyH("CENTER")
    content:SetJustifyV("TOP")
    
    local warningText = "|cffff0000WARNING:|r Toxic or pumper players detected in your group!\n\n"
    
    if #toxicPlayers > 0 then
        warningText = warningText .. "|cffff0000Toxic Players:|r\n" .. table.concat(toxicPlayers, ", ") .. "\n\n"
    end
    
    if #pumperPlayers > 0 then
        warningText = warningText .. "|cff00ff00Pumper Players:|r\n" .. table.concat(pumperPlayers, ", ") .. "\n\n"
    end
    
    warningText = warningText .. "|cffaaaaaaBe cautious when playing with these players.|r"
    
    content:SetText(warningText)
    
    -- Close button
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    closeBtn:SetSize(100, 30)
    closeBtn:SetPoint("BOTTOM", 0, 20)
    closeBtn:SetText("Close")
    closeBtn:SetScript("OnClick", function()
        frame:Hide()
    end)
    
    -- Show the frame
    frame:Show()
    
    -- Auto-hide after 30 seconds
    C_Timer.After(30, function()
        if frame and frame:IsVisible() then
            frame:Hide()
        end
    end)
end

-- Initialize event handlers
function ns.Events.Initialize()
    -- Group roster updates
    local rosterFrame = CreateFrame("Frame")
    rosterFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    rosterFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    rosterFrame:SetScript("OnEvent", ns.Events.UpdateGroupMembers)
    
    -- Tooltip integration
    if TooltipDataProcessor then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip, data)
            local unit = select(2, tooltip:GetUnit())
            if unit then
                local name = GetUnitName(unit, true)
                if ns.Player.IsToxic(name) then
                    tooltip:AddLine("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:16:16|t |cffff0000Toxic Player|r ")
                elseif ns.Player.IsPumper(name) then
                    tooltip:AddLine("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:16:16|t |cff00ff00Pumper|r ")
                end
            end
        end)
    end
    
    -- Context menu integration
    -- Add Toxicify options to all unit types (Mark as Toxic, Mark as Pumper, Remove from List - submenu)
    -- Self, Player, Target, Friend, Enemy Player, Party, Raid
    -- Party members (specific slots)
    -- Raid members (specific slots)
    if Menu then
        local function AddToxicifyContextMenu(_, rootDescription, contextData)
            if not contextData or not contextData.unit then return end
            
            -- Only show for real players, not NPCs
            if not UnitIsPlayer(contextData.unit) then return end
            
            local playerName = GetUnitName(contextData.unit, true)
            if not playerName then return end

            local toxicSubmenu = rootDescription:CreateButton("Toxicify")
            toxicSubmenu:CreateButton("Mark player as Toxic", function() ns.Player.MarkToxic(playerName) end)
            toxicSubmenu:CreateButton("Mark player as Pumper", function() ns.Player.MarkPumper(playerName) end)
            toxicSubmenu:CreateButton("Remove from List", function() ns.Player.UnmarkToxic(playerName) end)
        end

        -- Core unit types
        Menu.ModifyMenu("MENU_UNIT_SELF", AddToxicifyContextMenu)
        Menu.ModifyMenu("MENU_UNIT_PLAYER", AddToxicifyContextMenu)
        Menu.ModifyMenu("MENU_UNIT_TARGET", AddToxicifyContextMenu)
        Menu.ModifyMenu("MENU_UNIT_FRIEND", AddToxicifyContextMenu)
        Menu.ModifyMenu("MENU_UNIT_ENEMY_PLAYER", AddToxicifyContextMenu)
        
        -- Party members (specific slots)
        for i = 1, 4 do
            Menu.ModifyMenu("MENU_UNIT_PARTY" .. i, AddToxicifyContextMenu)
        end
        
        -- Raid members (specific slots)
        for i = 1, 40 do
            Menu.ModifyMenu("MENU_UNIT_RAID" .. i, AddToxicifyContextMenu)
        end
    end
end
