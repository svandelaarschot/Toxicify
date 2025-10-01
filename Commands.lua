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
            print("|cff39FF14Toxicify:|r Current list:")
            for name, status in pairs(ToxicifyDB) do
                if status then
                    print(" - " .. name .. " (" .. status .. ")")
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
        elseif cmd == "settings" or cmd == "config" then
            -- Sluit het huidige Toxicify dialoog als het open is
            if _G.ToxicifyListFrame and _G.ToxicifyListFrame:IsShown() then
                _G.ToxicifyListFrame:Hide()
            end
            
            -- Open de juiste settings
            if Settings and Settings.OpenToCategory then
                -- Retail (Dragonflight+)
                Settings.OpenToCategory("|cff39FF14Toxicify|r")
            elseif InterfaceOptionsFrame_OpenToCategory then
                -- Classic/older versions
                InterfaceOptionsFrame_OpenToCategory("|cff39FF14Toxicify|r")
                InterfaceOptionsFrame_OpenToCategory("|cff39FF14Toxicify|r") -- double call fixes Blizzard bug
            else
                -- Fallback: open interface options
                InterfaceOptionsFrame:Show()
                print("|cff39FF14Toxicify:|r Please navigate to the Toxicify section in Interface Options.")
            end
        elseif cmd == "debug" then
            if ToxicifyDB.DebugEnabled then
                ToxicifyDB.DebugEnabled = false
                print("|cff39FF14Toxicify:|r Debug mode disabled.")
                print("|cffaaaaaaLua errors toggle is now hidden in settings.|r")
            else
                ToxicifyDB.DebugEnabled = true
                print("|cff39FF14Toxicify:|r Debug mode enabled! All debug messages will show in main chat with [DEBUG] prefix.")
                print("|cffaaaaaaDebug messages will appear when you use Toxicify features.|r")
                print("|cffaaaaaaLua errors toggle is now visible in settings.|r")
            end
        elseif cmd == "partywarning" then
            if ToxicifyDB.PartyWarningEnabled then
                ToxicifyDB.PartyWarningEnabled = false
                print("|cff39FF14Toxicify:|r Party warning disabled.")
            else
                ToxicifyDB.PartyWarningEnabled = true
                print("|cff39FF14Toxicify:|r Party warning enabled.")
            end
        elseif cmd == "luaerrors" then
            if not ToxicifyDB.DebugEnabled then
                print("|cffff0000Toxicify:|r Debug mode must be enabled first. Use /toxic debug")
                return
            end
            if ToxicifyDB.LuaErrorsEnabled then
                ToxicifyDB.LuaErrorsEnabled = false
                SetCVar("scriptErrors", "0")
                print("|cff39FF14Toxicify:|r Lua errors disabled - /console scriptErrors set to 0")
            else
                ToxicifyDB.LuaErrorsEnabled = true
                SetCVar("scriptErrors", "1")
                print("|cff39FF14Toxicify:|r Lua errors enabled - /console scriptErrors set to 1")
            end
        elseif cmd == "contextmenu" then
            if ns.UI and ns.UI.AddContextMenuMarking then
                ns.UI.AddContextMenuMarking()
                print("|cff39FF14Toxicify:|r Context menu marking activated.")
            else
                print("|cffff0000Toxicify:|r Context menu marking not available.")
            end
        elseif cmd == "testwarning" then
            -- Show warning popup for testing
            local testToxicPlayers = {"TestPlayer-Realm1", "AnotherToxic-Realm2"}
            ns.Events.ShowToxicWarningPopup(testToxicPlayers)
            print("|cff39FF14Toxicify:|r Test warning popup shown.")
        else
            print("|cff39FF14Toxicify Commands:|r")
            print("/toxic add <name-realm>        - Mark player as Toxic")
            print("/toxic addpumper <name-realm>  - Mark player as Pumper")
            print("/toxic del <name-realm>        - Remove player from list")
            print("/toxic list                    - Show current list")
            print("/toxic export                  - Export list (string)")
            print("/toxic import <string>         - Import list from string")
            print("/toxic ui                      - Toggle Toxicify list window")
            print("/toxic settings                - Open addon settings")
            print("/toxic config                  - Open addon settings (alias)")
            print("/toxic debug                   - Toggle debug mode (shows in main chat)")
            print("/toxic partywarning            - Toggle party warning")
            print("/toxic luaerrors               - Toggle Lua errors (requires debug mode)")
            print("/toxic contextmenu              - Activate context menu marking")
            print("/toxic testwarning              - Show test warning popup")
        end
    end
end
