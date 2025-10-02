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
        elseif cmd == "testguild" then
            -- Test guild roster hook
            if GuildRosterFrame then
                local selection = GetGuildRosterSelection()
                if selection and selection > 0 then
                    local name = GetGuildRosterInfo(selection)
                end
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
                ns.Core.DebugPrint("Lua errors toggle is now hidden in settings")
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
        elseif cmd == "contextmenu" then
            if ns.UI and ns.UI.AddContextMenuMarking then
                ns.UI.AddContextMenuMarking()
                ns.Core.DebugPrint("Context menu marking activated.", true)
            else
                ns.Core.DebugPrint("Context menu marking not available.", true)
            end
        elseif cmd == "testwarning" then
            -- Show warning popup for testing
            local testToxicPlayers = {"TestPlayer-Realm1", "AnotherToxic-Realm2"}
            ns.Events.ShowToxicWarningPopup(testToxicPlayers)
            ns.Core.DebugPrint("Test warning popup shown.", true)
        elseif cmd == "testclipboard" then
            -- Test clipboard functionality
            print("|cff39FF14Toxicify:|r Testing clipboard functionality...")
            local testData = "TX:VGVzdERhdGE="
            print("Copying test data: " .. testData)
            if ns.Core.CopyToClipboard(testData) then
                print("✓ Copy successful")
                local retrieved = ns.Core.GetFromClipboard()
                if retrieved == testData then
                    print("✓ Clipboard test passed!")
                else
                    print("✗ Retrieved data doesn't match: " .. (retrieved or "nil"))
                end
            else
                print("✗ Copy failed")
            end
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
            ns.Core.DebugPrint("/toxic luaerrors               - Toggle Lua errors (requires debug mode)", true)
            ns.Core.DebugPrint("/toxic contextmenu             - Activate context menu marking", true)
            ns.Core.DebugPrint("/toxic testwarning             - Show test warning popup", true)
            ns.Core.DebugPrint("/toxic testclipboard           - Test clipboard functionality", true)
        end
    end
end
