-- Events.lua - Event handling and group roster updates
local addonName, ns = ...

-- Events namespace
ns.Events = {}

-- Update group members (party/raid/M+)
function ns.Events.UpdateGroupMembers(event)
    -- Only show warning for actual group roster updates, not for PLAYER_ENTERING_WORLD
    if event == "PLAYER_ENTERING_WORLD" then
        return
    end
    
    -- Only show warning if we're actually in a group
    if not IsInGroup() then
        return
    end
    
    local toxicPlayers = {}
    local pumperPlayers = {}
    
    -- Check yourself first
    local playerName = GetUnitName("player", true)
    if playerName and ns.Player.IsToxic(playerName) then
        table.insert(toxicPlayers, playerName)
    end
    if playerName and ns.Player.IsPumper(playerName) then
        table.insert(pumperPlayers, playerName)
    end
    
    -- Check group members if in group
    if IsInGroup() then
        ns.Core.DebugPrint("Checking group members...")
        for i = 1, GetNumGroupMembers() do
            local unit = (IsInRaid() and "raid"..i) or (i == GetNumGroupMembers() and "player" or "party"..i)
            if UnitExists(unit) then
                local name = GetUnitName(unit, true)
                ns.Core.DebugPrint("Checking player: " .. tostring(name))
                if name and ns.Player.IsToxic(name) then
                    ns.Core.DebugPrint("Found toxic player: " .. name)
                    table.insert(toxicPlayers, name)
                    local frame = ns.UI.GetUnitFrame(unit)
                    if frame and frame.name and frame.name.SetText then
                        frame.name:SetText("|cffff0000 Toxic: " .. name .. "|r")
                    end
                end
                if name and ns.Player.IsPumper(name) then
                    ns.Core.DebugPrint("Found pumper player: " .. name)
                    table.insert(pumperPlayers, name)
                    local frame = ns.UI.GetUnitFrame(unit)
                    if frame and frame.name and frame.name.SetText then
                        frame.name:SetText("|cff00ff00 Pumper: " .. name .. "|r")
                    end
                end
            end
        end
        ns.Core.DebugPrint("Total toxic players found: " .. #toxicPlayers)
    end
    
    -- Only set default if not already configured by user
    if ToxicifyDB.PartyWarningEnabled == nil then
        ToxicifyDB.PartyWarningEnabled = true
    end
    if ToxicifyDB.PartyWarningEnabled and #toxicPlayers > 0 then
        -- Show popup warning (only once per session)
        if not _G.ToxicifyWarningShown then
            -- Delay the popup to wait for loading screen to finish
            C_Timer.After(ns.Constants.WARNING_POPUP_DELAY, function()
                ns.Events.ShowToxicWarningPopup(toxicPlayers)
            end)
            _G.ToxicifyWarningShown = true
        end
    end
end

-- Show toxic warning popup
function ns.Events.ShowToxicWarningPopup(toxicPlayers)
    if _G.ToxicifyWarningFrame then
        _G.ToxicifyWarningFrame:Hide()
    end
    
    local frame = CreateFrame("Frame", "ToxicifyWarningFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
    frame:SetSize(400, 250)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
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
    frame:SetBackdropColor(0, 0, 0, 0.9)
    
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
        end
        if frame.countdownTimer then
            frame.countdownTimer:Cancel()
        end
        frame:Hide()
    end)
    
    -- Footer
    local footer = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    footer:SetPoint("BOTTOM", 0, 12)
    footer:SetText("|cffaaaaaaBy Toxicify Addon v2025|r")
    
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
        return 
    end
    
    -- Initialize setting if not exists (fallback)
    if ToxicifyDB.TargetFrameIndicatorEnabled == nil then
        ToxicifyDB.TargetFrameIndicatorEnabled = true
    end
    
    -- Check if target frame indicator is enabled
    if not ToxicifyDB.TargetFrameIndicatorEnabled then
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
        return 
    end
    
    local targetName = GetUnitName("target", true)
    if not targetName then 
        return 
    end
    
    local isToxic = ns.Player.IsToxic(targetName)
    local isPumper = ns.Player.IsPumper(targetName)
    
    if not isToxic and not isPumper then 
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
    elseif isPumper then
        indicator.text:SetText("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:16:16|t |cff00ff00PUMPER|r")
    end
    
    indicator:Show()
end

-- Initialize event handlers
function ns.Events.Initialize()
    -- Initialize target frame indicator setting
    if ToxicifyDB.TargetFrameIndicatorEnabled == nil then
        ToxicifyDB.TargetFrameIndicatorEnabled = true
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
        
        -- Guild member tooltip integration
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.GuildMember, function(tooltip, data)
            if data and data.memberInfo then
                local name = data.memberInfo.name
                local server = data.memberInfo.server
                if name and server then
                    local fullName = name .. "-" .. server
                    if ns.Player.IsToxic(fullName) then
                        tooltip:AddLine("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:16:16|t |cffff0000Toxic Player|r ")
                    elseif ns.Player.IsPumper(fullName) then
                        tooltip:AddLine("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:16:16|t |cff00ff00Pumper|r ")
                    end
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
        -- Define the context menu function
        function ns.Events.AddToxicifyContextMenu(_, rootDescription, contextData)
            if not contextData then 
                return 
            end

            local playerName = nil
            
            -- Handle Battle.net friends (no unit, but have accountInfo)
            if contextData.accountInfo and contextData.accountInfo.battleTag then
                -- Try to get character name and realm from ALL possible fields
                local charName = contextData.name or contextData.characterName or contextData.accountInfo.characterName
                local realm = contextData.realm or contextData.characterRealm or contextData.accountInfo.characterRealm
                
                if charName and realm then
                    playerName = charName .. "-" .. realm
                elseif charName then
                    playerName = charName
                else
                    -- Extract character name from Battle.net tag (remove #numbers)
                    local battleTag = contextData.accountInfo.battleTag
                    local charNameFromTag = battleTag:match("^([^#]+)")
                    if charNameFromTag then
                        playerName = charNameFromTag
                    else
                        -- Fallback to full Battle.net tag
                        playerName = battleTag
                    end
                end
            -- Handle guild members (have name and server)
            elseif contextData.name and contextData.server then
                playerName = contextData.name .. "-" .. contextData.server
            -- Handle regular players (have unit)
            elseif contextData.unit then
                -- Only show for real players, not NPCs
                if not UnitIsPlayer(contextData.unit) then 
                    return 
                end
                
                playerName = GetUnitName(contextData.unit, true)
                if not playerName then 
                    return 
                end
            else
                return 
            end
            
            local toxicSubmenu = rootDescription:CreateButton("Toxicify")
            toxicSubmenu:CreateButton("Mark player as Toxic", function() ns.Player.MarkToxic(playerName) end)
            toxicSubmenu:CreateButton("Mark player as Pumper", function() ns.Player.MarkPumper(playerName) end)
            toxicSubmenu:CreateButton("Remove from List", function() ns.Player.UnmarkToxic(playerName) end)
        end

        -- Context menus will be registered after function definition
    end
end

-- Register context menu for various unit types
function ns.Events.RegisterContextMenus()
        -- Core unit types
        Menu.ModifyMenu("MENU_UNIT_SELF", function(_, rootDescription, contextData)
            ns.Events.AddToxicifyContextMenu(_, rootDescription, contextData)
        end)
        Menu.ModifyMenu("MENU_UNIT_PLAYER", function(_, rootDescription, contextData)
            ns.Events.AddToxicifyContextMenu(_, rootDescription, contextData)
        end)
        Menu.ModifyMenu("MENU_UNIT_TARGET", function(_, rootDescription, contextData)
            ns.Events.AddToxicifyContextMenu(_, rootDescription, contextData)
        end)
        Menu.ModifyMenu("MENU_UNIT_FRIEND", function(_, rootDescription, contextData)
            ns.Events.AddToxicifyContextMenu(_, rootDescription, contextData)
        end)
        Menu.ModifyMenu("MENU_UNIT_ENEMY_PLAYER", function(_, rootDescription, contextData)
            ns.Events.AddToxicifyContextMenu(_, rootDescription, contextData)
        end)
        
        -- Guild context menu
        local guildMenuTypes = {
            "MENU_UNIT_COMMUNITIES_GUILD_MEMBER",
            "MENU_UNIT_COMMUNITIES_MEMBER",
            "MENU_UNIT_GUILD",
            "MENU_UNIT_GUILD_MEMBER",
            "MENU_UNIT_GUILD_PLAYER",
            "MENU_UNIT_GUILD_FRIEND"
        }
        
        for _, menuType in ipairs(guildMenuTypes) do
            Menu.ModifyMenu(menuType, function(_, rootDescription, contextData)
                ns.Events.AddToxicifyContextMenu(_, rootDescription, contextData)
            end)
        end
        
        -- Also keep the old approach as a fallback
        local function RegisterGuildContextMenu()
            -- Hook into the guild roster frame when it's created
            local function HookGuildFrame()
                if GuildRosterFrame then
                    -- Hook into the guild roster frame's context menu
                    local originalGuildRosterFrame_OnClick = GuildRosterFrame:GetScript("OnClick")
                    GuildRosterFrame:SetScript("OnClick", function(self, button)
                        if button == "RightButton" then
                            -- Try to get the guild member info
                            local name, rank, rankIndex, level, class, zone, note, officernote, online, status, classFileName, achievementPoints, achievementRank, isMobile, canSoR, repStanding, guid = GetGuildRosterInfo(GetGuildRosterSelection())
                            if name then
                                -- Create a context menu for this guild member
                                local contextData = {
                                    unit = nil,
                                    name = name,
                                    realm = GetRealmName(),
                                    accountInfo = nil
                                }
                                -- Show the context menu
                                ns.Events.AddToxicifyContextMenu(nil, nil, contextData)
                            end
                        end
                        if originalGuildRosterFrame_OnClick then
                            originalGuildRosterFrame_OnClick(self, button)
                        end
                    end)
                end
            end
            
            -- Try to hook immediately
            HookGuildFrame()
            
            -- Also hook into the guild tab opening event
            local function OnGuildTabOpened()
                HookGuildFrame()
            end
            
            -- Hook into guild tab events
            if GuildFrame then
                GuildFrame:HookScript("OnShow", OnGuildTabOpened)
            end
        end
        
        -- Register the guild context menu
        RegisterGuildContextMenu()
        
        -- Battle.net friends
        Menu.ModifyMenu("MENU_UNIT_BN_FRIEND", function(_, rootDescription, contextData)
            ns.Events.AddToxicifyContextMenu(_, rootDescription, contextData)
        end)
        
        -- Party members (specific slots)
        for i = 1, 4 do
            Menu.ModifyMenu("MENU_UNIT_PARTY" .. i, function(_, rootDescription, contextData)
                ns.Events.AddToxicifyContextMenu(_, rootDescription, contextData)
            end)
        end
        
        -- Raid members (specific slots)
        for i = 1, 40 do
            Menu.ModifyMenu("MENU_UNIT_RAID" .. i, function(_, rootDescription, contextData)
                ns.Events.AddToxicifyContextMenu(_, rootDescription, contextData)
            end)
        end
        
    end

-- Register context menus after function definition
ns.Events.RegisterContextMenus()

