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

    -- Dropdown voor Toxic/Pumper
    local roleDrop = CreateFrame("Frame", "ToxicifyRoleDrop", f, "UIDropDownMenuTemplate")
    roleDrop:SetPoint("LEFT", addBox, "RIGHT", -15, -3)
    UIDropDownMenu_SetWidth(roleDrop, 100)
    UIDropDownMenu_SetText(roleDrop, "Toxic")

    UIDropDownMenu_Initialize(roleDrop, function(self, level)
        local info = UIDropDownMenu_CreateInfo()

        info.text = "Toxic"
        info.func = function() UIDropDownMenu_SetText(roleDrop, "Toxic") end
        UIDropDownMenu_AddButton(info)

        info.text = "Pumper"
        info.func = function() UIDropDownMenu_SetText(roleDrop, "Pumper") end
        UIDropDownMenu_AddButton(info)
    end)

    -- Add button
    local addBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    addBtn:SetSize(60, 22)
    addBtn:SetPoint("LEFT", roleDrop, "RIGHT", 10, 0)
    addBtn:SetText("Add")

    -- Remove all
    local clearBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    clearBtn:SetSize(100, 22)
    clearBtn:SetPoint("LEFT", addBtn, "RIGHT", 10, 0)
    clearBtn:SetText("Remove All")

    -- Suggestion box (max 5)
    local suggestionBox = CreateFrame("Frame", nil, f, BackdropTemplateMixin and "BackdropTemplate")
    suggestionBox:SetSize(200, 110) -- max 5 * 20px + marge
    suggestionBox:SetPoint("TOPLEFT", addBox, "BOTTOMLEFT", 0, -2)
    suggestionBox:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground", -- zwarte achtergrond
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    suggestionBox:SetBackdropColor(0, 0, 0, 0.9) -- echt zwart met lichte transparantie
    suggestionBox:SetFrameStrata("TOOLTIP")      -- altijd bovenop
    suggestionBox:Hide()

    local function UpdateSuggestions()
        for _, child in ipairs(suggestionBox.children or {}) do child:Hide() end
        suggestionBox.children = {}

        local text = addBox:GetText():lower()
        if text == "" then suggestionBox:Hide() return end

        local suggestions = {}

        -- Groepsleden
        for i = 1, GetNumGroupMembers() do
            local unit = (IsInRaid() and ("raid"..i)) or ("party"..i)
            if UnitExists(unit) then
                local name = GetUnitName(unit, true)
                if name and name:lower():find(text) then
                    table.insert(suggestions, name)
                end
            end
        end

        -- Guildleden
        if IsInGuild() then
            for i = 1, GetNumGuildMembers() do
                local name = GetGuildRosterInfo(i)
                if name and name:lower():find(text) then
                    table.insert(suggestions, name)
                end
            end
        end

        -- Friends
        for i = 1, C_FriendList.GetNumFriends() do
            local info = C_FriendList.GetFriendInfoByIndex(i)
            if info and info.name and info.name:lower():find(text) then
                table.insert(suggestions, info.name)
            end
        end

        -- Bouw max 5
        local y = -5
        local count = 0
        for _, name in ipairs(suggestions) do
            count = count + 1
            if count > 5 then break end

            local btn = CreateFrame("Button", nil, suggestionBox, "UIPanelButtonTemplate")
            btn:SetSize(180, 18)
            btn:SetPoint("TOPLEFT", 10, y)
            btn:SetText(name)
            btn:SetScript("OnClick", function()
                addBox:SetText(name)
                suggestionBox:Hide()
            end)
            table.insert(suggestionBox.children, btn)
            y = y - 20
        end

        if count > 0 then
            suggestionBox:SetHeight(count * 20 + 10)
            suggestionBox:Show()
        else
            suggestionBox:Hide()
        end
    end

    addBox:SetScript("OnTextChanged", UpdateSuggestions)
    addBox:SetScript("OnEditFocusLost", function() C_Timer.After(0.2, function() suggestionBox:Hide() end) end)

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
    end
    f.Refresh = Refresh

    -- Buttons logic
    addBtn:SetScript("OnClick", function()
        local name = addBox:GetText()
        if name and name ~= "" then
            local role = UIDropDownMenu_GetText(roleDrop)
            if role == "Toxic" then
                ns.Player.MarkToxic(name)
            else
                ns.Player.MarkPumper(name)
            end
            addBox:SetText("")
            suggestionBox:Hide()
            Refresh()
        end
    end)

    clearBtn:SetScript("OnClick", function()
        ns.Player.ClearAllPlayers()
        Refresh()
    end)

    -- ReloadUI button rechtsonder
    local reloadBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    reloadBtn:SetSize(80, 22)
    reloadBtn:SetPoint("BOTTOMRIGHT", -20, 15)
    reloadBtn:SetText("ReloadUI")
    reloadBtn:SetScript("OnClick", function() ReloadUI() end)

    -- Footer
    local footer = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    footer:SetPoint("BOTTOMLEFT", 20, 20)
    footer:SetText("|cffaaaaaaCreated by Alvarín-Silvermoon - v2025|r")
