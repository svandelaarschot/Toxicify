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
    if not C_CompactUnitFrame or not C_CompactUnitFrame.GetAllFrames then
        return nil
    end

    for _, frame in ipairs(C_CompactUnitFrame.GetAllFrames()) do
        if frame and frame.unit == unit then
            return frame
        end
    end

    return nil
end

-- Create the main Toxicify UI
function ns.UI.CreateToxicifyUI()
    if _G.ToxicifyListFrame then return end

    local f = CreateFrame("Frame", "ToxicifyListFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
    f:SetSize(620, 500)
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
    addBox:SetSize(200, 22)
    addBox:SetPoint("LEFT", playerLabel, "RIGHT", 10, 0)
    addBox:SetAutoFocus(false)

    -- Add Toxic button
    local addToxicBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    addToxicBtn:SetSize(80, 22)
    addToxicBtn:SetPoint("LEFT", addBox, "RIGHT", 10, 0)
    addToxicBtn:SetText("Add Toxic")

    -- Add Pumper button
    local addPumperBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    addPumperBtn:SetSize(80, 22)
    addPumperBtn:SetPoint("LEFT", addToxicBtn, "RIGHT", 10, 0)
    addPumperBtn:SetText("Add Pumper")

    -- Remove all
    local clearBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    clearBtn:SetSize(100, 22)
    clearBtn:SetPoint("LEFT", addPumperBtn, "RIGHT", 10, 0)
    clearBtn:SetText("Remove All")

    -- Auto-completion using shared functionality
    local suggestionBox = ns.Core.CreateAutoCompletion(addBox, f)

    -- Filter toxic groups checkbox
    local hideToxicCheck = CreateFrame("CheckButton", nil, f, "InterfaceOptionsCheckButtonTemplate")
    hideToxicCheck:SetPoint("TOPLEFT", addBox, "BOTTOMLEFT", 0, -15)
    hideToxicCheck.Text:SetText("Hide toxic groups in Premade Groups")
    hideToxicCheck:SetChecked(ToxicifyDB.HideInFinder or false)
    hideToxicCheck:SetScript("OnClick", function(self)
        ToxicifyDB.HideInFinder = self:GetChecked()
        if LFGListFrame and LFGListFrame.SearchPanel then
            LFGListSearchPanel_UpdateResultList(LFGListFrame.SearchPanel)
        end
    end)

    -- Search row
    local searchLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    searchLabel:SetPoint("TOPLEFT", hideToxicCheck, "BOTTOMLEFT", 0, -15)
    searchLabel:SetText("Search:")

    local searchBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    searchBox:SetSize(220, 22)
    searchBox:SetPoint("LEFT", searchLabel, "RIGHT", 10, 0)
    searchBox:SetAutoFocus(false)
    searchBox:SetScript("OnTextChanged", function(self) f:Refresh() end)

    -- List
    local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", searchLabel, "BOTTOMLEFT", 0, -10)
    scroll:SetPoint("BOTTOMRIGHT", -30, 50)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(460, 300)
    scroll:SetScrollChild(content)

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
            ns.Player.MarkToxic(name)
            addBox:SetText("")
            suggestionBox:Hide()
            Refresh()
            -- Force refresh after a small delay
            C_Timer.After(0.1, function() Refresh() end)
        end
    end)

    addPumperBtn:SetScript("OnClick", function()
        local name = addBox:GetText()
        if name and name ~= "" then
            ns.Player.MarkPumper(name)
            addBox:SetText("")
            suggestionBox:Hide()
            Refresh()
            -- Force refresh after a small delay
            C_Timer.After(0.1, function() Refresh() end)
        end
    end)

    clearBtn:SetScript("OnClick", function()
        ns.Player.ClearAllPlayers()
        Refresh()
    end)

    -- Settings button rechtsonder
    local settingsBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    settingsBtn:SetSize(80, 22)
    settingsBtn:SetPoint("BOTTOMRIGHT", -20, 15)
    settingsBtn:SetText("Settings")
    settingsBtn:SetScript("OnClick", function() 
        -- Sluit het huidige dialoog
        f:Hide()
        
        -- Open de juiste settings
        if Settings and Settings.OpenToCategory then
            -- Retail (Dragonflight+)
            Settings.OpenToCategory("Toxicify")
        elseif InterfaceOptionsFrame_OpenToCategory then
            -- Classic/older versions
            InterfaceOptionsFrame_OpenToCategory("Toxicify")
            InterfaceOptionsFrame_OpenToCategory("Toxicify") -- double call fixes Blizzard bug
        else
            -- Fallback: open interface options
            InterfaceOptionsFrame:Show()
        end
    end)

    -- ReloadUI button links van Settings
    local reloadBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    reloadBtn:SetSize(80, 22)
    reloadBtn:SetPoint("RIGHT", settingsBtn, "LEFT", -10, 0)
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
    for name, status in pairs(ToxicifyDB) do
        if (status == "toxic" or status == "pumper") 
           and (filterText == "" or name:lower():find(filterText, 1, true)) then

            local row = CreateFrame("Frame", nil, content)
            row:SetSize(520, 26)
            row:SetPoint("TOPLEFT", 0, y)

            -- Icon
            local icon = row:CreateTexture(nil, "ARTWORK")
            icon:SetSize(16, 16)
            icon:SetPoint("LEFT", 0, 0)

            -- Editable name field
            local nameBox = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
            nameBox:SetSize(250, 22)
            nameBox:SetPoint("LEFT", icon, "RIGHT", 6, 0)
            nameBox:SetAutoFocus(false)
            nameBox:SetText(name)
            
            -- Force text to be visible immediately
            nameBox:SetFontObject("GameFontNormal")
            nameBox:SetCursorPosition(0)
            nameBox:ClearFocus()
            
            -- Set initial color based on status
            if ToxicifyDB[name] == "toxic" then
                nameBox:SetTextColor(1, 0, 0) -- rood
            else
                nameBox:SetTextColor(0, 1, 0) -- groen
            end

            -- Dropdown
            local drop = CreateFrame("Frame", nil, row, "UIDropDownMenuTemplate")
            drop:SetPoint("LEFT", nameBox, "RIGHT", -10, -3)
            UIDropDownMenu_SetWidth(drop, 100)

            local function UpdateVisual()
                if ToxicifyDB[name] == "toxic" then
                    icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_8")
                    nameBox:SetTextColor(1, 0, 0) -- rood
                else
                    icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_1")
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
                    ToxicifyDB[name] = "toxic"
                    UpdateVisual()
                    -- Update list immediately after status change
                    ns.UI.RefreshSharedList(content, filterText)
                end
                UIDropDownMenu_AddButton(info)

                info.text = "Pumper"
                info.func = function()
                    ToxicifyDB[name] = "pumper"
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
                    local role = ToxicifyDB[name]
                    ToxicifyDB[name] = nil
                    ToxicifyDB[newName] = role
                    name = newName
                    
                    -- Update list after name change
                    ns.UI.RefreshSharedList(content, filterText)
                end
            end)
            
            -- Keep text visible with correct color during typing
            nameBox:SetScript("OnTextChanged", function(self)
                self:SetFontObject("GameFontNormal")
                if ToxicifyDB[name] == "toxic" then
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
                ToxicifyDB[name] = nil
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
        f.description:SetText("Your list has been exported and copied to clipboard. Share this with friends!")
        
        local exportData = ns.Core.ExportList()
        f.editBox:SetText(exportData)
        f.actionBtn:SetText("Copy Again")
        
        -- Auto-copy to clipboard on show
        local autocopied = ns.Core.CopyToClipboard(exportData)
        if autocopied then
            print("|cff39FF14Toxicify:|r ✓ List exported and copied to clipboard!")
        else
            print("|cff39FF14Toxicify:|r List exported. Please copy manually.")
        end
        
        f.actionBtn:SetScript("OnClick", function()
            if ns.Core.CopyToClipboard(exportData) then
                print("|cff39FF14Toxicify:|r ✓ Copied to clipboard again!")
            else
                f.editBox:HighlightText()
                print("|cff39FF14Toxicify:|r Please copy the text manually with CTRL+C.")
            end
        end)
        
    elseif mode == "import" then
        f.title:SetText("|cff39FF14Toxicify|r - Import List")
        f.description:SetText("Paste a friend's export string below, or it will be automatically loaded from clipboard.")
        f.actionBtn:SetText("Import")
        
        -- Try to auto-paste from clipboard
        local clipboardData = ns.Core.GetFromClipboard()
        print("|cff39FF14Toxicify:|r Checking clipboard for import data...")
        
        if clipboardData and clipboardData ~= "" then
            print("|cff39FF14Toxicify:|r Found data in clipboard: " .. clipboardData:sub(1, 50) .. "...")
            if clipboardData:match("^TX:") or clipboardData:match("^TOXICIFYv") then
                f.editBox:SetText(clipboardData)
                print("|cff39FF14Toxicify:|r ✓ Valid import data found and loaded!")
            else
                f.editBox:SetText(clipboardData)
                print("|cff39FF14Toxicify:|r Data found but format unknown - loaded anyway for manual check.")
            end
        else
            f.editBox:SetText("")
            print("|cff39FF14Toxicify:|r No data found in clipboard. Paste import string below.")
        end
        
        f.actionBtn:SetScript("OnClick", function()
            local text = f.editBox:GetText()
            
            if text == "" then
                text = ns.Core.GetFromClipboard()
                if text and text ~= "" then
                    f.editBox:SetText(text)
                end
            end
            
            if text == "" then
                print("|cffff0000Toxicify:|r No data to import. Please paste an export string first.")
                return
            end
            
            local ok, result = ns.Core.ImportList(text)
            if ok then
                print("|cff39FF14Toxicify:|r ✓ " .. result)
                if _G.ToxicifyListFrame and _G.ToxicifyListFrame.Refresh then
                    _G.ToxicifyListFrame:Refresh()
                end
                f:Hide()
            else
                print("|cffff0000Toxicify:|r Import failed: " .. result)
            end
        end)
    end
end
