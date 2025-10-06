local addonName, ns = ...

-- Commands namespace
ns.Commands = {}

-- Initialize Commands module
function ns.Commands.Initialize()
    -- Commands are already registered via SlashCmdList
end

-- Slash command registration
if not SLASH_TOXICIFY1 then
    SLASH_TOXICIFY1 = "/toxic"
    SlashCmdList["TOXICIFY"] = function(msg)
        local cmd, arg1, arg2 = strsplit(" ", msg, 3)
        cmd = string.lower(cmd or "")

        if cmd == "add" and arg1 then
            -- Check if trying to mark yourself
            local playerName = GetUnitName("player", true)
            if arg1 == playerName or arg1 == GetUnitName("player", false) then
                ns.Core.DebugPrint("You cannot mark yourself as toxic!", true)
                return
            end
            ns.Player.MarkToxic(arg1)
        elseif cmd == "addpumper" and arg1 then
            -- Check if trying to mark yourself
            local playerName = GetUnitName("player", true)
            if arg1 == playerName or arg1 == GetUnitName("player", false) then
                ns.Core.DebugPrint("You cannot mark yourself as pumper!", true)
                return
            end
            ns.Player.MarkPumper(arg1)
        elseif cmd == "del" and arg1 then
            -- Check if trying to unmark yourself
            local playerName = GetUnitName("player", true)
            if arg1 == playerName or arg1 == GetUnitName("player", false) then
                ns.Core.DebugPrint("You cannot unmark yourself!", true)
                return
            end
            ns.Player.UnmarkPlayer(arg1)
        elseif cmd == "list" then
            ns.Core.DebugPrint("|cff39FF14Toxicify:|r Current list:", true)
            local players = ns.Player.GetAllPlayers()
            for name, data in pairs(players) do
                if type(data) == "table" then
                    -- New format with datetime
                    local statusColor = data.status == "toxic" and "|cffff0000" or "|cff00ff00"
                    ns.Core.DebugPrint(" - " .. statusColor .. name .. "|r (" .. data.status .. ") - " .. (data.datetime or "Unknown date"), true)
                else
                    -- Legacy format
                    local statusColor = data == "toxic" and "|cffff0000" or "|cff00ff00"
                    ns.Core.DebugPrint(" - " .. statusColor .. name .. "|r (" .. data .. ") - Legacy entry", true)
                end
            end
        elseif cmd == "ui" then
            if not _G.ToxicifyListFrame then ns.UI.CreateToxicifyUI() end
            if _G.ToxicifyListFrame:IsShown() then
                _G.ToxicifyListFrame:Hide()
            else
                _G.ToxicifyListFrame:Refresh()
                _G.ToxicifyListFrame:Show()
            end
        elseif cmd == "settings" or cmd == "config" or cmd == "s" or cmd == "c" then
            -- Sluit het huidige Toxicify dialoog als het open is
            if _G.ToxicifyListFrame and _G.ToxicifyListFrame:IsShown() then
                _G.ToxicifyListFrame:Hide()
            end
            
            -- Open de juiste settings en ga direct naar Toxicify tab
            if Settings and Settings.OpenToCategory then
                -- Retail (Dragonflight+) - gebruik de opgeslagen category referentie
                if _G.ToxicifySettingsCategory then
                    Settings.OpenToCategory(_G.ToxicifySettingsCategory:GetID())
                    ns.Core.DebugPrint("Opening Toxicify settings...", true)
                else
                    -- Fallback: probeer de category op te halen
                    local category = Settings.GetCategory("Toxicify")
                    if category then
                        Settings.OpenToCategory(category:GetID())
                        ns.Core.DebugPrint("Opening Toxicify settings (found category)...", true)
                    else
                        -- Laatste fallback: probeer de oude methode
                        Settings.OpenToCategory("Toxicify")
                        ns.Core.DebugPrint("Opening settings (fallback)...", true)
                    end
                end
            elseif InterfaceOptionsFrame_OpenToCategory then
                -- Classic/older versions - double call fixes Blizzard bug
                InterfaceOptionsFrame_OpenToCategory("Toxicify")
                C_Timer.After(0.1, function()
                    InterfaceOptionsFrame_OpenToCategory("Toxicify")
                end)
                ns.Core.DebugPrint("Opening Toxicify settings (Classic)...", true)
            else
                ns.Core.DebugPrint("Settings system not available", true)
            end
        elseif cmd == "debug" then
            if ToxicifyDB.DebugEnabled then
                ToxicifyDB.DebugEnabled = false
                ns.Core.DebugPrint("Debug mode disabled! Debug messages are now hidden.", true)
            else
                ToxicifyDB.DebugEnabled = true
                ns.Core.DebugPrint("Debug mode enabled! Debug messages will now show in main chat.", true)
            end
        elseif cmd == "clearonline" or cmd == "resetonline" then
            -- Clear online notification cache
            ns.Events.ClearOnlineNotificationCache()
            ns.Core.DebugPrint("Online notification cache cleared - notifications will show again for all players", true)
        elseif cmd == "notificationinterval" or cmd == "notifyinterval" then
            -- Show or set notification interval
            if arg1 then
                local minutes = tonumber(arg1)
                if minutes and minutes > 0 then
                    ToxicifyDB.NotificationIntervalMinutes = minutes
                    ns.Core.DebugPrint("Notification interval set to " .. minutes .. " minutes", true)
                else
                    ns.Core.DebugPrint("Error: Please specify a valid number of minutes. Use /toxic notificationinterval <minutes>", true)
                end
            else
                local interval = ToxicifyDB.NotificationIntervalMinutes or 10
                ns.Core.DebugPrint("Current notification interval: " .. interval .. " minutes", true)
                ns.Core.DebugPrint("Use /toxic notificationinterval <minutes> to change", true)
            end
        elseif cmd == "runstatus" or cmd == "runsuppress" then
            -- Show run suppression status
            if ns.Events and ns.Events.IsInActiveRun then
                local inRun = ns.Events.IsInActiveRun()
                local suppressWarnings = ns.Events.ShouldSuppressWarnings()
                
                ns.Core.DebugPrint("=== RUN STATUS ===", true)
                ns.Core.DebugPrint("In active run: " .. (inRun and "YES" or "NO"), true)
                ns.Core.DebugPrint("Warnings suppressed: " .. (suppressWarnings and "YES" or "NO"), true)
                ns.Core.DebugPrint("Suppress during runs setting: " .. (ToxicifyDB.SuppressWarningsDuringRuns and "ENABLED" or "DISABLED"), true)
                
                if ToxicifyDB.RunTracking then
                    ns.Core.DebugPrint("Run tracking data:", true)
                    ns.Core.DebugPrint("  - In key run: " .. (ToxicifyDB.RunTracking.inKeyRun and "YES" or "NO"), true)
                    ns.Core.DebugPrint("  - In dungeon: " .. (ToxicifyDB.RunTracking.inDungeon and "YES" or "NO"), true)
                    ns.Core.DebugPrint("  - In raid: " .. (ToxicifyDB.RunTracking.inRaid and "YES" or "NO"), true)
                    ns.Core.DebugPrint("  - Manual marking during run: " .. (ToxicifyDB.RunTracking.manualMarkingDuringRun and "YES" or "NO"), true)
                    if ToxicifyDB.RunTracking.lastManualMarkTime > 0 then
                        local timeSince = time() - ToxicifyDB.RunTracking.lastManualMarkTime
                        ns.Core.DebugPrint("  - Time since last manual mark: " .. timeSince .. " seconds", true)
                    end
                end
            else
                ns.Core.DebugPrint("Run tracking functions not available", true)
            end
        else
            ns.Core.DebugPrint("|cff39FF14Toxicify Commands:|r", true)
            ns.Core.DebugPrint("/toxic add <name-realm>        - Mark player as Toxic", true)
            ns.Core.DebugPrint("/toxic addpumper <name-realm>  - Mark player as Pumper", true)
            ns.Core.DebugPrint("/toxic del <name-realm>        - Remove player from list", true)
            ns.Core.DebugPrint("/toxic list                    - Show current list", true)
            ns.Core.DebugPrint("/toxic ui                      - Toggle Toxicify list window", true)
            ns.Core.DebugPrint("/toxic settings                - Open addon settings", true)
            ns.Core.DebugPrint("/toxic debug                   - Toggle debug mode", true)
            ns.Core.DebugPrint("/toxic clearonline             - Reset notification cache", true)
            ns.Core.DebugPrint("/toxic notificationinterval    - Set notification interval (minutes)", true)
            ns.Core.DebugPrint("/toxic runstatus               - Show run suppression status", true)
        end
    end
end