end

-- Refresh the shared list
function ns.UI.RefreshSharedList(content, filterText)
    for _, child in ipairs(content.children or {}) do child:Hide() end
    content.children = {}

    filterText = filterText and filterText:lower() or ""

    local y = -5
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
            nameBox:SetSize(180, 22)
            nameBox:SetPoint("LEFT", icon, "RIGHT", 6, 0)
            nameBox:SetAutoFocus(false)
            nameBox:SetText(name)

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
            end

            UIDropDownMenu_Initialize(drop, function(self, level)
                local info = UIDropDownMenu_CreateInfo()

                info.text = "Toxic"
                info.func = function()
                    ToxicifyDB[name] = "toxic"
                    UpdateVisual()
                end
                UIDropDownMenu_AddButton(info)

                info.text = "Pumper"
                info.func = function()
                    ToxicifyDB[name] = "pumper"
                    UpdateVisual()
                end
                UIDropDownMenu_AddButton(info)
            end)

            UIDropDownMenu_SetText(drop, status == "toxic" and "Toxic" or "Pumper")
            UpdateVisual()

            -- Save button
            local save = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            save:SetSize(60, 22)
            save:SetPoint("LEFT", drop, "RIGHT", 10, 0)
            save:SetText("Save")
            save:SetScript("OnClick", function()
                local newName = ns.Player.NormalizePlayerName(nameBox:GetText())
                if newName and newName ~= name then
                    local role = ToxicifyDB[name]
                    ToxicifyDB[name] = nil
                    ToxicifyDB[newName] = role
                end
                ns.UI.RefreshSharedList(content, filterText)
            end)

            -- Delete button
            local del = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            del:SetSize(60, 22)
            del:SetPoint("LEFT", save, "RIGHT", 10, 0)
            del:SetText("Delete")
            del:SetScript("OnClick", function()
                ToxicifyDB[name] = nil
                ns.UI.RefreshSharedList(content, filterText)
            end)

            table.insert(content.children, row)
            y = y - 28
        end
    end
end

-- Show Import/Export popup
function ns.UI.ShowIOPopup(mode, data)
    if not _G.ToxicifyIOFrame then
        local f = CreateFrame("Frame", "ToxicifyIOFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
        f:SetSize(500, 300)
        f:SetPoint("CENTER")
        f:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 16,
            insets = { left = 8, right = 8, top = 8, bottom = 8 }
        })
        f:SetFrameStrata("DIALOG")
        f:Hide()

        -- Titel
        f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        f.title:SetPoint("TOP", 0, -15)

        -- EditBox + Scroll
        f.scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
        f.scroll:SetPoint("TOPLEFT", 20, -50)
        f.scroll:SetPoint("BOTTOMRIGHT", -40, 50)

        f.editBox = CreateFrame("EditBox", nil, f.scroll)
        f.editBox:SetMultiLine(true)
        f.editBox:SetFontObject("ChatFontNormal")
        f.editBox:SetWidth(420)
        f.editBox:SetAutoFocus(false)
        f.scroll:SetScrollChild(f.editBox)

        -- Buttons
        f.closeBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        f.closeBtn:SetSize(100, 22)
        f.closeBtn:SetPoint("BOTTOMRIGHT", -20, 15)
        f.closeBtn:SetText("Close")
        f.closeBtn:SetScript("OnClick", function() f:Hide() end)

        f.actionBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        f.actionBtn:SetSize(100, 22)
        f.actionBtn:SetPoint("RIGHT", f.closeBtn, "LEFT", -10, 0)

        _G.ToxicifyIOFrame = f
    end

    local f = _G.ToxicifyIOFrame
    f:Show()
    f.editBox:SetText("")
    f.editBox:HighlightText()

    if mode == "export" then
        f.title:SetText("|cff39FF14Toxicify|r - Export List")
        f.editBox:SetText(ns.Core.ExportList())
        f.editBox:HighlightText()
        f.actionBtn:SetText("Copy")
        f.actionBtn:SetScript("OnClick", function()
            f.editBox:HighlightText()
            print("|cff39FF14Toxicify:|r Copy the string with CTRL+C.")
        end)
    elseif mode == "import" then
        f.title:SetText("|cff39FF14Toxicify|r - Import List")
        f.actionBtn:SetText("Import")
        f.actionBtn:SetScript("OnClick", function()
            local ok, result = ns.Core.ImportList(f.editBox:GetText())
            if ok then
                print("|cff39FF14Toxicify:|r Import success: " .. result)
                if _G.ToxicifyListFrame and _G.ToxicifyListFrame.Refresh then
                    _G.ToxicifyListFrame:Refresh()
                end
            else
                print("|cffff0000Toxicify:|r Import failed: " .. result)
            end
        end)
    end
end
