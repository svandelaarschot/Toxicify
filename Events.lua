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
    
    -- Check if we're in a Mythic+ dungeon and if the key is already activated
    if C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive() then
        local challengeInfo = C_ChallengeMode.GetActiveKeystoneInfo()
        if challengeInfo and challengeInfo.active then
            -- Skip warning popup if M+ key is already activated
            ns.Core.DebugPrint("Mythic+ key is already activated, skipping warning popup")
            return
        end
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
                    ns.Core.DebugPrint("Attempting to get unit frame for: " .. unit)
                    local frame = ns.UI.GetUnitFrame(unit)
                    if frame then
                        ns.Core.DebugPrint("Frame found, checking for name property")
                        ns.Core.DebugPrint("Frame type: " .. (frame:GetObjectType() or "unknown"))
                        ns.Core.DebugPrint("Frame name: " .. (frame:GetName() or "unnamed"))
                        
                        -- Debug frame properties
                        if frame.name then
                            ns.Core.DebugPrint("Frame has .name property")
                            if frame.name.SetText then
                                ns.Core.DebugPrint("Setting pumper text for: " .. name)
                                frame.name:SetText("|cff00ff00 Pumper: " .. name .. "|r")
                            else
                                ns.Core.DebugPrint("Frame.name exists but no SetText method")
                            end
                        else
                            ns.Core.DebugPrint("Frame has no .name property")
                            -- Try alternative properties
                            if frame.healthbar and frame.healthbar.name then
                                ns.Core.DebugPrint("Trying frame.healthbar.name")
                                if frame.healthbar.name.SetText then
                                    frame.healthbar.name:SetText("|cff00ff00 Pumper: " .. name .. "|r")
                                end
                            elseif frame.Name then
                                ns.Core.DebugPrint("Trying frame.Name (capital N)")
                                if frame.Name.SetText then
                                    frame.Name:SetText("|cff00ff00 Pumper: " .. name .. "|r")
                                end
                            else
                                ns.Core.DebugPrint("No name property found on frame")
                            end
                        end
                    else
                        ns.Core.DebugPrint("No frame found for unit: " .. unit)
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

-- Check guild members for toxic/pumper status and show toast
function ns.Events.CheckGuildMemberOnline()
    if not ToxicifyDB.GuildToastEnabled then
        return
    end
    
    -- Get guild roster info
    local numGuildMembers = GetNumGuildMembers()
    if numGuildMembers == 0 then
        return
    end
    
    local foundCount = 0
    -- Check each guild member (only show debug for found players)
    for i = 1, numGuildMembers do
        local name, rank, rankIndex, level, class, zone, note, officernote, online, status, classFileName, achievementPoints, achievementRank, isMobile, canSoR, repStanding, guid = GetGuildRosterInfo(i)
        
        if name and online then
            local fullName = name .. "-" .. GetRealmName()
            
            if ns.Player.IsToxic(fullName) then
                ns.Core.DebugPrint("Toxic guild member online: " .. name)
                ns.Events.ShowGuildToast(name, "toxic")
                foundCount = foundCount + 1
            elseif ns.Player.IsPumper(fullName) then
                ns.Core.DebugPrint("Pumper guild member online: " .. name)
                ns.Events.ShowGuildToast(name, "pumper")
                foundCount = foundCount + 1
            end
        end
    end
    
    -- Only show summary if we found marked players
    if foundCount > 0 then
        ns.Core.DebugPrint("Guild scan: " .. foundCount .. " marked players online")
    end
end

-- Show guild member toast notification
function ns.Events.ShowGuildToast(playerName, status)
    if not _G.ToxicifyGuildToastFrame then
    local frame = CreateFrame("Frame", "ToxicifyGuildToastFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
    frame:SetSize(350, 80)
    frame:SetPoint("TOP", UIParent, "TOP", 0, -100)
        frame:SetFrameStrata("TOOLTIP")
        frame:SetFrameLevel(1000)
        frame:Hide()
        
        -- Backdrop
        frame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 16,
            insets = { left = 8, right = 8, top = 8, bottom = 8 }
        })
        frame:SetBackdropColor(0, 0, 0, 0.8)
        
        -- Title
        frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        frame.title:SetPoint("TOP", 0, -10)
        frame.title:SetText("|cff39FF14Guild Member Online|r")
        
        -- Content
        frame.content = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.content:SetPoint("CENTER", 0, -5)
        frame.content:SetJustifyH("CENTER")
        frame.content:SetWidth(320)
        
        -- Close button
        frame.closeBtn = CreateFrame("Button", nil, frame)
        frame.closeBtn:SetSize(20, 20)
        frame.closeBtn:SetPoint("TOPRIGHT", -10, -10)
        frame.closeBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
        frame.closeBtn:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
        frame.closeBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
        frame.closeBtn:SetScript("OnClick", function()
            frame:Hide()
        end)
    end
    
    local frame = _G.ToxicifyGuildToastFrame
    local icon = status == "toxic" and "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:16:16|t" or "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:16:16|t"
    local color = status == "toxic" and "|cffff0000" or "|cff00ff00"
    local statusText = status == "toxic" and "Toxic Player" or "Pumper"
    
    frame.content:SetText(icon .. " " .. color .. playerName .. "|r (" .. statusText .. ")")
    frame:Show()
    
    -- Auto-hide after 5 seconds
    if frame.hideTimer then
        frame.hideTimer:Cancel()
    end
    frame.hideTimer = C_Timer.NewTimer(5, function()
        frame:Hide()
    end)
