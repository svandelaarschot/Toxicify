-- Toxicify.lua - Main addon initialization
local addonName, ns = ...

-- Initialize namespace if not exists
if not ns then
    ns = {}
end

-- Main Toxicify namespace
Toxicify = ns

-- Initialize all modules
function ns.Initialize()
    -- Initialize all modules
    ns.Core.Initialize()
    ns.Player.Initialize()
    
    -- Don't initialize Events here - it will be initialized in WaitForEvents
    ns.UI.Initialize()
    ns.GroupFinder.Initialize()
    ns.Commands.Initialize()
    ns.Minimap.Initialize()
end

-- Wait for Events module to load
local function WaitForEvents()
    if ns.Events then
        ns.Events.Initialize()
    else
        C_Timer.After(0.1, WaitForEvents)
    end
end

-- Start waiting for Events module
C_Timer.After(0.1, WaitForEvents)

-- Initialize the addon
ns.Initialize()