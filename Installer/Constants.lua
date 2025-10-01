-- Constants.lua - Centralized configuration for timeouts and delays
local addonName, ns = ...

-- Constants namespace
ns.Constants = {}

-- Warning System Timeouts
ns.Constants.WARNING_POPUP_DELAY = 4  -- Delay before showing warning popup (seconds)
ns.Constants.WARNING_POPUP_TIMER = function() 
    return ToxicifyDB and ToxicifyDB.PopupTimerSeconds or 25 
end -- How long the warning popup stays open (seconds)

-- UI Timeouts
ns.Constants.SUGGESTION_BOX_HIDE_DELAY = 0.2 -- Delay before hiding suggestion box (seconds)

-- Initialize constants
function ns.Constants.Initialize()
    -- Debug print if debug mode is enabled
    if ToxicifyDB and ToxicifyDB.DebugEnabled == true then
        print("|cff39FF14[Toxicify DEBUG]|r Constants initialized")
        print("|cffaaaaaaWarning popup delay: " .. ns.Constants.WARNING_POPUP_DELAY .. " seconds|r")
        print("|cffaaaaaaWarning popup timer: " .. ns.Constants.WARNING_POPUP_TIMER() .. " seconds|r")
    end
end

-- Initialize on load
ns.Constants.Initialize()
