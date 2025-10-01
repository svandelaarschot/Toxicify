-- Events.lua - Event handling and group roster updates
local addonName, ns = ...

-- Events namespace
ns.Events = {}

-- Update group members (party/raid/M+)
function ns.Events.UpdateGroupMembers(event)
    ns.Core.DebugPrint("UpdateGroupMembers called with event: " .. tostring(event))
    
    -- Only show warning for actual group roster updates, not for PLAYER_ENTERING_WORLD
    if event == "PLAYER_ENTERING_WORLD" then
        ns.Core.DebugPrint("Skipping warning check for PLAYER_ENTERING_WORLD event")
        return
    end
    
    -- Only show warning if we're actually in a group
    if not IsInGroup() then
        ns.Core.DebugPrint("Not in a group, skipping warning check")
        return
    end
    
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
    
    if ToxicifyDB.PartyWarningEnabled and #toxicPlayers > 0 then
        -- Show popup warning (only once per session)
        if not _G.ToxicifyWarningShown then
            -- Delay the popup to wait for loading screen to finish
            C_Timer.After(ns.Constants.WARNING_POPUP_DELAY, function()
                ns.Events.ShowToxicWarningPopup(toxicPlayers)
            end)
            _G.ToxicifyWarningShown = true
        end
    else
        ns.Core.DebugPrint("No warning shown - conditions not met")
    end
end

-- Show toxic warning popup
function ns.Events.ShowToxicWarningPopup(toxicPlayers)
    if _G.ToxicifyWarningFrame then
        _G.ToxicifyWarningFrame:Hide()
    end
    
    local frame = CreateFrame("Frame", "ToxicifyWarningFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
    frame:SetSize(400, 250)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(1000)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    
    -- Backdrop
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 16,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    frame:SetBackdropColor(0, 0, 0, 0.8)
    
    -- Make frame movable
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        frame:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(self)
        frame:StopMovingOrSizing()
    end)
    
    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -20)
    title:SetText("|cffff0000TOXIC PLAYERS DETECTED|r")
    
    -- Close button
    local closeBtn = CreateFrame("Button", nil, frame)
    closeBtn:SetSize(20, 20)
    closeBtn:SetPoint("TOPRIGHT", -10, -10)
    closeBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    closeBtn:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
    closeBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    closeBtn:SetScript("OnClick", function()
        if frame.countdownTimer then
            frame.countdownTimer:Cancel()
        end
        frame:Hide()
    end)
    
    -- Content
    local content = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    content:SetPoint("TOP", title, "BOTTOM", 0, -15)
    content:SetWidth(350)
    content:SetJustifyH("CENTER")
    content:SetJustifyV("TOP")
    
    local warningText = "|cffff0000WARNING:|r Toxic players detected in your group!\n\n"
    
    if #toxicPlayers > 0 then
        -- Remove duplicates from toxic players list and normalize names
        local uniqueToxicPlayers = {}
        local seen = {}
        for _, player in ipairs(toxicPlayers) do
            -- Normalize player name to include realm
            local normalizedName = ns.Player.NormalizePlayerName(player)
            if not seen[normalizedName] then
                table.insert(uniqueToxicPlayers, normalizedName or player)
                seen[normalizedName] = true
            end
        end
        warningText = warningText .. "|cffff0000Toxic Players:|r\n" .. table.concat(uniqueToxicPlayers, ", ") .. "\n\n"
    end
    
    warningText = warningText .. "|cffaaaaaaBe cautious when playing with these players.|r"
    
    content:SetText(warningText)
    
    -- Countdown bar
    local countdownBar = CreateFrame("StatusBar", nil, frame)
    countdownBar:SetSize(360, 12)
    countdownBar:SetPoint("BOTTOM", 0, 30)
    countdownBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    countdownBar:SetStatusBarColor(1, 1, 0, 0.8) -- Yellow
    
    -- Countdown bar background
    local countdownBg = countdownBar:CreateTexture(nil, "BACKGROUND")
    countdownBg:SetAllPoints()
    countdownBg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    countdownBg:SetVertexColor(0.3, 0.3, 0.3, 0.5)
    
    -- Use constants for timer, fallback to database setting
    local timerSeconds = ns.Constants.WARNING_POPUP_TIMER()
    countdownBar:SetMinMaxValues(0, timerSeconds)
    countdownBar:SetValue(timerSeconds)
    
    -- Countdown text
    local countdownText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    countdownText:SetPoint("BOTTOM", countdownBar, "TOP", 0, 5)
    countdownText:SetText("Auto-close in " .. timerSeconds .. " seconds")
    countdownText:SetTextColor(1, 1, 1, 0.8)
    
    -- Leave Group button
    local leaveBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    leaveBtn:SetSize(120, 30)
    leaveBtn:SetPoint("BOTTOM", countdownBar, "TOP", 0, 20)
    leaveBtn:SetText("Leave Group")
    leaveBtn:SetScript("OnClick", function()
        if IsInGroup() then
            C_PartyInfo.LeaveParty()
            ns.Core.DebugPrint("Left group due to toxic players detected")
        end
        if frame.countdownTimer then
            frame.countdownTimer:Cancel()
        end
        frame:Hide()
    end)
    
    
    -- Show the frame
    frame:Show()
    
    -- Countdown timer
    local timeLeft = timerSeconds
    local countdownTimer = C_Timer.NewTicker(1, function()
        timeLeft = timeLeft - 1
        countdownBar:SetValue(timeLeft)
        countdownText:SetText("Auto-close in " .. timeLeft .. " seconds")

        if timeLeft <= 0 then
            if countdownTimer then
                countdownTimer:Cancel()
            end
            frame:Hide()
        end
    end)
    
    -- Store timer reference in frame for cleanup
    frame.countdownTimer = countdownTimer