end

-- Initialize event handlers
function ns.Events.Initialize()
    -- Initialize target frame indicator setting
    if ToxicifyDB.TargetFrameIndicatorEnabled == nil then
        ToxicifyDB.TargetFrameIndicatorEnabled = true
    end
    
    -- Initialize guild toast notification setting
    if ToxicifyDB.GuildToastEnabled == nil then
        ToxicifyDB.GuildToastEnabled = false
    end
    
    -- Group roster updates
    local rosterFrame = CreateFrame("Frame")
    rosterFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    rosterFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    rosterFrame:RegisterEvent("CHALLENGE_MODE_START")
    rosterFrame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
    rosterFrame:RegisterEvent("CHALLENGE_MODE_RESET")
    rosterFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    rosterFrame:SetScript("OnEvent", function(self, event, ...)
        ns.Core.DebugPrint("Event fired: " .. event)
        if event == "CHALLENGE_MODE_START" then
            ns.Core.DebugPrint("Mythic+ key activated - no warning popup")
            -- No warning popup when M+ key is activated
        elseif event == "CHALLENGE_MODE_COMPLETED" or event == "CHALLENGE_MODE_RESET" then
            -- No warning popup when M+ ends
        elseif event == "ZONE_CHANGED_NEW_AREA" then
            -- Check if we're entering a M+ dungeon but key not yet activated
            local zoneName = GetZoneText()
            if zoneName and (zoneName:find("Mythic") or zoneName:find("Challenge")) then
                -- Check if we're in a group and M+ key is not yet activated
                if IsInGroup() and C_ChallengeMode and not C_ChallengeMode.IsChallengeModeActive() then
                    ns.Core.DebugPrint("Entering M+ dungeon area - showing warning popup before key activation")
                    C_Timer.After(2, function() -- Delay to ensure we're fully loaded
                        ns.Events.UpdateGroupMembers("ZONE_CHANGED_NEW_AREA")
                    end)
                end
            end
        else
            ns.Events.UpdateGroupMembers(event)
        end
    end)
    
    -- Guild member online notifications
    local guildFrame = CreateFrame("Frame")
    guildFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
    guildFrame:RegisterEvent("CHAT_MSG_SYSTEM")
    guildFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "GUILD_ROSTER_UPDATE" then
            ns.Events.CheckGuildMemberOnline()
        elseif event == "CHAT_MSG_SYSTEM" then
            local message = ...
            -- Check for guild member online messages
            if message and (message:find("has come online") or message:find("is now online")) then
                ns.Core.DebugPrint("Guild member online detected: " .. message)
                C_Timer.After(1, function() -- Delay to ensure roster is updated
                    ns.Events.CheckGuildMemberOnline()
                end)
            end
        end
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
                ns.Core.DebugPrint("No contextData provided")
                return 
            end

            ns.Core.DebugPrint("Context menu triggered - inspecting contextData:")
            for k, v in pairs(contextData) do
                ns.Core.DebugPrint("  " .. tostring(k) .. " = " .. tostring(v))
            end

            local playerName = nil
            
            -- Handle Battle.net friends (no unit, but have accountInfo)
            if contextData.accountInfo and contextData.accountInfo.battleTag then
                ns.Core.DebugPrint("Battle.net friend detected")
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
                ns.Core.DebugPrint("Guild member detected: " .. contextData.name .. "-" .. contextData.server)
                playerName = contextData.name .. "-" .. contextData.server
            -- Handle guild members with different field names
            elseif contextData.name and (contextData.realm or contextData.server) then
                local realm = contextData.realm or contextData.server or GetRealmName()
                ns.Core.DebugPrint("Guild member detected (alt): " .. contextData.name .. "-" .. realm)
                playerName = contextData.name .. "-" .. realm
            -- Handle regular players (have unit)
            elseif contextData.unit then
                ns.Core.DebugPrint("Unit detected: " .. contextData.unit)
                -- Only show for real players, not NPCs
                if not UnitIsPlayer(contextData.unit) then 
                    ns.Core.DebugPrint("Not a player unit, returning")
                    return 
                end
                
                playerName = GetUnitName(contextData.unit, true)
                if not playerName then 
                    ns.Core.DebugPrint("No player name from unit, returning")
                    return 
                end
            -- Handle players by name only (fallback)
            elseif contextData.name then
                ns.Core.DebugPrint("Name-only detection: " .. contextData.name)
                playerName = contextData.name
                -- Add realm if not present
                if not playerName:find("-") then
                    local realm = GetRealmName()
                    playerName = playerName .. "-" .. realm
                    ns.Core.DebugPrint("Added realm: " .. playerName)
                end
            else
                ns.Core.DebugPrint("No recognized context data, returning")
                ns.Core.DebugPrint("Available contextData keys:")
                for k, v in pairs(contextData) do
                    ns.Core.DebugPrint("  " .. k .. " = " .. tostring(v))
                end
                return 
            end
            
            if not playerName then
                ns.Core.DebugPrint("No player name determined, returning")
                return
            end
            
            ns.Core.DebugPrint("Adding context menu for player: " .. playerName)
            
            if not rootDescription then
                ns.Core.DebugPrint("rootDescription is nil, cannot create menu")
                return
            end
            
            ns.Core.DebugPrint("Creating Toxicify submenu...")
            
            -- Create submenu for better organization
            local success, toxicSubmenu = pcall(function()
                return rootDescription:CreateButton("Toxicify")
            end)
            
            if not success or not toxicSubmenu then
                ns.Core.DebugPrint("Failed to create submenu, creating direct buttons")
                -- Fallback to direct buttons
                rootDescription:CreateButton("Mark as Toxic", function() 
                    ns.Player.MarkToxic(playerName)
                    ns.Core.DebugPrint("Marked " .. playerName .. " as Toxic via context menu")
                end)
                rootDescription:CreateButton("Mark as Pumper", function() 
                    ns.Player.MarkPumper(playerName)
                    ns.Core.DebugPrint("Marked " .. playerName .. " as Pumper via context menu")
                end)
                rootDescription:CreateButton("Remove from Toxicify", function() 
                    ns.Player.UnmarkToxic(playerName)
                    ns.Core.DebugPrint("Removed " .. playerName .. " from Toxicify list via context menu")
                end)
            else
                ns.Core.DebugPrint("Submenu created, adding buttons...")
                toxicSubmenu:CreateButton("Mark as Toxic", function() 
                    ns.Player.MarkToxic(playerName)
                    ns.Core.DebugPrint("Marked " .. playerName .. " as Toxic via context menu")
                end)
                toxicSubmenu:CreateButton("Mark as Pumper", function() 
                    ns.Player.MarkPumper(playerName)
                    ns.Core.DebugPrint("Marked " .. playerName .. " as Pumper via context menu")
                end)
                toxicSubmenu:CreateButton("Remove from List", function() 
                    ns.Player.UnmarkToxic(playerName)
                    ns.Core.DebugPrint("Removed " .. playerName .. " from Toxicify list via context menu")
                end)
            end
            
            ns.Core.DebugPrint("Context menu buttons created successfully")
        end

        -- Context menus will be registered after function definition
    end
