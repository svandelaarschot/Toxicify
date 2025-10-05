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
    local playerData = ToxicifyDB[ns.Player.NormalizePlayerName(playerName)]
    if type(playerData) == "table" then
        return playerData.status == "pumper"
    elseif type(playerData) == "string" then
        -- Handle legacy data format
        return playerData == "pumper"
    end
    return false
end

-- Check if player is marked as toxic
function ns.Player.IsToxic(playerName)
    if not playerName then return false end
    local playerData = ToxicifyDB[ns.Player.NormalizePlayerName(playerName)]
    if type(playerData) == "table" then
        return playerData.status == "toxic"
    elseif type(playerData) == "string" then
        -- Handle legacy data format
        return playerData == "toxic"
    end
    return false
end

-- Mark player as pumper
function ns.Player.MarkPumper(playerName)
    local norm = ns.Player.NormalizePlayerName(playerName)
    if norm then
        local currentTime = time()
        local dateTime = date("%Y-%m-%d %H:%M:%S", currentTime)
        ToxicifyDB[norm] = {
            status = "pumper",
            timestamp = currentTime,
            datetime = dateTime
        }
        print("|cff00ff00Toxicify:|r " .. playerName .. " marked as Pumper on " .. dateTime .. ".")
        
        -- Track manual marking for run suppression
        if ns.Events and ns.Events.TrackManualMarking then
            ns.Events.TrackManualMarking()
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
        
        -- Trigger party warning check (but not online detection for manual marking)
        if ns.Events and ns.Events.UpdateGroupMembers then
            ns.Events.UpdateGroupMembers("MANUAL_MARK")
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
        local currentTime = time()
        local dateTime = date("%Y-%m-%d %H:%M:%S", currentTime)
        ToxicifyDB[norm] = {
            status = "toxic",
            timestamp = currentTime,
            datetime = dateTime
        }
        print("|cffff0000Toxicify:|r " .. playerName .. " marked as Toxic on " .. dateTime .. ".")
        
        -- Send whisper if enabled
        if ToxicifyDB.WhisperOnMark then
            local msg = ToxicifyDB.WhisperMessage or "U have been marked as Toxic player by - Toxicify Addon"
            SendChatMessage(msg, "WHISPER", nil, playerName)
        end
        
        -- Add to ignore list if enabled
        if ToxicifyDB.IgnoreOnMark then
            ns.Player.AddToIgnoreListSafely(playerName)
        end
        
        -- Track manual marking for run suppression
        if ns.Events and ns.Events.TrackManualMarking then
            ns.Events.TrackManualMarking()
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
        
        -- Trigger party warning check (but not online detection for manual marking)
        if ns.Events and ns.Events.UpdateGroupMembers then
            ns.Events.UpdateGroupMembers("MANUAL_MARK")
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
    local playerData = ToxicifyDB[norm]
    if type(playerData) == "table" then
        return playerData.status
    elseif type(playerData) == "string" then
        -- Handle legacy data format
        return playerData
    end
    return nil
end

-- Get player data (including datetime)
function ns.Player.GetPlayerData(playerName)
    if not playerName then return nil end
    local norm = ns.Player.NormalizePlayerName(playerName)
    local playerData = ToxicifyDB[norm]
    if type(playerData) == "table" then
        return playerData
    elseif type(playerData) == "string" then
        -- Convert legacy data to new format
        local currentTime = time()
        local dateTime = date("%Y-%m-%d %H:%M:%S", currentTime)
        return {
            status = playerData,
            timestamp = currentTime,
            datetime = dateTime
        }
    end
    return nil
end

-- Get all players with status
function ns.Player.GetAllPlayers()
    local players = {}
    for name, data in pairs(ToxicifyDB) do
        if type(data) == "table" and (data.status == "toxic" or data.status == "pumper") then
            players[name] = data
        elseif type(data) == "string" and (data == "toxic" or data == "pumper") then
            -- Handle legacy data format
            local currentTime = time()
            local dateTime = date("%Y-%m-%d %H:%M:%S", currentTime)
            players[name] = {
                status = data,
                timestamp = currentTime,
                datetime = dateTime
            }
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

