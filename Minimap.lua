-- Minimap.lua - Minimap button functionality
local addonName, ns = ...

-- Minimap namespace
ns.Minimap = {}

-- Initialize Minimap module
function ns.Minimap.Initialize()
    local LDB = LibStub("LibDataBroker-1.1"):NewDataObject("Toxicify", {
        type = "launcher",
        text = "Toxicify",
        icon = "Interface\\Icons\\ability_creature_poison_05", -- poison icon
        OnClick = function(self, button)
            if button == "LeftButton" then
                InterfaceOptionsFrame_OpenToCategory("Toxicify")
                InterfaceOptionsFrame_OpenToCategory("Toxicify") -- double call fixes Blizzard bug
            elseif button == "RightButton" then
                print("|cff39FF14Toxicify:|r Use /toxic add <playername-realm> or open settings.")
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("|cff39FF14Toxicify|r")
            tooltip:AddLine("Click to open settings")
            tooltip:AddLine("Right click for quick options")
        end,
    })

    local icon = LibStub("LibDBIcon-1.0", true)
    if icon then
        icon:Register("Toxicify", LDB, ToxicifyDB.minimap)
    end
end