end

-- Target frame indicator for toxic/pumper players
function ns.Events.UpdateTargetFrame()
    if not _G.TargetFrame then 
        ns.Core.DebugPrint("UpdateTargetFrame: TargetFrame not found")
        return 
    end
    
    -- Initialize setting if not exists (fallback)
    if ToxicifyDB.TargetFrameIndicatorEnabled == nil then
        ToxicifyDB.TargetFrameIndicatorEnabled = true
        ns.Core.DebugPrint("UpdateTargetFrame: Target frame indicator setting initialized to true")
    end
    
    -- Check if target frame indicator is enabled
    if not ToxicifyDB.TargetFrameIndicatorEnabled then
        ns.Core.DebugPrint("UpdateTargetFrame: Target frame indicator disabled")
        -- Hide existing indicator if disabled
        if _G.ToxicifyTargetIndicator then
            _G.ToxicifyTargetIndicator:Hide()
        end
        return
    end
    
    -- Remove existing indicator
    if _G.ToxicifyTargetIndicator then
        _G.ToxicifyTargetIndicator:Hide()
    end
    
    -- Check if target is a player
    if not UnitIsPlayer("target") then 
        ns.Core.DebugPrint("UpdateTargetFrame: Target is not a player")
        return 
    end
    
    local targetName = GetUnitName("target", true)
    if not targetName then 
        ns.Core.DebugPrint("UpdateTargetFrame: No target name")
        return 
    end
    
    ns.Core.DebugPrint("UpdateTargetFrame: Checking target: " .. targetName)
    
    local isToxic = ns.Player.IsToxic(targetName)
    local isPumper = ns.Player.IsPumper(targetName)
    
    ns.Core.DebugPrint("UpdateTargetFrame: isToxic=" .. tostring(isToxic) .. ", isPumper=" .. tostring(isPumper))
    
    if not isToxic and not isPumper then 
        ns.Core.DebugPrint("UpdateTargetFrame: Target is neither toxic nor pumper")
        return 
    end
    
    -- Create indicator frame
    local indicator = _G.ToxicifyTargetIndicator or CreateFrame("Frame", "ToxicifyTargetIndicator", _G.TargetFrame)
    indicator:SetSize(80, 20)
    indicator:SetPoint("TOPLEFT", _G.TargetFrame, "TOPLEFT", 20, -5)
    indicator:SetFrameStrata("HIGH")
    indicator:SetFrameLevel(1000)
    
    -- Create text
    if not indicator.text then
        indicator.text = indicator:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        indicator.text:SetPoint("LEFT")
        indicator.text:SetJustifyH("LEFT")
    end
    
    -- Set text and color based on status
    if isToxic then
        indicator.text:SetText("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:16:16|t |cffff0000TOXIC|r")
        ns.Core.DebugPrint("UpdateTargetFrame: Showing TOXIC indicator")
    elseif isPumper then
        indicator.text:SetText("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:16:16|t |cff00ff00PUMPER|r")
        ns.Core.DebugPrint("UpdateTargetFrame: Showing PUMPER indicator")
    end
    
    indicator:Show()
    ns.Core.DebugPrint("UpdateTargetFrame: Indicator shown")
end

-- Initialize event handlers
function ns.Events.Initialize()
    -- Initialize target frame indicator setting
    if ToxicifyDB.TargetFrameIndicatorEnabled == nil then
        ToxicifyDB.TargetFrameIndicatorEnabled = true
        ns.Core.DebugPrint("Events.Initialize: Target frame indicator setting initialized to true")
    end
    
    -- Group roster updates
    local rosterFrame = CreateFrame("Frame")
    rosterFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    rosterFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    rosterFrame:SetScript("OnEvent", function(self, event, ...)
        ns.Events.UpdateGroupMembers(event)
    end)
    
    -- Target frame updates
    local targetFrame = CreateFrame("Frame")
    targetFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    targetFrame:RegisterEvent("UNIT_TARGET")
    targetFrame:SetScript("OnEvent", function(self, event, ...)
        ns.Events.UpdateTargetFrame()
    end)
    
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
