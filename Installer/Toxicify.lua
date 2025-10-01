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
    ns.Events.Initialize()
    ns.UI.Initialize()
    ns.GroupFinder.Initialize()
    ns.Commands.Initialize()
    ns.Minimap.Initialize()
end

-- Initialize the addon
ns.Initialize()