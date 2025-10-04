-- Player.lua - Player management functionality
local addonName, ns = ...

-- Player namespace
ns.Player = {}

-- Initialize Player module
function ns.Player.Initialize()
    -- Player initialization if needed
end

-- Normalize player name to standard format
function ns.Player.NormalizePlayerName(playerName)
    if not playerName or playerName == "" then return nil end

    -- Split Name-Realm
    local name, realm = strsplit("-", playerName, 2)
    name = name:gsub("^%l", string.upper) -- Capitalize first letter
    realm = realm or GetNormalizedRealmName()

    return name .. "-" .. realm
end

-- Check if player is marked as pumper
function ns.Player.IsPumper(playerName)
    if not playerName then return false end
    return ToxicifyDB[ns.Player.NormalizePlayerName(playerName)] == "pumper"
end

-- Check if player is marked as toxic
function ns.Player.IsToxic(playerName)
    if not playerName then return false end
    return ToxicifyDB[ns.Player.NormalizePlayerName(playerName)] == "toxic"
end

-- Mark player as pumper
function ns.Player.MarkPumper(playerName)
    local norm = ns.Player.NormalizePlayerName(playerName)
    if norm then
        ToxicifyDB[norm] = "pumper"
        print("|cff00ff00Toxicify:|r " .. playerName .. " marked as Pumper.")
        
        -- Update list immediately
        if ns.UI and ns.UI.RefreshSharedList then
            ns.UI.RefreshSharedList()
        end
        
        -- Trigger custom event for UI updates
        if ns.UI and ns.UI.TriggerRefresh then
            ns.UI.TriggerRefresh()
        end
        
        -- Force refresh toxic UI if it exists
        if ns.UI and ns.UI.ToxicUIFrame and ns.UI.ToxicUIFrame.Refresh then
            ns.UI.ToxicUIFrame:Refresh()
        end
        
        -- Trigger party warning check
        if ns.Events and ns.Events.UpdateGroupMembers then
            ns.Events.UpdateGroupMembers()
        end
        
        -- Update player frame specifically when marking yourself
        if ns.Events and ns.Events.UpdatePlayerFrame then
            ns.Events.UpdatePlayerFrame()
        end
        
        -- Update target frame if this player is currently targeted
        if ns.Events and ns.Events.UpdateTargetFrame then
            ns.Events.UpdateTargetFrame()
        end
    end
end

-- Mark player as toxic
function ns.Player.MarkToxic(playerName)
    local norm = ns.Player.NormalizePlayerName(playerName)
    if norm then
        ToxicifyDB[norm] = "toxic"
        print("|cffff0000Toxicify:|r " .. playerName .. " marked as Toxic.")
        
        -- Send whisper if enabled
        if ToxicifyDB.WhisperOnMark then
            local msg = ToxicifyDB.WhisperMessage or "U have been marked as Toxic player by - Toxicify Addon"
            SendChatMessage(msg, "WHISPER", nil, playerName)
        end
        
        -- Add to ignore list if enabled
        if ToxicifyDB.IgnoreOnMark then
            C_FriendList.AddIgnore(playerName)
            print("|cffaaaaaaToxicify:|r " .. playerName .. " has also been added to your Ignore list.")
        end
        
        -- Update list immediately
        if ns.UI and ns.UI.RefreshSharedList then
            ns.UI.RefreshSharedList()
        end
        
        -- Trigger custom event for UI updates
        if ns.UI and ns.UI.TriggerRefresh then
            ns.UI.TriggerRefresh()
        end
        
        -- Force refresh toxic UI if it exists
        if ns.UI and ns.UI.ToxicUIFrame and ns.UI.ToxicUIFrame.Refresh then
            ns.UI.ToxicUIFrame:Refresh()
        end
        
        -- Trigger party warning check
        if ns.Events and ns.Events.UpdateGroupMembers then
            ns.Events.UpdateGroupMembers()
        end
        
        -- Update player frame specifically when marking yourself
        if ns.Events and ns.Events.UpdatePlayerFrame then
            ns.Events.UpdatePlayerFrame()
        end
        
        -- Update target frame if this player is currently targeted
        if ns.Events and ns.Events.UpdateTargetFrame then
            ns.Events.UpdateTargetFrame()
        end
    end
end

-- Remove player from list
function ns.Player.UnmarkToxic(playerName)
    local norm = ns.Player.NormalizePlayerName(playerName)
    if norm and ToxicifyDB[norm] then
        ToxicifyDB[norm] = nil
        print("|cffaaaaaaToxicify:|r " .. playerName .. " removed from list.")
        
        -- Update list immediately
        if ns.UI and ns.UI.RefreshSharedList then
            ns.UI.RefreshSharedList()
        end
        
        -- Trigger custom event for UI updates
        if ns.UI and ns.UI.TriggerRefresh then
            ns.UI.TriggerRefresh()
        end
        
        -- Force refresh toxic UI if it exists
        if ns.UI and ns.UI.ToxicUIFrame and ns.UI.ToxicUIFrame.Refresh then
            ns.UI.ToxicUIFrame:Refresh()
        end
        
        -- Update player frame specifically when marking yourself
        if ns.Events and ns.Events.UpdatePlayerFrame then
            ns.Events.UpdatePlayerFrame()
        end
        
        -- Update target frame if this player is currently targeted
        if ns.Events and ns.Events.UpdateTargetFrame then
            ns.Events.UpdateTargetFrame()
        end
    end
    
    -- Remove from ignore if option is enabled
    if ToxicifyDB.IgnoreOnMark then
        C_FriendList.DelIgnore(playerName)
        print("|cffaaaaaaToxicify:|r " .. playerName .. " has also been removed from your Ignore list.")
    end
end

-- Get player status
function ns.Player.GetPlayerStatus(playerName)
    if not playerName then return nil end
    local norm = ns.Player.NormalizePlayerName(playerName)
    return ToxicifyDB[norm]
end

-- Get all players with status
function ns.Player.GetAllPlayers()
    local players = {}
    for name, status in pairs(ToxicifyDB) do
        if status == "toxic" or status == "pumper" then
            players[name] = status
        end
    end
    return players
end


-- Clear all players
function ns.Player.ClearAllPlayers()
    for k in pairs(ToxicifyDB) do
        if type(k) == "string" then 
            ToxicifyDB[k] = nil 
        end
    end
    print("|cffaaaaaaToxicify:|r All players removed from list.")
    
    -- Update list immediately
    if ns.UI and ns.UI.RefreshSharedList then
        ns.UI.RefreshSharedList()
    end
    
    -- Trigger custom event for UI updates
    if ns.UI and ns.UI.TriggerRefresh then
        ns.UI.TriggerRefresh()
    end
    
    -- Force refresh toxic UI if it exists
    if ns.UI and ns.UI.ToxicUIFrame and ns.UI.ToxicUIFrame.Refresh then
        ns.UI.ToxicUIFrame:Refresh()
    end
end
