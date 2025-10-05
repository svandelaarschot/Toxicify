-- UI.lua - User interface functionality
local addonName, ns = ...

-- UI namespace
ns.UI = {}

-- Initialize UI module
function ns.UI.Initialize()
    -- UI initialization if needed
end

-- Get unit frame for a unit
function ns.UI.GetUnitFrame(unit)
    -- Try modern compact unit frames first
    if C_CompactUnitFrame and C_CompactUnitFrame.GetAllFrames then
        for _, frame in ipairs(C_CompactUnitFrame.GetAllFrames()) do
            if frame and frame.unit == unit then
                ns.Core.DebugPrint("Found compact frame for " .. unit)
                return frame
            end
        end
    else
        ns.Core.DebugPrint("C_CompactUnitFrame API not available, trying fallback methods")
    end
    
    -- Fallback: Try traditional party frames
    if unit == "player" then
        -- For player, try to find any player frame
        local playerFrame = _G["PlayerFrame"]
        if playerFrame then
            ns.Core.DebugPrint("Found PlayerFrame for " .. unit)
            return playerFrame
        end
    elseif unit:match("^party") then
        -- For party members, try PartyMemberFrame1-4
        local partyNum = unit:match("party(%d+)")
        if partyNum then
            local frameName = "PartyMemberFrame" .. partyNum
            local frame = _G[frameName]
            if frame then
                ns.Core.DebugPrint("Found " .. frameName .. " for " .. unit)
                return frame
            end
            
            -- Also try CompactPartyFrameMember
            frameName = "CompactPartyFrameMember" .. partyNum
            frame = _G[frameName]
            if frame then
                ns.Core.DebugPrint("Found " .. frameName .. " for " .. unit)
                return frame
            end
        end
    elseif unit:match("^raid") then
        -- For raid members, try CompactRaidFrame1-40
        local raidNum = unit:match("raid(%d+)")
        if raidNum then
            local frameName = "CompactRaidFrame" .. raidNum
            local frame = _G[frameName]
            if frame then
                ns.Core.DebugPrint("Found " .. frameName .. " for " .. unit)
                return frame
            end
        end
    end

    ns.Core.DebugPrint("No frame found for " .. unit .. " using any method")
    return nil
end

