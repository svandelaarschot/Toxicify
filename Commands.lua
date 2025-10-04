-- Commands.lua - Slash command functionality
local addonName, ns = ...

-- Commands namespace
ns.Commands = {}

-- Initialize Commands module
function ns.Commands.Initialize()
    SLASH_TOXICIFY1 = "/toxic"
    SlashCmdList["TOXICIFY"] = function(msg)
        local cmd, arg1, arg2 = strsplit(" ", msg, 3)
        cmd = string.lower(cmd or "")

        if cmd == "add" and arg1 then
            ns.Player.MarkToxic(arg1)
        elseif cmd == "addpumper" and arg1 then
            ns.Player.MarkPumper(arg1)
        elseif cmd == "del" and arg1 then
            ns.Player.UnmarkToxic(arg1)
        elseif cmd == "list" then
            ns.Core.DebugPrint("|cff39FF14Toxicify:|r Current list:", true)
            for name, status in pairs(ToxicifyDB) do
                if status then
                    ns.Core.DebugPrint(" - " .. name .. " (" .. status .. ")", true)
                end
            end
        elseif cmd == "export" then
            ns.UI.ShowIOPopup("export")
        elseif cmd == "import" then
            ns.UI.ShowIOPopup("import")
        elseif cmd == "ui" then
            if not _G.ToxicifyListFrame then ns.UI.CreateToxicifyUI() end
            if _G.ToxicifyListFrame:IsShown() then
                _G.ToxicifyListFrame:Hide()
            else
                _G.ToxicifyListFrame:Refresh()
                _G.ToxicifyListFrame:Show()
            end
        elseif cmd == "testwarning" or cmd == "testpopup" then
            -- Test the warning popup
            local testPlayers = {"TestPlayer1", "TestPlayer2"}
            if ns.Events and ns.Events.ShowToxicWarningPopup then
                ns.Events.ShowToxicWarningPopup(testPlayers)
            end
        elseif cmd == "testtoast" or cmd == "testguildtoast" then
            -- Test the guild toast notification
            if ns.Events and ns.Events.ShowGuildToast then
                ns.Events.ShowGuildToast("TestPlayer", "toxic")
            end
        
        elseif cmd == "guildtoast" then
            if ToxicifyDB.GuildToastEnabled then
                ToxicifyDB.GuildToastEnabled = false
                ns.Core.DebugPrint("Toxicify: Guild toast notifications disabled")
            else
                ToxicifyDB.GuildToastEnabled = true
                ns.Core.DebugPrint("Toxicify: Guild toast notifications enabled", true)
            end
        
        elseif cmd == "settings" or cmd == "config" then
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
                ns.Core.DebugPrint("Opening settings...", true)
            else
                -- Fallback: open interface options
                if SettingsPanel then
                    SettingsPanel:Show()
                    ns.Core.DebugPrint("Please navigate to the Toxicify section in Settings.")
                elseif InterfaceOptionsFrame then
                    InterfaceOptionsFrame:Show()
                    ns.Core.DebugPrint("Please navigate to the Toxicify section in Interface Options.")
                else
                    ns.Core.DebugPrint("Could not open settings. Please use the Game Menu > Options > AddOns.")
                end
            end
        elseif cmd == "debug" then
            if ToxicifyDB.DebugEnabled then
                ToxicifyDB.DebugEnabled = false
                ns.Core.DebugPrint("Debug mode disabled! Debug messages are now hidden.", true)
                ns.Core.DebugPrint("Lua errors toggle is now hidden in settings.", true)
            else
                ToxicifyDB.DebugEnabled = true
                ns.Core.DebugPrint("Debug mode enabled! All debug messages will show in main chat with [DEBUG] prefix.", true)
                ns.Core.DebugPrint("Debug messages will appear when you use Toxicify features.", true)
                ns.Core.DebugPrint("Lua errors toggle is now visible in settings.", true)
            end
        elseif cmd == "partywarning" then
            if ToxicifyDB.PartyWarningEnabled then
                ToxicifyDB.PartyWarningEnabled = false
                ns.Core.DebugPrint("Party warning disabled.", true)
            else
                ToxicifyDB.PartyWarningEnabled = true
                ns.Core.DebugPrint("Party warning enabled.", true)
            end
        elseif cmd == "luaerrors" then
            if not ToxicifyDB.DebugEnabled then
                ns.Core.DebugPrint("Debug mode must be enabled first. Use /toxic debug", true)
                return
            end
            if ToxicifyDB.LuaErrorsEnabled then
                ToxicifyDB.LuaErrorsEnabled = false
                SetCVar("scriptErrors", "0")
                ns.Core.DebugPrint("Lua errors disabled - /console scriptErrors set to 0", true)
            else
                ToxicifyDB.LuaErrorsEnabled = true
                SetCVar("scriptErrors", "1")
                ns.Core.DebugPrint("Lua errors enabled - /console scriptErrors set to 1", true)
            end
        elseif cmd == "testwarning" then
            -- Show warning popup with real online marked players
            local onlineMarkedPlayers = {}
            
            -- Check guild members
            local numGuildMembers = GetNumGuildMembers()
            if numGuildMembers > 0 then
                for i = 1, numGuildMembers do
                    local name, rank, rankIndex, level, class, zone, note, officernote, online, status, classFileName, achievementPoints, achievementRank, isMobile, canSoR, repStanding, guid = GetGuildRosterInfo(i)
                    if name and online then
                        local fullName = name .. "-" .. GetRealmName()
                        if ns.Player.IsToxic(fullName) or ns.Player.IsPumper(fullName) then
                            table.insert(onlineMarkedPlayers, name)
                        end
                    end
                end
            end
            
            -- Check friends
            local numFriends = C_FriendList.GetNumFriends()
            if numFriends > 0 then
                for i = 1, numFriends do
                    local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
                    if friendInfo and friendInfo.connected then
                        local name = friendInfo.name
                        if name then
                            local fullName = name .. "-" .. GetRealmName()
                            if (ns.Player.IsToxic(fullName) or ns.Player.IsPumper(fullName)) and not tContains(onlineMarkedPlayers, name) then
                                table.insert(onlineMarkedPlayers, name)
                            end
                        end
                    end
                end
            end
            
            -- Check group members
            if IsInGroup() then
                for i = 1, GetNumGroupMembers() do
                    local unit = (IsInRaid() and "raid"..i) or (i == GetNumGroupMembers() and "player" or "party"..i)
                    if UnitExists(unit) then
                        local name = GetUnitName(unit, true)
                        if name and (ns.Player.IsToxic(name) or ns.Player.IsPumper(name)) and not tContains(onlineMarkedPlayers, name) then
                            table.insert(onlineMarkedPlayers, name)
                        end
                    end
                end
            end
            
            if #onlineMarkedPlayers > 0 then
                ns.Events.ShowToxicWarningPopup(onlineMarkedPlayers)
                ns.Core.DebugPrint("Test warning popup shown with " .. #onlineMarkedPlayers .. " real online marked players: " .. table.concat(onlineMarkedPlayers, ", "), true)
            else
                ns.Core.DebugPrint("No marked players are currently online to test with.", true)
                ns.Core.DebugPrint("Make sure you have marked players in your guild, friends list, or current group.", true)
            end
        elseif cmd == "clearwarnings" then
            ns.Events.ClearWarningCache()
            ns.Core.DebugPrint("Warning cache cleared - warnings will show again for all players", true)
        elseif cmd == "checkonline" or cmd == "scanonline" then
            -- Manually trigger online detection
            ns.Core.DebugPrint("Scanning for online marked players...", true)
            ns.Events.CheckGuildMemberOnline()
            ns.Events.CheckFriendListOnline()
            ns.Events.CheckGroupForMarkedPlayers()
            ns.Core.DebugPrint("Online scan completed.", true)
        else
            ns.Core.DebugPrint("|cff39FF14Toxicify Commands:|r", true)
            ns.Core.DebugPrint("/toxic add <name-realm>        - Mark player as Toxic", true)
            ns.Core.DebugPrint("/toxic addpumper <name-realm>  - Mark player as Pumper", true)
            ns.Core.DebugPrint("/toxic del <name-realm>        - Remove player from list", true)
            ns.Core.DebugPrint("/toxic list                    - Show current list", true)
            ns.Core.DebugPrint("/toxic export                  - Export list (string)", true)
            ns.Core.DebugPrint("/toxic import <string>         - Import list from string", true)
            ns.Core.DebugPrint("/toxic ui                      - Toggle Toxicify list window", true)
            ns.Core.DebugPrint("/toxic settings                - Open addon settings", true)
            ns.Core.DebugPrint("/toxic config                  - Open addon settings (alias)", true)
            ns.Core.DebugPrint("/toxic debug                   - Toggle debug mode (shows in main chat)", true)
            ns.Core.DebugPrint("/toxic partywarning            - Toggle party warning", true)
            ns.Core.DebugPrint("/toxic clearwarnings           - Reset warning cache (show warnings again)", true)
            ns.Core.DebugPrint("/toxic checkonline             - Manually scan for online marked players", true)
            ns.Core.DebugPrint("/toxic luaerrors               - Toggle Lua errors (requires debug mode)", true)
            ns.Core.DebugPrint("/toxic contextmenu             - Activate context menu marking", true)
        end
    end
end
