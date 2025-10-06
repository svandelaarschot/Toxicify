-- Toxicify.lua - Main addon initialization
local addonName, ns = ...

-- Gebruik de gedeelde namespace van WoW; maak GEEN nieuwe lokale ns aan
-- (andere files delen dezelfde tabel via ...).
-- Optioneel: expose als globale tabel voor debug/interop
_G.Toxicify = ns

-- Eénmalige bootstrap guard
ns._bootstrapped = ns._bootstrapped or false

-- Veilige helper om module-inits in consistente volgorde te starten
local function SafeInitialize(label, fn)
    if type(fn) == "function" then
        local ok, err = pcall(fn)
        if not ok then
            -- Probeer via Core.DebugPrint te loggen; val terug op print
            if ns.Core and ns.Core.DebugPrint then
                ns.Core.DebugPrint(("Init error in %s: %s"):format(label, tostring(err)), true)
            else
                print("|cffff0000Toxicify:|r Init error in " .. tostring(label) .. ": " .. tostring(err))
            end
        end
    else
        -- Optioneel: debug melding als een module ontbreekt
        if ns.Core and ns.Core.DebugPrint then
            ns.Core.DebugPrint(("Skip init: %s.Initialize() not found"):format(label))
        end
    end
end

-- Centrale Initialize die ALLE modules start (alleen op EVENT aanroepen!)
function ns.Initialize()
    if ns._bootstrapped then return end
    ns._bootstrapped = true

    -- Zorg dat Core als eerste gaat (SavedVariables, defaults, CVar-sync, etc.)
    SafeInitialize("Core",        ns.Core and ns.Core.Initialize)

    -- Overige modules in jouw volgorde
    SafeInitialize("Player",      ns.Player and ns.Player.Initialize)
    SafeInitialize("Events",      ns.Events and ns.Events.Initialize)
    SafeInitialize("UI",          ns.UI and ns.UI.Initialize)
    SafeInitialize("GroupFinder", ns.GroupFinder and ns.GroupFinder.Initialize)
    SafeInitialize("Commands",    ns.Commands and ns.Commands.Initialize)
    SafeInitialize("Minimap",     ns.Minimap and ns.Minimap.Initialize)

    -- Optioneel: log één duidelijke ready-regel
    if ns.Core and ns.Core.DebugPrint then
        ns.Core.DebugPrint("All modules initialized.")
    else
        print("|cff39FF14Toxicify:|r Modules initialized.")
    end
end

-- Event-driver: init pas als dit addonpakket is geladen
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" and name == addonName then
        -- Nu zijn SavedVariables beschikbaar; start bootstrap.
        ns.Initialize()
        -- Event niet meer nodig
        frame:UnregisterEvent("ADDON_LOADED")
    end
end)