-- Create the main Toxicify UI
function ns.UI.CreateToxicifyUI()
    if _G.ToxicifyListFrame then return end

    local f = CreateFrame("Frame", "ToxicifyListFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
    f:SetSize(800, 650)
    f:SetPoint("CENTER")
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 16,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    f:Hide()

    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetClampedToScreen(true)
    f:SetFrameStrata("DIALOG")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetScript("OnShow", function(self)
        if self.Refresh then
            self:Refresh()
        end
    end)
    
    -- Title
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -15)
    title:SetText("|cff39FF14Toxicify List|r")

    -- Close button
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    -- Player label
    local playerLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    playerLabel:SetPoint("TOPLEFT", 20, -50)
    playerLabel:SetText("Player:")

    -- Add box
    local addBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    addBox:SetSize(220, 22)
    addBox:SetPoint("LEFT", playerLabel, "RIGHT", 10, 0)
    addBox:SetAutoFocus(false)

    -- First row of buttons (3 buttons)
    -- Add Toxic button
    local addToxicBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    addToxicBtn:SetSize(120, 22)
    addToxicBtn:SetPoint("LEFT", addBox, "RIGHT", 20, 0)
    addToxicBtn:SetText("Add Toxic")

    -- Add Pumper button
    local addPumperBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    addPumperBtn:SetSize(120, 22)
    addPumperBtn:SetPoint("LEFT", addToxicBtn, "RIGHT", 10, 0)
    addPumperBtn:SetText("Add Pumper")

    -- Remove all button
    local clearBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    clearBtn:SetSize(120, 22)
    clearBtn:SetPoint("LEFT", addPumperBtn, "RIGHT", 10, 0)
    clearBtn:SetText("Remove All")

    -- Second row of buttons (3 buttons) - positioned below the first row
    -- Clear by date button
    local clearDateBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    clearDateBtn:SetSize(120, 22)
    clearDateBtn:SetPoint("LEFT", addToxicBtn, "LEFT", 0, -30)
    clearDateBtn:SetText("Clear by Date")

    -- Manage ignore list button
    local manageIgnoreBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    manageIgnoreBtn:SetSize(120, 22)
    manageIgnoreBtn:SetPoint("LEFT", clearDateBtn, "RIGHT", 10, 0)
    manageIgnoreBtn:SetText("Manage Ignore")

    -- Settings button next to Manage Ignore
    local settingsBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    settingsBtn:SetSize(120, 22)
    settingsBtn:SetPoint("LEFT", manageIgnoreBtn, "RIGHT", 10, 0)
    settingsBtn:SetText("Settings")
    settingsBtn:SetScript("OnClick", function() 
        -- Sluit het huidige dialoog
        f:Hide()
        
        -- Open de juiste settings
        if Settings and Settings.GetCategory and Settings.OpenToCategory then
            -- Retail (Dragonflight+) - use the stored global reference
            local category = _G.ToxicifySettingsCategory or Settings.GetCategory("Toxicify")
            if category then
                Settings.OpenToCategory(category:GetID())
                ns.Core.DebugPrint("Opening Toxicify settings panel (Retail)")
            else
                ns.Core.DebugPrint("Settings category not found")
                InterfaceOptionsFrame:Show()
            end
        elseif InterfaceOptionsFrame_OpenToCategory then
            -- Classic/older versions
            InterfaceOptionsFrame_OpenToCategory("Toxicify")
            InterfaceOptionsFrame_OpenToCategory("Toxicify") -- double call fixes Blizzard bug
            ns.Core.DebugPrint("Opening Toxicify settings panel (Classic)")
        else
            -- Fallback: open interface options
            InterfaceOptionsFrame:Show()
            ns.Core.DebugPrint("Fallback: Opening interface options")
        end
    end)

    -- Auto-completion using shared functionality
    local suggestionBox = ns.Core.CreateAutoCompletion(addBox, f)

    -- Search row (moved up to be right below buttons)
    local searchLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    searchLabel:SetPoint("TOPLEFT", addBox, "BOTTOMLEFT", 0, -110)
    searchLabel:SetText("Search:")

    local searchBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    searchBox:SetSize(250, 22)
    searchBox:SetPoint("LEFT", searchLabel, "RIGHT", 10, 0)
    searchBox:SetAutoFocus(false)
    searchBox:SetScript("OnTextChanged", function(self) f:Refresh() end)

    -- List (increased height)
    local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", searchLabel, "BOTTOMLEFT", 0, -10)
    scroll:SetPoint("BOTTOMRIGHT", -30, 40)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(760, 450)
    scroll:SetScrollChild(content)

    -- Filter toxic groups checkbox (moved to bottom left)
    local hideToxicCheck = CreateFrame("CheckButton", nil, f, "InterfaceOptionsCheckButtonTemplate")
    hideToxicCheck:SetPoint("BOTTOMLEFT", 20, 50)
    hideToxicCheck.Text:SetText("Hide toxic groups in Premade Groups")
    hideToxicCheck:SetChecked(ToxicifyDB.HideInFinder or false)
    hideToxicCheck:SetScript("OnClick", function(self)
        ToxicifyDB.HideInFinder = self:GetChecked()
        if LFGListFrame and LFGListFrame.SearchPanel then
            LFGListSearchPanel_UpdateResultList(LFGListFrame.SearchPanel)
        end
    end)

    local function Refresh()
        ns.UI.RefreshSharedList(content, searchBox:GetText():lower())
        -- Force content to be visible
        content:Show()
        scroll:Show()
        scroll:UpdateScrollChildRect()
        scroll:SetVerticalScroll(0)
    end
    f.Refresh = Refresh
    
    -- Store reference to this frame for external refresh
    ns.UI.ToxicUIFrame = f

    -- Buttons logic
    addToxicBtn:SetScript("OnClick", function()
        local name = addBox:GetText()
        if name and name ~= "" then
            -- Check if trying to mark yourself
            local playerName = GetUnitName("player", true)
            local playerShortName = GetUnitName("player", false)
            if name == playerName or name == playerShortName then
                print("|cffff0000Toxicify:|r You cannot mark yourself as toxic!")
            else
                ns.Player.MarkToxic(name)
                addBox:SetText("")
                suggestionBox:Hide()
                Refresh()
                -- Force refresh after a small delay
                C_Timer.After(0.1, function() Refresh() end)
            end
        end
    end)

    addPumperBtn:SetScript("OnClick", function()
        local name = addBox:GetText()
        if name and name ~= "" then
            -- Check if trying to mark yourself
            local playerName = GetUnitName("player", true)
            local playerShortName = GetUnitName("player", false)
            if name == playerName or name == playerShortName then
                print("|cffff0000Toxicify:|r You cannot mark yourself as pumper!")
            else
                ns.Player.MarkPumper(name)
                addBox:SetText("")
                suggestionBox:Hide()
                Refresh()
                -- Force refresh after a small delay
                C_Timer.After(0.1, function() Refresh() end)
            end
        end
    end)

    clearBtn:SetScript("OnClick", function()
        ns.Player.ClearAllPlayers()
        Refresh()
    end)

    -- Clear by date button script
    clearDateBtn:SetScript("OnClick", function()
        -- Create a simple input dialog for date
        local inputFrame = CreateFrame("Frame", nil, UIParent, BackdropTemplateMixin and "BackdropTemplate")
        inputFrame:SetSize(400, 200)
        inputFrame:SetPoint("CENTER")
        inputFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 16,
            insets = { left = 8, right = 8, top = 8, bottom = 8 }
        })
        inputFrame:SetFrameStrata("DIALOG")
        inputFrame:SetFrameLevel(100)
        inputFrame:EnableMouse(true)
        inputFrame:SetMovable(true)
        inputFrame:RegisterForDrag("LeftButton")
        inputFrame:SetScript("OnDragStart", inputFrame.StartMoving)
        inputFrame:SetScript("OnDragStop", inputFrame.StopMovingOrSizing)

        -- Title
        local title = inputFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, -15)
        title:SetText("Clear Players by Date")

        -- Close button
        local closeBtn = CreateFrame("Button", nil, inputFrame, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", inputFrame, "TOPRIGHT", -5, -5)

        -- Instructions
        local instructions = inputFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        instructions:SetPoint("TOP", title, "BOTTOM", 0, -20)
        instructions:SetText("Enter date to clear players older than this date:")
        instructions:SetJustifyH("CENTER")

        -- Date input
        local dateInput = CreateFrame("EditBox", nil, inputFrame, "InputBoxTemplate")
        dateInput:SetSize(200, 30)
        dateInput:SetPoint("TOP", instructions, "BOTTOM", 0, -20)
        dateInput:SetAutoFocus(true)
        dateInput:SetText("YYYY-MM-DD")

        -- Buttons
        local clearBtn = CreateFrame("Button", nil, inputFrame, "UIPanelButtonTemplate")
        clearBtn:SetSize(100, 30)
        clearBtn:SetPoint("BOTTOMLEFT", 50, 20)
        clearBtn:SetText("Clear")
        clearBtn:SetScript("OnClick", function()
            local dateStr = dateInput:GetText()
            if dateStr and dateStr ~= "YYYY-MM-DD" then
                ns.Player.ClearPlayersByDate(dateStr)
                Refresh()
                inputFrame:Hide()
            else
                print("|cffff0000Toxicify:|r Please enter a valid date (YYYY-MM-DD)")
            end
        end)

        local cancelBtn = CreateFrame("Button", nil, inputFrame, "UIPanelButtonTemplate")
        cancelBtn:SetSize(100, 30)
        cancelBtn:SetPoint("BOTTOMRIGHT", -50, 20)
        cancelBtn:SetText("Cancel")
        cancelBtn:SetScript("OnClick", function()
            inputFrame:Hide()
        end)

        closeBtn:SetScript("OnClick", function()
            inputFrame:Hide()
        end)

        inputFrame:Show()
    end)

    -- Manage ignore list button script
    manageIgnoreBtn:SetScript("OnClick", function()
        -- Create ignore list management dialog
        local ignoreFrame = CreateFrame("Frame", nil, UIParent, BackdropTemplateMixin and "BackdropTemplate")
        ignoreFrame:SetSize(500, 400)
        ignoreFrame:SetPoint("CENTER")
        ignoreFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 16,
            insets = { left = 8, right = 8, top = 8, bottom = 8 }
        })
        ignoreFrame:SetFrameStrata("DIALOG")
        ignoreFrame:SetFrameLevel(100)
        ignoreFrame:EnableMouse(true)
        ignoreFrame:SetMovable(true)
        ignoreFrame:RegisterForDrag("LeftButton")
        ignoreFrame:SetScript("OnDragStart", ignoreFrame.StartMoving)
        ignoreFrame:SetScript("OnDragStop", ignoreFrame.StopMovingOrSizing)

        -- Title
        local title = ignoreFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, -15)
        title:SetText("Ignore List Management")

        -- Close button
        local closeBtn = CreateFrame("Button", nil, ignoreFrame, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", ignoreFrame, "TOPRIGHT", -5, -5)

        -- Info text
        local count = ns.Player.GetIgnoreListCount()
        local capacity = ns.Player.GetIgnoreListCapacity()
        local isFull = ns.Player.IsIgnoreListFull()
        local statusColor = isFull and "|cffff0000" or "|cff00ff00"
        
        local infoText = ignoreFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        infoText:SetPoint("TOP", title, "BOTTOM", 0, -20)
        infoText:SetText("Current: " .. count .. " / " .. capacity .. " (" .. statusColor .. (isFull and "FULL" or "Available") .. "|r)")
        infoText:SetJustifyH("CENTER")

        -- Scroll frame for ignore list
        local scrollFrame = CreateFrame("ScrollFrame", nil, ignoreFrame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOP", infoText, "BOTTOM", 0, -20)
        scrollFrame:SetSize(450, 250)

        local content = CreateFrame("Frame", nil, scrollFrame)
        content:SetSize(450, 250)
        scrollFrame:SetScrollChild(content)

        -- Populate ignore list
        local y = -10
        local ignoreEntries = {}
        for i = 1, count do
            local name = C_FriendList.GetIgnoreName(i)
            if name then
                local entry = CreateFrame("Frame", nil, content)
                entry:SetSize(430, 20)
                entry:SetPoint("TOPLEFT", 10, y)
                
                local nameLabel = entry:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                nameLabel:SetPoint("LEFT", 0, 0)
                nameLabel:SetText(name)
                
                local removeBtn = CreateFrame("Button", nil, entry, "UIPanelButtonTemplate")
                removeBtn:SetSize(60, 20)
                removeBtn:SetPoint("RIGHT", 0, 0)
                removeBtn:SetText("Remove")
                removeBtn:SetScript("OnClick", function()
                    C_FriendList.DelIgnore(name)
                    ignoreFrame:Hide()
                    manageIgnoreBtn:GetScript("OnClick")() -- Refresh the dialog
                end)
                
                table.insert(ignoreEntries, entry)
                y = y - 25
            end
        end

        -- Buttons
        local clearOldestBtn = CreateFrame("Button", nil, ignoreFrame, "UIPanelButtonTemplate")
        clearOldestBtn:SetSize(120, 30)
        clearOldestBtn:SetPoint("BOTTOMLEFT", 50, 20)
        clearOldestBtn:SetText("Clear Oldest 20")
        clearOldestBtn:SetScript("OnClick", function()
            local removedCount = ns.Player.ClearOldestIgnoreEntries(20)
            if removedCount > 0 then
                print("|cffaaaaaaToxicify:|r Removed " .. removedCount .. " oldest ignore entries.")
                ignoreFrame:Hide()
                manageIgnoreBtn:GetScript("OnClick")() -- Refresh the dialog
            end
        end)

        local manageBtn = CreateFrame("Button", nil, ignoreFrame, "UIPanelButtonTemplate")
        manageBtn:SetSize(100, 30)
        manageBtn:SetPoint("BOTTOM", 0, 20)
        manageBtn:SetText("Auto Manage")
        manageBtn:SetScript("OnClick", function()
            ns.Player.ManageIgnoreListCapacity()
            ignoreFrame:Hide()
            manageIgnoreBtn:GetScript("OnClick")() -- Refresh the dialog
        end)

        local closeDialogBtn = CreateFrame("Button", nil, ignoreFrame, "UIPanelButtonTemplate")
        closeDialogBtn:SetSize(100, 30)
        closeDialogBtn:SetPoint("BOTTOMRIGHT", -50, 20)
        closeDialogBtn:SetText("Close")
        closeDialogBtn:SetScript("OnClick", function()
            ignoreFrame:Hide()
        end)

        closeBtn:SetScript("OnClick", function()
            ignoreFrame:Hide()
        end)

        ignoreFrame:Show()
    end)

    -- ReloadUI button (positioned at bottom right)
    local reloadBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    reloadBtn:SetSize(80, 22)
    reloadBtn:SetPoint("BOTTOMRIGHT", -20, 15)
    reloadBtn:SetText("ReloadUI")
    reloadBtn:SetScript("OnClick", function() ReloadUI() end)

    -- Footer
    local footer = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    footer:SetPoint("BOTTOMLEFT", 20, 20)
    footer:SetText(ns.Core.GetFooterText())
end

-- Refresh the shared list
function ns.UI.RefreshSharedList(content, filterText)
    -- Return early if content is nil (called from Player.lua without parameters)
    if not content then
        return
    end
    
    for _, child in ipairs(content.children or {}) do child:Hide() end
    content.children = {}

    filterText = filterText and filterText:lower() or ""

    local y = -5
    local count = 0
    local players = ns.Player.GetAllPlayers()
    for name, data in pairs(players) do
        local status = type(data) == "table" and data.status or data
        if (status == "toxic" or status == "pumper") 
           and (filterText == "" or name:lower():find(filterText, 1, true)) then

            local row = CreateFrame("Frame", nil, content)
            row:SetSize(760, 26)
            row:SetPoint("TOPLEFT", 0, y)

            -- Icon
            local icon = row:CreateTexture(nil, "ARTWORK")
            icon:SetSize(16, 16)
            icon:SetPoint("LEFT", 0, 0)

            -- Editable name field
            local nameBox = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
            nameBox:SetSize(200, 22)
            nameBox:SetPoint("LEFT", icon, "RIGHT", 6, 0)
            nameBox:SetAutoFocus(false)
            nameBox:SetText(name)
            
            -- Force text to be visible immediately
            nameBox:SetFontObject("GameFontNormal")
            nameBox:SetCursorPosition(0)
            nameBox:ClearFocus()
            
            -- Set initial color based on status
            if status == "toxic" then
                nameBox:SetTextColor(1, 0, 0) -- rood
            else
                nameBox:SetTextColor(0, 1, 0) -- groen
            end

            -- Date/time label
            local dateLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            dateLabel:SetPoint("LEFT", nameBox, "RIGHT", 10, 0)
            dateLabel:SetSize(150, 20)
            if type(data) == "table" and data.datetime then
                dateLabel:SetText(data.datetime)
                dateLabel:SetTextColor(0.7, 0.7, 0.7)
            else
                dateLabel:SetText("Legacy entry")
                dateLabel:SetTextColor(0.5, 0.5, 0.5)
            end

            -- Dropdown
            local drop = CreateFrame("Frame", nil, row, "UIDropDownMenuTemplate")
            drop:SetPoint("LEFT", dateLabel, "RIGHT", 10, -3)
            UIDropDownMenu_SetWidth(drop, 100)

            local function UpdateVisual()
                local currentStatus = ns.Player.GetPlayerStatus(name)
                if currentStatus == "toxic" then
                    icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_8")
                    nameBox:SetTextColor(1, 0, 0) -- rood
                else
                    icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_2")
                    nameBox:SetTextColor(0, 1, 0) -- groen
                end
                -- Zorg dat de tekst zichtbaar is
                nameBox:SetText(name)
                nameBox:SetCursorPosition(0)
                -- nameBox:HighlightText(0, -1) -- Removed highlight
                nameBox:ClearFocus()
            end

            UIDropDownMenu_Initialize(drop, function(self, level)
                local info = UIDropDownMenu_CreateInfo()

                info.text = "Toxic"
                info.func = function()
                    ns.Player.MarkToxic(name)
                    UpdateVisual()
                    -- Update list immediately after status change
                    ns.UI.RefreshSharedList(content, filterText)
                end
                UIDropDownMenu_AddButton(info)

                info.text = "Pumper"
                info.func = function()
                    ns.Player.MarkPumper(name)
                    UpdateVisual()
                    -- Update list immediately after status change
                    ns.UI.RefreshSharedList(content, filterText)
                end
                UIDropDownMenu_AddButton(info)
            end)

            UIDropDownMenu_SetText(drop, status == "toxic" and "Toxic" or "Pumper")
            UpdateVisual()

            -- Auto-save on focus loss
            nameBox:SetScript("OnEditFocusLost", function(self)
                local newName = ns.Player.NormalizePlayerName(self:GetText())
                if newName and newName ~= name then
                    local playerData = ns.Player.GetPlayerData(name)
                    if playerData then
                        -- Remove old entry
                        ns.Player.UnmarkToxic(name)
                        -- Add new entry with same data
                        if playerData.status == "toxic" then
                            ns.Player.MarkToxic(newName)
                        elseif playerData.status == "pumper" then
                            ns.Player.MarkPumper(newName)
                        end
                        name = newName
                    end
                    
                    -- Update list after name change
                    ns.UI.RefreshSharedList(content, filterText)
                end
            end)
            
            -- Keep text visible with correct color during typing
            nameBox:SetScript("OnTextChanged", function(self)
                self:SetFontObject("GameFontNormal")
                local currentStatus = ns.Player.GetPlayerStatus(name)
                if currentStatus == "toxic" then
                    self:SetTextColor(1, 0, 0) -- rood
                else
                    self:SetTextColor(0, 1, 0) -- groen
                end
            end)

            -- Delete button
            local del = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            del:SetSize(80, 28)
            del:SetPoint("LEFT", drop, "RIGHT", 2, 3)
            del:SetText("Delete")
            del:SetScript("OnClick", function()
                ns.Player.UnmarkToxic(name)
                ns.UI.RefreshSharedList(content, filterText)
            end)

            table.insert(content.children, row)
            y = y - 28
            count = count + 1
        end
    end
    
    -- Force all children to be visible
    for _, child in ipairs(content.children or {}) do 
        child:Show() 
    end
end

-- Trigger refresh for toxic UI
function ns.UI.TriggerRefresh()
    if ns.UI.ToxicUIFrame and ns.UI.ToxicUIFrame.Refresh then
        ns.UI.ToxicUIFrame:Refresh()
    end
end

-- Add toxic marking to context menu (now handled in Events.lua)
function ns.UI.AddContextMenuMarking()
    -- Context menu functionality moved to Events.lua using Menu API
end

-- Show Import/Export popup
function ns.UI.ShowIOPopup(mode)
    if not _G.ToxicifyIOFrame then
        local f = CreateFrame("Frame", "ToxicifyIOFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
        f:SetSize(550, 350)
        f:SetPoint("CENTER")
        f:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 16,
            insets = { left = 8, right = 8, top = 8, bottom = 8 }
        })
        f:SetFrameStrata("DIALOG")
        f:SetFrameLevel(100)
        f:EnableMouse(true)  -- Capture mouse events
        f:SetMovable(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop", f.StopMovingOrSizing)
        f:Hide()

        -- Title
        f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        f.title:SetPoint("TOP", 0, -15)

        -- Description
        f.description = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        f.description:SetPoint("TOPLEFT", 20, -45)
        f.description:SetWidth(500)
        f.description:SetJustifyH("LEFT")

        -- EditBox + Scroll
        f.scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
        f.scroll:SetPoint("TOPLEFT", 20, -80)
        f.scroll:SetPoint("BOTTOMRIGHT", -40, 60)

        f.editBox = CreateFrame("EditBox", nil, f.scroll)
        f.editBox:SetMultiLine(true)
        f.editBox:SetFontObject("ChatFontNormal")
        f.editBox:SetWidth(480)
        f.editBox:SetAutoFocus(false)
        f.scroll:SetScrollChild(f.editBox)

        -- Buttons
        f.closeBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        f.closeBtn:SetSize(100, 25)
        f.closeBtn:SetPoint("BOTTOMRIGHT", -20, 20)
        f.closeBtn:SetText("Close")
        f.closeBtn:SetScript("OnClick", function() f:Hide() end)

        f.actionBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        f.actionBtn:SetSize(120, 25)
        f.actionBtn:SetPoint("RIGHT", f.closeBtn, "LEFT", -10, 0)

        -- Footer
        local footer = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        footer:SetPoint("BOTTOMLEFT", 20, 25)
        footer:SetText(ns.Core.GetFooterText())

        _G.ToxicifyIOFrame = f
    end

    local f = _G.ToxicifyIOFrame
    f:Show()

    if mode == "export" then
        f.title:SetText("|cff39FF14Toxicify|r - Export List")
        f.description:SetText("Your list has been exported! Select all text below and copy with CTRL+C to share with friends.")
        
        local exportData = ns.Core.ExportList()
        f.editBox:SetText(exportData)
        f.actionBtn:SetText("Select All")
        
        -- Auto-copy to clipboard on show (if available)
        local autocopied = ns.Core.CopyToClipboard(exportData)
        if autocopied then
            ns.Core.DebugPrint("List exported and copied to clipboard!")
            f.description:SetText("Your list has been exported and copied to clipboard! Ready to share.")
        else
            ns.Core.DebugPrint("List exported. Clipboard not available - please copy manually.")
            -- Auto-select text for easy copying
            f.editBox:HighlightText()
        end
        
        f.actionBtn:SetScript("OnClick", function()
            if ns.Core.CopyToClipboard(exportData) then
                ns.Core.DebugPrint("Copied to clipboard!")
            else
                f.editBox:HighlightText()
                f.editBox:SetFocus()
                ns.Core.DebugPrint("Text selected - press CTRL+C to copy.")
            end
        end)
        
    elseif mode == "import" then
        f.title:SetText("|cff39FF14Toxicify|r - Import List")
        f.description:SetText("Paste your friend's export string below with CTRL+V - it will import automatically!")
        f.actionBtn:SetText("Close")
        
        -- Make editbox more visible
        f.editBox:SetTextColor(1, 1, 1) -- White text
        f.editBox:SetFontObject("GameFontNormalLarge")
        
        -- Try to auto-paste from clipboard (if available)
        local clipboardData = ns.Core.GetFromClipboard()
        
        if clipboardData and clipboardData ~= "" then
            if clipboardData:match("^TX:") or clipboardData:match("^TOXICIFYv") then
                f.editBox:SetText(clipboardData)
                f.description:SetText("✓ Valid import data found in clipboard! Paste will auto-import.")
                ns.Core.DebugPrint("✓ Valid import data found and loaded!")
            else
                f.editBox:SetText("")
                f.description:SetText("Paste your friend's export string below with CTRL+V - it will import automatically!")
            end
        else
            f.editBox:SetText("")
            f.description:SetText("Paste your friend's export string below with CTRL+V - it will import automatically!")
        end
        
        f.editBox:SetFocus()
        
        -- Auto-import on text change
        f.editBox:SetScript("OnTextChanged", function(self)
            local text = self:GetText()
            if text and text ~= "" and (text:match("^TX:") or text:match("^TOXICIFYv")) then
                ns.Core.DebugPrint("Auto-importing pasted data...")
                f.description:SetText("Importing...")
                
                -- Small delay to ensure text is fully pasted
                C_Timer.After(0.1, function()
                    local ok, result = ns.Core.ImportList(text)
                    if ok then
                        ns.Core.DebugPrint("✓ " .. result)
                        f.description:SetText("SUCCESS: " .. result .. " - Closing in 3 seconds...")
                        if _G.ToxicifyListFrame and _G.ToxicifyListFrame.Refresh then
                            _G.ToxicifyListFrame:Refresh()
                        end
                        -- Auto-close after 3 seconds
                        C_Timer.After(3, function() f:Hide() end)
                    else
                        ns.Core.DebugPrint("Import failed: " .. result)
                        f.description:SetText("ERROR: Import failed: " .. result)
                    end
                end)
            elseif text and text ~= "" then
                f.description:SetText("WARNING: Invalid format. Please paste a valid Toxicify export string.")
            else
                f.description:SetText("Paste your friend's export string below with CTRL+V - it will import automatically!")
            end
        end)
        
        -- Close button
        f.actionBtn:SetScript("OnClick", function()
            f:Hide()
        end)
    end
end
