-- Events.lua - Event handling and group roster updates
local addonName, ns = ...

-- Events namespace
ns.Events = {}

-- Function to initialize warning cache in database
local function InitializeWarningCache()
    if not ToxicifyDB.WarningCache then
        ToxicifyDB.WarningCache = {
            toxic = {},
            pumper = {}
        }
    end
end

-- Function to clear warning cache (useful for new groups)
function ns.Events.ClearWarningCache()
    if not ToxicifyDB.WarningCache then
        InitializeWarningCache()
    end
    ToxicifyDB.WarningCache.toxic = {}
    ToxicifyDB.WarningCache.pumper = {}
    ns.Core.DebugPrint("Warning cache cleared")
end

-- Track if we were in a group to detect when we leave
local wasInGroup = false

-- Function to handle group leave events
local function OnGroupLeft()
    if wasInGroup and not IsInGroup() then
        ns.Core.DebugPrint("Left group - clearing warning cache for next group")
        ns.Events.ClearWarningCache()
        wasInGroup = false
    elseif IsInGroup() then
        wasInGroup = true
    end
end

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
        -- Initialize warning cache if needed
        InitializeWarningCache()
        
        -- Filter out players we've already warned about this session
        local newToxicPlayers = {}
        for _, playerName in ipairs(toxicPlayers) do
            if not ToxicifyDB.WarningCache.toxic[playerName] then
                table.insert(newToxicPlayers, playerName)
                ToxicifyDB.WarningCache.toxic[playerName] = true
                ns.Core.DebugPrint("Added to toxic warning cache: " .. playerName)
            else
                ns.Core.DebugPrint("Skipping toxic warning for " .. playerName .. " (already shown this session)")
            end
        end
        
        -- Show popup warning only for new players
        if #newToxicPlayers > 0 then
            -- Delay the popup to wait for loading screen to finish
            C_Timer.After(ns.Constants.WARNING_POPUP_DELAY, function()
                ns.Events.ShowToxicWarningPopup(newToxicPlayers)
            end)
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
    ns.countdownTimer = C_Timer.NewTicker(1, function()
        timeLeft = timeLeft - 1
        countdownBar:SetValue(timeLeft)
        countdownText:SetText("Auto-close in " .. timeLeft .. " seconds")

        if timeLeft <= 0 then
        if ns.countdownTimer then
            ns.countdownTimer:Cancel()
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
        
        -- Check for group leave on roster updates
        if event == "GROUP_ROSTER_UPDATE" then
            OnGroupLeft()
        end
        
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
            -- Also update guild roster display
            C_Timer.After(0.5, function()
                ns.Events.UpdateGuildRosterDisplay()
            end)
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
    
    -- Simple GameTooltip hook with better duplicate prevention
    local tooltipCache = {}
    
    local function OnTooltipSetUnit(tooltip)
        if not tooltip or not tooltip:IsShown() then return end
        
        -- Get the first line of the tooltip (usually the player name)
        local name = _G[tooltip:GetName() .. "TextLeft1"]
        if name then
            local nameText = name:GetText()
            if nameText then
                -- Skip non-player tooltips
                if nameText:find("Tab") or nameText:find("Channel") or nameText:find("General") or nameText:find("Loot") or nameText:find("Log") then
                    return
                end
                
                -- Create unique key for this tooltip
                local tooltipKey = nameText .. ":" .. GetTime()
                
                -- Skip if we already processed this tooltip recently
                if tooltipCache[nameText] and (GetTime() - tooltipCache[nameText]) < 1 then
                    return
                end
                tooltipCache[nameText] = GetTime()
                
                ns.Core.DebugPrint("GameTooltip name: " .. nameText)
                
                -- Try multiple name formats
                local nameVariations = {
                    nameText,
                    nameText .. "-" .. GetRealmName(),
                    nameText .. "-" .. GetNormalizedRealmName()
                }
                
                for _, testName in ipairs(nameVariations) do
                    if ns.Player.IsToxic(testName) then
                        tooltip:AddLine(" ")  -- Add some spacing
                        tooltip:AddLine("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:16:16|t |cffff0000Toxic Player|r")
                        ns.Core.DebugPrint("Added toxic tooltip for: " .. testName)
                        return
                    elseif ns.Player.IsPumper(testName) then
                        tooltip:AddLine(" ")  -- Add some spacing
                        tooltip:AddLine("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:16:16|t |cff00ff00Pumper|r")
                        ns.Core.DebugPrint("Added pumper tooltip for: " .. testName)
                        return
                    end
                end
            end
        end
    end
    
    -- Hook GameTooltip with better duplicate prevention
    GameTooltip:HookScript("OnShow", function(self)
        OnTooltipSetUnit(self)
    end)
    
    -- Chat message filtering with throttling to prevent spam
    local chatFilterCache = {}
    
    local function AddChatIcons(self, event, message, sender, ...)
        if not sender or not message then return false end
        
        -- Create unique key for this message to prevent duplicate processing
        local messageKey = event .. ":" .. sender .. ":" .. message
        local currentTime = GetTime()
        
        -- Skip if we processed this exact message recently (within 0.1 seconds)
        if chatFilterCache[messageKey] and (currentTime - chatFilterCache[messageKey]) < 0.1 then
            return false
        end
        chatFilterCache[messageKey] = currentTime
        
        ns.Core.DebugPrint("=== CHAT FILTER DEBUG ===")
        ns.Core.DebugPrint("Event: " .. event)
        ns.Core.DebugPrint("Sender: '" .. sender .. "'")
        ns.Core.DebugPrint("Message: '" .. message .. "'")
        
        -- Clean sender name (remove realm if present)
        local cleanSender = sender:match("([^-]+)") or sender
        ns.Core.DebugPrint("Clean sender: '" .. cleanSender .. "'")
        
        -- Check if this player is marked
        local nameVariations = {
            sender,
            cleanSender,
            sender .. "-" .. GetRealmName(),
            cleanSender .. "-" .. GetRealmName(),
            sender .. "-" .. GetNormalizedRealmName(),
            cleanSender .. "-" .. GetNormalizedRealmName()
        }
        
        ns.Core.DebugPrint("Testing name variations:")
        for i, testName in ipairs(nameVariations) do
            local isToxic = ns.Player.IsToxic(testName)
            local isPumper = ns.Player.IsPumper(testName)
            ns.Core.DebugPrint("  " .. i .. ": '" .. testName .. "' - Toxic: " .. tostring(isToxic) .. ", Pumper: " .. tostring(isPumper))
            
            if isToxic then
                local icon = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:12:12|t"
                ns.Core.DebugPrint("*** FOUND TOXIC PLAYER: " .. testName .. " ***")
                
                -- Try to modify the player name in the message
                local newMessage = message
                
                -- Look for [Level:Name] pattern and add icon before name
                if message:find("%[%d+:" .. cleanSender .. "%]") then
                    newMessage = message:gsub("(%[%d+:)(" .. cleanSender:gsub("%-", "%%-") .. ")(%])", "%1" .. icon .. " %2%3")
                    ns.Core.DebugPrint("Modified level pattern: '" .. newMessage .. "'")
                elseif message:find(cleanSender) then
                    -- For simple name occurrences, add icon before the name
                    newMessage = message:gsub("(" .. cleanSender:gsub("%-", "%%-") .. ")", icon .. " %1")
                    ns.Core.DebugPrint("Modified simple pattern: '" .. newMessage .. "'")
                end
                
                ns.Core.DebugPrint("FINAL RESULT:")
                ns.Core.DebugPrint("  Original: '" .. message .. "'")
                ns.Core.DebugPrint("  Modified: '" .. newMessage .. "'")
                return false, newMessage, sender, ...
                
            elseif isPumper then
                local icon = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:12:12|t"
                ns.Core.DebugPrint("*** FOUND PUMPER PLAYER: " .. testName .. " ***")
                
                -- Try to modify the player name in the message
                local newMessage = message
                
                -- Look for [Level:Name] pattern and add icon before name
                if message:find("%[%d+:" .. cleanSender .. "%]") then
                    newMessage = message:gsub("(%[%d+:)(" .. cleanSender:gsub("%-", "%%-") .. ")(%])", "%1" .. icon .. " %2%3")
                    ns.Core.DebugPrint("Modified level pattern: '" .. newMessage .. "'")
                elseif message:find(cleanSender) then
                    -- For simple name occurrences, add icon before the name
                    newMessage = message:gsub("(" .. cleanSender:gsub("%-", "%%-") .. ")", icon .. " %1")
                    ns.Core.DebugPrint("Modified simple pattern: '" .. newMessage .. "'")
                end
                
                ns.Core.DebugPrint("FINAL RESULT:")
                ns.Core.DebugPrint("  Original: '" .. message .. "'")
                ns.Core.DebugPrint("  Modified: '" .. newMessage .. "'")
                return false, newMessage, sender, ...
            end
        end
        
        ns.Core.DebugPrint("No match found for this player")
        return false
    end
    
    -- Register chat filters for all relevant chat types
    ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", AddChatIcons)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", AddChatIcons)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", AddChatIcons)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY", AddChatIcons)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY_LEADER", AddChatIcons)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID", AddChatIcons)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_LEADER", AddChatIcons)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_WARNING", AddChatIcons)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_INSTANCE_CHAT", AddChatIcons)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_INSTANCE_CHAT_LEADER", AddChatIcons)
    
    ns.Core.DebugPrint("Basic chat filters registered - testing phase")
    
    -- Tooltip integration
    if TooltipDataProcessor then
        -- Debug all tooltip types to see which one is used for guild members
        local function DebugTooltipType(tooltipType, typeName)
            TooltipDataProcessor.AddTooltipPostCall(tooltipType, function(tooltip, data)
                ns.Core.DebugPrint("Tooltip type triggered: " .. typeName)
                if data then
                    ns.Core.DebugPrint("  Data available: " .. tostring(data ~= nil))
                    if data.memberInfo then
                        ns.Core.DebugPrint("  Has memberInfo: " .. (data.memberInfo.name or "no name"))
                    end
                end
            end)
        end
        
        -- Hook all possible tooltip types
        if Enum.TooltipDataType.Unit then
            DebugTooltipType(Enum.TooltipDataType.Unit, "Unit")
        end
        if Enum.TooltipDataType.GuildMember then
            DebugTooltipType(Enum.TooltipDataType.GuildMember, "GuildMember")
        end
        if Enum.TooltipDataType.CommunitiesMember then
            DebugTooltipType(Enum.TooltipDataType.CommunitiesMember, "CommunitiesMember")
        end
        if Enum.TooltipDataType.Communities then
            DebugTooltipType(Enum.TooltipDataType.Communities, "Communities")
        end
        if Enum.TooltipDataType.ClubMember then
            DebugTooltipType(Enum.TooltipDataType.ClubMember, "ClubMember")
        end
        
        -- Enhanced Unit tooltip (also handles guild members)
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip, data)
            local unit = select(2, tooltip:GetUnit())
            local name = nil
            
            if unit then
                name = GetUnitName(unit, true)
                ns.Core.DebugPrint("Unit tooltip - unit name: " .. (name or "nil"))
            end
            
            -- If no unit name, try to get name from tooltip text (for guild members)
            if not name then
                local tooltipName = tooltip:GetName()
                if tooltipName then
                    -- Try to extract name from tooltip lines
                    for i = 1, tooltip:NumLines() do
                        local line = _G[tooltipName .. "TextLeft" .. i]
                        if line then
                            local text = line:GetText()
                            if text and not text:find("|c") and not text:find("Level") and not text:find("Guild") then
                                -- This might be the player name
                                name = text
                                ns.Core.DebugPrint("Extracted name from tooltip: " .. name)
                                break
                            end
                        end
                    end
                end
            end
            
            if name then
                -- Try multiple name formats for guild members
                local nameVariations = {
                    name,
                    name .. "-" .. GetRealmName(),
                    name .. "-" .. GetNormalizedRealmName()
                }
                
                for _, testName in ipairs(nameVariations) do
                    ns.Core.DebugPrint("Testing name: " .. testName)
                    if ns.Player.IsToxic(testName) then
                        tooltip:AddLine("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:16:16|t |cffff0000Toxic Player|r")
                        ns.Core.DebugPrint("Added toxic tooltip for: " .. testName)
                        return
                    elseif ns.Player.IsPumper(testName) then
                        tooltip:AddLine("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:16:16|t |cff00ff00Pumper|r")
                        ns.Core.DebugPrint("Added pumper tooltip for: " .. testName)
                        return
                    end
                end
                ns.Core.DebugPrint("No match found for any variation of: " .. name)
            else
                ns.Core.DebugPrint("Could not extract name from tooltip")
            end
        end)
        
        -- Guild member tooltip integration (multiple types)
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.GuildMember, function(tooltip, data)
            ns.Core.DebugPrint("GuildMember tooltip triggered")
        end)
        
        -- Also try Communities member tooltip
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.CommunitiesMember, function(tooltip, data)
            ns.Core.DebugPrint("CommunitiesMember tooltip triggered")
            if data and data.memberInfo then
                local name = data.memberInfo.name
                if name then
                    -- Try multiple server name approaches
                    local server = data.memberInfo.server or GetRealmName() or GetNormalizedRealmName()
                    local fullName = name .. "-" .. server
                    
                    -- Also try without server for same-realm players
                    local nameOnly = name .. "-" .. GetRealmName()
                    
                    -- Try normalized realm name
                    local normalizedName = name .. "-" .. GetNormalizedRealmName()
                    
                    -- Try just the name (for same server)
                    local justName = name
                    
                    ns.Core.DebugPrint("Communities tooltip check: " .. name)
                    ns.Core.DebugPrint("  Trying: " .. fullName)
                    ns.Core.DebugPrint("  Trying: " .. nameOnly)
                    ns.Core.DebugPrint("  Trying: " .. normalizedName)
                    ns.Core.DebugPrint("  Trying: " .. justName)
                    
                    -- Check all possible name variations
                    local isToxic = ns.Player.IsToxic(fullName) or ns.Player.IsToxic(nameOnly) or 
                                   ns.Player.IsToxic(normalizedName) or ns.Player.IsToxic(justName)
                    local isPumper = ns.Player.IsPumper(fullName) or ns.Player.IsPumper(nameOnly) or 
                                    ns.Player.IsPumper(normalizedName) or ns.Player.IsPumper(justName)
                    
                    if isToxic then
                        tooltip:AddLine("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:16:16|t |cffff0000Toxic Player|r")
                        ns.Core.DebugPrint("Added toxic tooltip for: " .. name)
                    elseif isPumper then
                        tooltip:AddLine("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:16:16|t |cff00ff00Pumper|r")
                        ns.Core.DebugPrint("Added pumper tooltip for: " .. name)
                    else
                        ns.Core.DebugPrint("No match found for: " .. name)
                    end
                end
            end
        end)
        
        -- Original GuildMember tooltip (keeping for compatibility)
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.GuildMember, function(tooltip, data)
            if data and data.memberInfo then
                local name = data.memberInfo.name
                if name then
                    -- Try multiple server name approaches
                    local server = data.memberInfo.server or GetRealmName() or GetNormalizedRealmName()
                    local fullName = name .. "-" .. server
                    
                    -- Also try without server for same-realm players
                    local nameOnly = name .. "-" .. GetRealmName()
                    
                    -- Try normalized realm name
                    local normalizedName = name .. "-" .. GetNormalizedRealmName()
                    
                    -- Try just the name (for same server)
                    local justName = name
                    
                    ns.Core.DebugPrint("Guild tooltip check: " .. name)
                    ns.Core.DebugPrint("  Trying: " .. fullName)
                    ns.Core.DebugPrint("  Trying: " .. nameOnly)
                    ns.Core.DebugPrint("  Trying: " .. normalizedName)
                    ns.Core.DebugPrint("  Trying: " .. justName)
                    
                    -- Check all possible name variations
                    local isToxic = ns.Player.IsToxic(fullName) or ns.Player.IsToxic(nameOnly) or 
                                   ns.Player.IsToxic(normalizedName) or ns.Player.IsToxic(justName)
                    local isPumper = ns.Player.IsPumper(fullName) or ns.Player.IsPumper(nameOnly) or 
                                    ns.Player.IsPumper(normalizedName) or ns.Player.IsPumper(justName)
                    
                    if isToxic then
                        tooltip:AddLine("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:16:16|t |cffff0000Toxic Player|r")
                        ns.Core.DebugPrint("Added toxic tooltip for: " .. name)
                    elseif isPumper then
                        tooltip:AddLine("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:16:16|t |cff00ff00Pumper|r")
                        ns.Core.DebugPrint("Added pumper tooltip for: " .. name)
                    else
                        ns.Core.DebugPrint("No match found for: " .. name)
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
            
            ns.Core.DebugPrint("Creating custom Toxicify submenu...")
            
            -- Create custom submenu with full control
            local success, toxicSubmenu = pcall(function()
                local button = rootDescription:CreateButton("Toxicify")
                
                -- Try to set custom properties for better visibility
                if button.SetTooltip then
                    button:SetTooltip("Toxicify Player Management")
                end
                
                -- Set custom icon if possible
                if button.SetTexture then
                    button:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_8")
                end
                
                return button
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
                rootDescription:CreateButton("Remove Mark", function() 
                    ns.Player.RemoveMark(playerName)
                    ns.Core.DebugPrint("Removed mark from " .. playerName .. " via context menu")
                end)
                return
            end
            
            -- Add custom buttons to submenu with icons and tooltips
            local toxicButton = toxicSubmenu:CreateButton("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:16:16|t Mark as Toxic", function() 
                ns.Player.MarkToxic(playerName)
                ns.Core.DebugPrint("Marked " .. playerName .. " as Toxic via context menu")
            end)
            if toxicButton and toxicButton.SetTooltip then
                toxicButton:SetTooltip("Mark this player as toxic")
            end
            
            local pumperButton = toxicSubmenu:CreateButton("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:16:16|t Mark as Pumper", function() 
                ns.Player.MarkPumper(playerName)
                ns.Core.DebugPrint("Marked " .. playerName .. " as Pumper via context menu")
            end)
            if pumperButton and pumperButton.SetTooltip then
                pumperButton:SetTooltip("Mark this player as pumper")
            end
            
            local removeButton = toxicSubmenu:CreateButton("|TInterface\\Buttons\\UI-GroupLoot-Pass-Up:16:16|t Remove Mark", function() 
                ns.Player.RemoveMark(playerName)
                ns.Core.DebugPrint("Removed mark from " .. playerName .. " via context menu")
            end)
            if removeButton and removeButton.SetTooltip then
                removeButton:SetTooltip("Remove any marks from this player")
            end
            
            ns.Core.DebugPrint("Toxicify submenu created successfully")
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

-- Update guild roster display with toxic/pumper icons
function ns.Events.UpdateGuildRosterDisplay()
    -- Check for modern Communities frame first
    if _G.CommunitiesFrame and _G.CommunitiesFrame:IsShown() then
        ns.Core.DebugPrint("Communities frame is open, updating guild roster...")
    elseif _G.GuildFrame and _G.GuildFrame:IsShown() then
        ns.Core.DebugPrint("Guild frame is open, updating guild roster...")
    else
        ns.Core.DebugPrint("No guild/communities frame is open")
        return
    end
    
    ns.Core.DebugPrint("Updating guild roster display...")
    
    -- Wait for guild roster to be populated
    C_Timer.After(0.1, function()
        local numGuildMembers = GetNumGuildMembers()
        ns.Core.DebugPrint("Number of guild members: " .. numGuildMembers)
        
        if numGuildMembers == 0 then
            return
        end
        
        -- Try different guild frame structures
        local foundButtons = 0
        
        -- Check for Communities guild roster structure
        local rosterFrame = nil
        if _G.CommunitiesFrame and _G.CommunitiesFrame.MemberList then
            ns.Core.DebugPrint("Found Communities member list")
            rosterFrame = _G.CommunitiesFrame.MemberList
        elseif _G.GuildRosterContainer and _G.GuildRosterContainer.listScroll then
            ns.Core.DebugPrint("Found modern guild roster container")
            rosterFrame = _G.GuildRosterContainer.listScroll
        end
        
        if rosterFrame then
            local scrollFrame = rosterFrame
            
            -- Debug the Communities frame structure
            ns.Core.DebugPrint("Examining Communities member list structure...")
            if scrollFrame.buttons then
                ns.Core.DebugPrint("Found buttons array with " .. #scrollFrame.buttons .. " buttons")
            elseif scrollFrame.ListScrollFrame and scrollFrame.ListScrollFrame.buttons then
                ns.Core.DebugPrint("Found ListScrollFrame.buttons")
                scrollFrame = scrollFrame.ListScrollFrame
            elseif scrollFrame.ScrollBox then
                ns.Core.DebugPrint("Found ScrollBox (modern UI)")
                -- Modern scroll box system
                if scrollFrame.ScrollBox.GetFrames then
                    local frames = scrollFrame.ScrollBox:GetFrames()
                    ns.Core.DebugPrint("ScrollBox has " .. #frames .. " frames")
                    
                    -- First, clean up any existing icon text to prevent duplicates
                    for i, button in ipairs(frames) do
                        if button.memberInfo and button.memberInfo.name then
                            local regions = {button:GetRegions()}
                            for j, region in ipairs(regions) do
                                if region and region.GetText and region.SetText then
                                    local text = region:GetText()
                                    if text and text:find("|T") then
                                        -- Remove existing icons from text
                                        local cleanText = text:gsub("|T[^|]*|t ", "")
                                        region:SetText(cleanText)
                                    end
                                end
                            end
                        end
                    end
                    
                    -- Then add icons for the correct players
                    for i, button in ipairs(frames) do
                        foundButtons = foundButtons + 1
                        -- Try to find member info in the button
                        if button.memberInfo then
                            local memberInfo = button.memberInfo
                            if memberInfo.name then
                                local fullName = memberInfo.name .. "-" .. GetRealmName()
                                local isToxic = ns.Player.IsToxic(fullName)
                                local isPumper = ns.Player.IsPumper(fullName)
                                
                                if isToxic or isPumper then
                                    -- Find and modify the name text directly
                                    local icon = isToxic and "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:12:12|t" or "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:12:12|t"
                                    local nameUpdated = false
                                    
                                    -- Try to find text regions that contain the player name
                                    local regions = {button:GetRegions()}
                                    for i, region in ipairs(regions) do
                                        if region and region.GetText and region.SetText then
                                            local text = region:GetText()
                                            if text and text:find(memberInfo.name) and not text:find("|T") then
                                                -- Add icon to the name
                                                local newText = icon .. " " .. text
                                                region:SetText(newText)
                                                nameUpdated = true
                                                ns.Core.DebugPrint("Updated name text for: " .. memberInfo.name)
                                                break
                                            end
                                        end
                                    end
                                    
                                    -- If we can't find the text region, try memberInfo directly
                                    if not nameUpdated and memberInfo.SetName then
                                        memberInfo:SetName(icon .. " " .. memberInfo.name)
                                        nameUpdated = true
                                        ns.Core.DebugPrint("Updated memberInfo name for: " .. memberInfo.name)
                                    end
                                    
                                    if nameUpdated then
                                        ns.Core.DebugPrint("Successfully added icon to name: " .. memberInfo.name)
                                    else
                                        ns.Core.DebugPrint("Could not update name for: " .. memberInfo.name)
                                    end
                                end
                                
                                -- Old approach (keeping for fallback)
                                if false then -- Disabled for now
                                    ns.Core.DebugPrint("Found marked Communities member: " .. memberInfo.name)
                                    local icon = isToxic and "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:12:12|t" or "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:12:12|t"
                                    
                                    -- Debug button structure
                                    ns.Core.DebugPrint("Debugging button structure for: " .. memberInfo.name)
                                    if button.Name then
                                        ns.Core.DebugPrint("  Has button.Name")
                                        if button.Name.SetText then
                                            ns.Core.DebugPrint("  button.Name has SetText")
                                            local text = button.Name:GetText()
                                            ns.Core.DebugPrint("  Current text: " .. (text or "nil"))
                                        end
                                    end
                                    
                                    -- Try different common name fields
                                    local nameFields = {"Name", "nameText", "NameText", "memberName", "MemberName"}
                                    local nameUpdated = false
                                    
                                    for _, fieldName in ipairs(nameFields) do
                                        if button[fieldName] and button[fieldName].SetText then
                                            local originalText = button[fieldName]:GetText() or memberInfo.name
                                            if originalText and not originalText:find("|T") then
                                                button[fieldName]:SetText(icon .. " " .. originalText)
                                                nameUpdated = true
                                                ns.Core.DebugPrint("Updated via " .. fieldName .. ": " .. memberInfo.name)
                                                break
                                            end
                                        end
                                    end
                                    
                                    -- If still not updated, try regions
                                    if not nameUpdated then
                                        local regions = {button:GetRegions()}
                                        ns.Core.DebugPrint("  Found " .. #regions .. " regions")
                                        for i, region in ipairs(regions) do
                                            if region then
                                                if region.GetText then
                                                    local text = region:GetText()
                                                    if text and text ~= "" then
                                                        ns.Core.DebugPrint("  Region " .. i .. " text: '" .. text .. "'")
                                                        -- Try exact match or partial match
                                                        if (text == memberInfo.name or text:find(memberInfo.name)) and not text:find("|T") then
                                                            if region.SetText then
                                                                region:SetText(icon .. " " .. text)
                                                                nameUpdated = true
                                                                ns.Core.DebugPrint("Updated via region " .. i .. ": " .. memberInfo.name)
                                                                break
                                                            end
                                                        end
                                                    else
                                                        ns.Core.DebugPrint("  Region " .. i .. " has no text or empty text")
                                                    end
                                                else
                                                    ns.Core.DebugPrint("  Region " .. i .. " has no GetText method")
                                                end
                                            end
                                        end
                                    end
                                    
                                    if not nameUpdated then
                                        ns.Core.DebugPrint("Could not update name display for: " .. memberInfo.name)
                                    end
                                end -- End of disabled old approach
                            end
                        end
                    end
                end
            else
                ns.Core.DebugPrint("Unknown Communities frame structure")
            end
            
            -- Original button processing for older systems
            if scrollFrame.buttons then
                for i, button in ipairs(scrollFrame.buttons) do
                    if button and button.guildIndex then
                        foundButtons = foundButtons + 1
                        local guildIndex = button.guildIndex
                        local name = GetGuildRosterInfo(guildIndex)
                        if name then
                            local fullName = name .. "-" .. GetRealmName()
                            local isToxic = ns.Player.IsToxic(fullName)
                            local isPumper = ns.Player.IsPumper(fullName)
                            
                            if isToxic or isPumper then
                                ns.Core.DebugPrint("Found marked guild member: " .. name)
                                
                                -- Try multiple ways to find and update the name
                                local nameUpdated = false
                                
                                -- Method 1: Direct Name field
                                if button.Name and button.Name.SetText then
                                    local icon = isToxic and "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:12:12|t" or "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:12:12|t"
                                    local originalText = button.Name:GetText() or name
                                    -- Only add icon if not already present
                                    if not originalText:find("|T") then
                                        button.Name:SetText(icon .. " " .. originalText)
                                        nameUpdated = true
                                        ns.Core.DebugPrint("Updated Name field for: " .. name)
                                    end
                                end
                                
                                -- Method 2: Try to find text elements in button
                                if not nameUpdated then
                                    for _, region in ipairs({button:GetRegions()}) do
                                        if region and region.GetText and region.SetText then
                                            local text = region:GetText()
                                            if text and text:find(name) then
                                                local icon = isToxic and "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:12:12|t" or "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:12:12|t"
                                                if not text:find("|T") then
                                                    region:SetText(icon .. " " .. text)
                                                    nameUpdated = true
                                                    ns.Core.DebugPrint("Updated text region for: " .. name)
                                                    break
                                                end
                                            end
                                        end
                                    end
                                end
                                
                                if not nameUpdated then
                                    ns.Core.DebugPrint("Could not find text element to update for: " .. name)
                                end
                            end
                        end
                    end
                end
            end
        end
        
        -- Fallback: Try classic guild frame structure
        if foundButtons == 0 then
            ns.Core.DebugPrint("Trying classic guild frame structure...")
            for i = 1, 20 do -- Check first 20 visible buttons
                local buttonName = "GuildFrameButton" .. i
                local button = _G[buttonName]
                
                if button then
                    foundButtons = foundButtons + 1
                    ns.Core.DebugPrint("Found button: " .. buttonName)
                    
                    -- Try different name field variations
                    local nameText = _G[buttonName .. "Name"] or button.Name or button.name
                    if nameText then
                        ns.Core.DebugPrint("Found name text element for button " .. i)
                    else
                        ns.Core.DebugPrint("No name text found for button " .. i)
                    end
                else
                    break -- No more buttons
                end
            end
        end
        
        ns.Core.DebugPrint("Total buttons found: " .. foundButtons)
        
        -- Manual test: Try to update Agatio if he's in the list
        for i = 1, numGuildMembers do
            local name = GetGuildRosterInfo(i)
            if name and name == "Agatio" then
                ns.Core.DebugPrint("Found Agatio in guild roster at index " .. i)
                local fullName = "Agatio-Bloodscalp"
                local isPumper = ns.Player.IsPumper(fullName)
                ns.Core.DebugPrint("Agatio is pumper: " .. tostring(isPumper))
                break
            end
        end
    end)
end

-- Hook guild frame to update display when opened
local function InstallGuildHooks()
    -- Hook Communities frame (modern guild system)
    if _G.CommunitiesFrame then
        _G.CommunitiesFrame:HookScript("OnShow", function()
            ns.Core.DebugPrint("Communities frame opened, updating roster display...")
            C_Timer.After(1, function()
                ns.Events.UpdateGuildRosterDisplay()
            end)
        end)
        ns.Core.DebugPrint("Communities frame hooks installed")
    end
    
    -- Also hook old guild frame for compatibility
    if _G.GuildFrame then
        -- Hook when guild frame is shown
        _G.GuildFrame:HookScript("OnShow", function()
            ns.Core.DebugPrint("Guild frame opened, updating roster display...")
            C_Timer.After(1, function()
                ns.Events.UpdateGuildRosterDisplay()
            end)
        end)
        
        -- Hook guild roster updates
        if _G.GuildRosterFrame then
            _G.GuildRosterFrame:HookScript("OnShow", function()
                ns.Core.DebugPrint("Guild roster frame shown, updating display...")
                C_Timer.After(0.5, function()
                    ns.Events.UpdateGuildRosterDisplay()
                end)
            end)
        end
        
        -- Hook guild roster container updates (modern UI)
        if _G.GuildRosterContainer then
            -- Try to hook the update function
            if _G.GuildRosterContainer.Update then
                local originalUpdate = _G.GuildRosterContainer.Update
                _G.GuildRosterContainer.Update = function(self, ...)
                    local result = originalUpdate(self, ...)
                    -- Update our icons after the roster updates
                    C_Timer.After(0.1, function()
                        ns.Events.UpdateGuildRosterDisplay()
                    end)
                    return result
                end
                ns.Core.DebugPrint("Hooked GuildRosterContainer.Update")
            end
            
            -- Also hook scroll events
            if _G.CommunitiesFrame and _G.CommunitiesFrame.MemberList and _G.CommunitiesFrame.MemberList.ScrollBox then
                local scrollBox = _G.CommunitiesFrame.MemberList.ScrollBox
                if scrollBox.SetScrollPercentage then
                    local originalSetScrollPercentage = scrollBox.SetScrollPercentage
                    scrollBox.SetScrollPercentage = function(self, ...)
                        local result = originalSetScrollPercentage(self, ...)
                        -- Update icons after scrolling
                        C_Timer.After(0.05, function()
                            ns.Events.UpdateGuildRosterDisplay()
                        end)
                        return result
                    end
                    ns.Core.DebugPrint("Hooked ScrollBox scroll events")
                end
            end
        end
        
        ns.Core.DebugPrint("Guild frame hooks installed")
        return true
    else
        ns.Core.DebugPrint("Guild frame not available for hooking")
        return false
    end
end

-- Try to install hooks immediately
C_Timer.After(3, function()
    if not InstallGuildHooks() then
        -- If guild frame not available, try when guild addon loads
        local guildLoader = CreateFrame("Frame")
        guildLoader:RegisterEvent("ADDON_LOADED")
        guildLoader:SetScript("OnEvent", function(self, event, addonName)
            if addonName == "Blizzard_GuildUI" or addonName == "Blizzard_Communities" then
                ns.Core.DebugPrint("Guild addon loaded: " .. addonName)
                C_Timer.After(1, function()
                    if InstallGuildHooks() then
                        guildLoader:UnregisterEvent("ADDON_LOADED")
                    end
                end)
            end
        end)
        ns.Core.DebugPrint("Waiting for guild addon to load...")
    end
end)

-- Register context menus after addon is fully loaded
ns.Core.DebugPrint("Events.lua loaded completely, scheduling context menu registration...")

-- Register context menus immediately for higher priority
ns.Core.DebugPrint("Attempting to register context menus...")
if Menu then
    ns.Core.DebugPrint("Menu API available, registering context menus")
ns.Events.RegisterContextMenus()
else
    -- Use a timer if Menu API not available yet
    C_Timer.After(1, function()
        ns.Core.DebugPrint("Attempting to register context menus (delayed)...")
        if Menu then
            ns.Core.DebugPrint("Menu API available, registering context menus")
            ns.Events.RegisterContextMenus()
        else
            ns.Core.DebugPrint("Menu API not available - context menus will not work")
        end
        ns.Core.DebugPrint("Context menu registration complete")
    end)
end
ns.Core.DebugPrint("Context menu registration complete")