-- Clear players by date (older than specified date)
function ns.Player.ClearPlayersByDate(cutoffDate)
    if not cutoffDate then
        print("|cffff0000Toxicify:|r Error: No cutoff date provided.")
        return
    end
    
    local cutoffTimestamp = cutoffDate
    if type(cutoffDate) == "string" then
        -- Parse date string (format: "YYYY-MM-DD" or "YYYY-MM-DD HH:MM:SS")
        local year, month, day, hour, min, sec = cutoffDate:match("(%d+)-(%d+)-(%d+)%s*(%d*):?(%d*):?(%d*)")
        if year and month and day then
            hour = hour and tonumber(hour) or 0
            min = min and tonumber(min) or 0
            sec = sec and tonumber(sec) or 0
            cutoffTimestamp = time({year=tonumber(year), month=tonumber(month), day=tonumber(day), hour=hour, min=min, sec=sec})
        else
            print("|cffff0000Toxicify:|r Error: Invalid date format. Use YYYY-MM-DD or YYYY-MM-DD HH:MM:SS")
            return
        end
    end
    
    local removedCount = 0
    for name, data in pairs(ToxicifyDB) do
        if type(data) == "table" and data.timestamp and data.timestamp < cutoffTimestamp then
            ToxicifyDB[name] = nil
            removedCount = removedCount + 1
        elseif type(data) == "string" then
            -- Legacy data - remove it (assume it's old)
            ToxicifyDB[name] = nil
            removedCount = removedCount + 1
        end
    end
    
    print("|cff00ff00Toxicify:|r Removed " .. removedCount .. " players older than " .. date("%Y-%m-%d %H:%M:%S", cutoffTimestamp) .. ".")
    
    -- Update UI if available
    if ns.UI and ns.UI.RefreshSharedList then
        ns.UI.RefreshSharedList()
    end
    if ns.UI and ns.UI.TriggerRefresh then
        ns.UI.TriggerRefresh()
    end
    if ns.UI and ns.UI.ToxicUIFrame and ns.UI.ToxicUIFrame.Refresh then
        ns.UI.ToxicUIFrame:Refresh()
    end
end

-- Clear players by days old
function ns.Player.ClearPlayersByDaysOld(daysOld)
    if not daysOld or daysOld < 0 then
        print("|cffff0000Toxicify:|r Error: Invalid days value. Must be 0 or greater.")
        return
    end
    
    local cutoffTimestamp = time() - (daysOld * 24 * 60 * 60)
    ns.Player.ClearPlayersByDate(cutoffTimestamp)
end

-- Ignore list management functions
function ns.Player.GetIgnoreListCount()
    return C_FriendList.GetNumIgnores()
end

function ns.Player.GetIgnoreListCapacity()
    return 50 -- WoW ignore list capacity
end

function ns.Player.IsIgnoreListFull()
    return ns.Player.GetIgnoreListCount() >= ns.Player.GetIgnoreListCapacity()
end

function ns.Player.ClearOldestIgnoreEntries(count)
    if not count or count <= 0 then
        return 0
    end
    
    local removedCount = 0
    local ignoreCount = ns.Player.GetIgnoreListCount()
    
    -- Get all ignore entries
    local ignoreEntries = {}
    for i = 1, ignoreCount do
        local name = C_FriendList.GetIgnoreName(i)
        if name then
            table.insert(ignoreEntries, {index = i, name = name})
        end
    end
    
    -- Remove the oldest entries (first entries in the list)
    local toRemove = math.min(count, #ignoreEntries)
    for i = 1, toRemove do
        local entry = ignoreEntries[i]
        if entry and entry.name then
            C_FriendList.DelIgnore(entry.name)
            removedCount = removedCount + 1
        end
    end
    
    return removedCount
end

function ns.Player.ManageIgnoreListCapacity()
    if ns.Player.IsIgnoreListFull() then
        local removedCount = ns.Player.ClearOldestIgnoreEntries(20)
        if removedCount > 0 then
            print("|cffaaaaaaToxicify:|r Ignore list was full. Removed " .. removedCount .. " oldest entries to make space.")
        end
    end
end

function ns.Player.AddToIgnoreListSafely(playerName)
    -- Check if already ignored
    local numIgnores = C_FriendList.GetNumIgnores()
    for i = 1, numIgnores do
        local ignoredName = C_FriendList.GetIgnoreName(i)
        if ignoredName == playerName then
            ns.Core.DebugPrint("Player " .. playerName .. " is already in ignore list")
            return true
        end
    end
    
    -- Manage capacity before adding
    ns.Player.ManageIgnoreListCapacity()
    
    -- Add to ignore list
    local success = pcall(function()
        C_FriendList.AddIgnore(playerName)
    end)
    
    if success then
        print("|cffaaaaaaToxicify:|r " .. playerName .. " has been added to your Ignore list.")
        return true
    else
        print("|cffff0000Toxicify:|r Failed to add " .. playerName .. " to ignore list.")
        return false
    end
end