end

-- Register context menu for various unit types
function ns.Events.RegisterContextMenus()
        ns.Core.DebugPrint("Registering context menus...")
        -- Core unit types
        Menu.ModifyMenu("MENU_UNIT_SELF", function(_, rootDescription, contextData)
            ns.Core.DebugPrint("MENU_UNIT_SELF triggered")
            ns.Events.AddToxicifyContextMenu(_, rootDescription, contextData)
        end)
        Menu.ModifyMenu("MENU_UNIT_PLAYER", function(_, rootDescription, contextData)
            ns.Core.DebugPrint("MENU_UNIT_PLAYER triggered")
            ns.Events.AddToxicifyContextMenu(_, rootDescription, contextData)
        end)
        Menu.ModifyMenu("MENU_UNIT_TARGET", function(_, rootDescription, contextData)
            ns.Core.DebugPrint("MENU_UNIT_TARGET triggered")
            ns.Events.AddToxicifyContextMenu(_, rootDescription, contextData)
        end)
        Menu.ModifyMenu("MENU_UNIT_FRIEND", function(_, rootDescription, contextData)
            ns.Core.DebugPrint("MENU_UNIT_FRIEND triggered")
            ns.Events.AddToxicifyContextMenu(_, rootDescription, contextData)
        end)
        Menu.ModifyMenu("MENU_UNIT_ENEMY_PLAYER", function(_, rootDescription, contextData)
            ns.Core.DebugPrint("MENU_UNIT_ENEMY_PLAYER triggered")
            ns.Events.AddToxicifyContextMenu(_, rootDescription, contextData)
        end)
        
        -- Guild context menu - try the most common working types first
        local guildMenuTypes = {
            "MENU_UNIT_COMMUNITIES_GUILD_MEMBER",
            "MENU_UNIT_COMMUNITIES_MEMBER",
            "MENU_UNIT_GUILD_MEMBER",
            "MENU_UNIT_GUILD_PLAYER",
            "MENU_UNIT_GUILD"
        }
        
        for _, menuType in ipairs(guildMenuTypes) do
            Menu.ModifyMenu(menuType, function(_, rootDescription, contextData)
                ns.Core.DebugPrint("Guild context menu triggered: " .. menuType)
                ns.Events.AddToxicifyContextMenu(_, rootDescription, contextData)
            end)
        end
        
        -- Alternative approach - hook into guild roster directly like RaiderIO
        local function HookGuildRoster()
            if GuildRosterFrame then
                -- Hook the right-click event on guild roster
                local originalOnClick = GuildRosterFrame:GetScript("OnClick")
                GuildRosterFrame:SetScript("OnClick", function(self, button)
                    if button == "RightButton" then
                        local selection = GetGuildRosterSelection()
                        if selection and selection > 0 then
                            local name, rank, rankIndex, level, class, zone, note, officernote, online, status, classFileName, achievementPoints, achievementRank, isMobile, canSoR, repStanding, guid = GetGuildRosterInfo(selection)
                            if name then
                                ns.Core.DebugPrint("Guild member right-clicked: " .. name)
                                -- Create context menu data
                                local contextData = {
                                    unit = nil,
                                    name = name,
                                    server = GetRealmName(),
                                    accountInfo = nil
                                }
                                -- Show context menu
                                ns.Events.AddToxicifyContextMenu(nil, nil, contextData)
                            end
                        end
                    end
                    if originalOnClick then
                        originalOnClick(self, button)
                    end
                end)
                ns.Core.DebugPrint("Guild roster frame hooked successfully")
                return true
            end
            return false
        end
        
        -- Try to hook immediately
        if not HookGuildRoster() then
            -- If not available, try when guild frame opens
            if GuildFrame then
                GuildFrame:HookScript("OnShow", function()
                    C_Timer.After(0.5, HookGuildRoster)
                end)
            end
        end
        
        -- Battle.net friends
        Menu.ModifyMenu("MENU_UNIT_BN_FRIEND", function(_, rootDescription, contextData)
            ns.Events.AddToxicifyContextMenu(_, rootDescription, contextData)
        end)
        
        -- Party members (specific slots)
        for i = 1, 4 do
            Menu.ModifyMenu("MENU_UNIT_PARTY" .. i, function(_, rootDescription, contextData)
                ns.Core.DebugPrint("MENU_UNIT_PARTY" .. i .. " triggered")
                ns.Events.AddToxicifyContextMenu(_, rootDescription, contextData)
            end)
        end
        
        -- Additional party member menu types
        Menu.ModifyMenu("MENU_UNIT_PARTY", function(_, rootDescription, contextData)
            ns.Core.DebugPrint("MENU_UNIT_PARTY triggered")
            ns.Events.AddToxicifyContextMenu(_, rootDescription, contextData)
        end)
        
        Menu.ModifyMenu("MENU_UNIT_PARTY_PLAYER", function(_, rootDescription, contextData)
            ns.Core.DebugPrint("MENU_UNIT_PARTY_PLAYER triggered")
            ns.Events.AddToxicifyContextMenu(_, rootDescription, contextData)
        end)
        
        -- Raid members (specific slots)
        for i = 1, 40 do
            Menu.ModifyMenu("MENU_UNIT_RAID" .. i, function(_, rootDescription, contextData)
                ns.Events.AddToxicifyContextMenu(_, rootDescription, contextData)
            end)
        end
        
    end

-- Register context menus after addon is fully loaded
ns.Core.DebugPrint("Events.lua loaded completely, scheduling context menu registration...")

-- Use a timer to register context menus after everything is loaded
C_Timer.After(2, function()
    ns.Core.DebugPrint("Attempting to register context menus...")
    if Menu then
        ns.Core.DebugPrint("Menu API available, registering context menus")
        ns.Events.RegisterContextMenus()
    else
        ns.Core.DebugPrint("Menu API not available - context menus will not work")
    end
    ns.Core.DebugPrint("Context menu registration complete")
end)

