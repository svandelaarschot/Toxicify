-- Events.lua - Event handling and group roster updates
local addonName, ns = ...

-- Events namespace
ns.Events = {}

-- Update group members (party/raid/M+)
local function UpdateGroupMembers()
    if not IsInGroup() then return end
    
    for i = 1, GetNumGroupMembers() do
        local unit = (IsInRaid() and "raid"..i) or (i == GetNumGroupMembers() and "player" or "party"..i)
        if UnitExists(unit) then
            local name = GetUnitName(unit, true)
            if name and ns.Player.IsToxic(name) then
                local frame = ns.UI.GetUnitFrame(unit)
                if frame and frame.name and frame.name.SetText then
                    frame.name:SetText("|cffff0000 Toxic: " .. name .. "|r")
                end
            end
            if name and ns.Player.IsPumper(name) then
                local frame = ns.UI.GetUnitFrame(unit)
                if frame and frame.name and frame.name.SetText then
                    frame.name:SetText("|cff00ff00 Pumper: " .. name .. "|r")
                end
            end
        end
    end
end

-- Initialize event handlers
function ns.Events.Initialize()
    -- Group roster updates
    local rosterFrame = CreateFrame("Frame")
    rosterFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    rosterFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    rosterFrame:SetScript("OnEvent", UpdateGroupMembers)
    
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
    if Menu then
        local function AddToxicifyContextMenu(_, rootDescription, contextData)
            if not contextData or not contextData.unit then return end
            local playerName = GetUnitName(contextData.unit, true)
            if not playerName then return end

            local toxicSubmenu = rootDescription:CreateButton("Toxicify")
            toxicSubmenu:CreateButton("Mark player as Toxic", function() ns.Player.MarkToxic(playerName) end)
            toxicSubmenu:CreateButton("Mark player as Pumper", function() ns.Player.MarkPumper(playerName) end)
            toxicSubmenu:CreateButton("Remove from List", function() ns.Player.UnmarkToxic(playerName) end)
        end

        Menu.ModifyMenu("MENU_UNIT_PLAYER", AddToxicifyContextMenu)
        Menu.ModifyMenu("MENU_UNIT_TARGET", AddToxicifyContextMenu)
        Menu.ModifyMenu("MENU_UNIT_FRIEND", AddToxicifyContextMenu)
        Menu.ModifyMenu("MENU_UNIT_ENEMY_PLAYER", AddToxicifyContextMenu)
    end
end
