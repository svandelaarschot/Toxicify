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
    
    -- Check if Events module exists before initializing
    if ns.Events then
        ns.Events.Initialize()
    else
        print("Toxicify: Events module not loaded!")
    end
    
    ns.UI.Initialize()
    ns.GroupFinder.Initialize()
    ns.Commands.Initialize()
    ns.Minimap.Initialize()
end

-- Initialize the addon
ns.Initialize()