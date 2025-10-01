local addonName, ns = ...
ToxicifyDB = ToxicifyDB or {}

-- Central function for initializing editboxes
local function InitializeEditBox(editBox, value, debugName)
    if not editBox then return end
    
    local currentValue = value or ""
    if debugName then
        print("|cff39FF14[Toxicify DEBUG]|r " .. debugName .. " value: " .. tostring(currentValue))
    end
    
    -- Set the text and properties
    editBox:SetText(tostring(currentValue))
    editBox:SetTextColor(1, 1, 1)
    editBox:SetFontObject("GameFontNormal")
    editBox:Show()
    editBox:Enable()
    
    -- Force the text to be visible
    editBox:SetCursorPosition(0)
    editBox:HighlightText(0, -1)
    editBox:SetCursorPosition(0)
end

-- Central function for delayed editbox initialization
local function InitializeEditBoxDelayed(editBox, value, debugName, delay)
    delay = delay or 0.5
    C_Timer.After(delay, function()
        InitializeEditBox(editBox, value, debugName)
    end)
end

---------------------------------------------------
-- General Settings Panel
---------------------------------------------------
local generalPanel = CreateFrame("Frame", "ToxicifyGeneralOptionsPanel")
generalPanel.name = "General"

-- Title
local title = generalPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("|cff39FF14Toxicify|r - General Settings")

-- Description
local desc = generalPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
desc:SetWidth(500)
desc:SetJustifyH("LEFT")
desc:SetText("General settings for the Toxicify addon. Configure basic behavior and party warnings.")

-- Hide in finder
local hideCheck = CreateFrame("CheckButton", nil, generalPanel, "InterfaceOptionsCheckButtonTemplate")
hideCheck:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -20)
hideCheck.Text:SetText("Hide toxic groups in Premade Groups")
hideCheck:SetChecked(ToxicifyDB.HideInFinder or false)
hideCheck:SetScript("OnClick", function(self)
    ToxicifyDB.HideInFinder = self:GetChecked()
end)

-- Party warning
local partyWarningCheck = CreateFrame("CheckButton", nil, generalPanel, "InterfaceOptionsCheckButtonTemplate")
partyWarningCheck:SetPoint("TOPLEFT", hideCheck, "BOTTOMLEFT", 0, -10)
partyWarningCheck.Text:SetText("Show warning when joining party with toxic/pumper players")
partyWarningCheck:SetChecked(ToxicifyDB.PartyWarningEnabled or true)
partyWarningCheck:SetScript("OnClick", function(self)
    ns.Core.DebugPrint("Party warning checkbox clicked, new value: " .. tostring(self:GetChecked()))
    ToxicifyDB.PartyWarningEnabled = self:GetChecked()
    ns.Core.DebugPrint("PartyWarningEnabled set to: " .. tostring(ToxicifyDB.PartyWarningEnabled))
end)

-- Auto-Close Timer
local autoCloseLabel = generalPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
autoCloseLabel:SetPoint("TOPLEFT", partyWarningCheck, "BOTTOMLEFT", 0, -20)
autoCloseLabel:SetText("Auto-Close Timer (seconds):")

-- Auto-Close Timer description
local autoCloseDesc = generalPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
autoCloseDesc:SetPoint("TOPLEFT", autoCloseLabel, "BOTTOMLEFT", 0, -5)
autoCloseDesc:SetWidth(400)
autoCloseDesc:SetJustifyH("LEFT")
autoCloseDesc:SetText("How long the warning popup stays open before automatically closing. Range: 1-300 seconds")

local autoCloseEditBox = CreateFrame("EditBox", nil, generalPanel, "InputBoxTemplate")
autoCloseEditBox:SetPoint("TOPLEFT", autoCloseDesc, "BOTTOMLEFT", 0, -5)
autoCloseEditBox:SetSize(80, 20)
autoCloseEditBox:SetAutoFocus(false)
autoCloseEditBox:SetNumeric(true)
autoCloseEditBox:SetMaxLetters(3)

-- Initialize immediately after creation
InitializeEditBox(autoCloseEditBox, ToxicifyDB.PopupTimerSeconds or 25, "Auto-Close timer")

autoCloseEditBox:SetScript("OnTextChanged", function(self)
    local value = tonumber(self:GetText())
    if value and value > 0 and value <= 300 then
        ToxicifyDB.PopupTimerSeconds = value
        ns.Core.DebugPrint("Auto-Close timer set to: " .. value .. " seconds")
        -- Update description with new value (using the local variable)
        if autoCloseDesc then
            autoCloseDesc:SetText("How long the warning popup stays open before automatically closing. Range: 1-300 seconds")
        end
    end
end)
autoCloseEditBox:SetScript("OnEnterPressed", function(self)
    self:ClearFocus()
end)
autoCloseEditBox:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
end)

-- Lua errors toggle (only visible when debug is enabled)
local luaErrorsCheck = CreateFrame("CheckButton", nil, generalPanel, "InterfaceOptionsCheckButtonTemplate")
luaErrorsCheck:SetPoint("TOPLEFT", autoCloseEditBox, "BOTTOMLEFT", 0, -10)
luaErrorsCheck.Text:SetText("Show Lua errors in chat (Debug mode only)")
luaErrorsCheck:SetChecked(ToxicifyDB.LuaErrorsEnabled or false)
luaErrorsCheck:SetScript("OnClick", function(self)
    local enabled = self:GetChecked()
    ToxicifyDB.LuaErrorsEnabled = enabled
    
    -- Set console scriptErrors based on toggle
    if enabled then
        SetCVar("scriptErrors", "1")
        print("|cff39FF14[Toxicify Debug]:|r Lua errors enabled - /console scriptErrors set to 1")
    else
        SetCVar("scriptErrors", "0")
        print("|cff39FF14[Toxicify Debug]:|r Lua errors disabled - /console scriptErrors set to 0")
    end
end)


-- Panel OnShow
generalPanel:SetScript("OnShow", function()
    -- Show/hide Lua errors toggle based on debug mode
    if ToxicifyDB.DebugEnabled then
        luaErrorsCheck:Show()
        -- Sync toggle with current scriptErrors setting
        local scriptErrorsEnabled = GetCVar("scriptErrors") == "1"
        luaErrorsCheck:SetChecked(scriptErrorsEnabled)
        ToxicifyDB.LuaErrorsEnabled = scriptErrorsEnabled
    else
        luaErrorsCheck:Hide()
    end
end)

---------------------------------------------------
-- Import / Export (strakke layout + textarea)
---------------------------------------------------
local ioLabel = generalPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
ioLabel:SetPoint("TOPLEFT", scrollFrame, "BOTTOMLEFT", 0, -30)
ioLabel:SetText("Import / Export List:")

-- ScrollFrame + Multiline EditBox
local ioScroll = CreateFrame("ScrollFrame", "ToxicifyIOScroll", generalPanel, "UIPanelScrollFrameTemplate")
ioScroll:SetPoint("TOPLEFT", ioLabel, "BOTTOMLEFT", 0, -10)
ioScroll:SetSize(500, 100)

local ioBox = CreateFrame("EditBox", "ToxicifyIOBox", ioScroll)
ioBox:SetMultiLine(true)
ioBox:SetSize(480, 100)
ioBox:SetAutoFocus(false)
ioBox:SetFontObject(ChatFontNormal)
ioBox:SetMaxLetters(4000)
ioBox:SetTextInsets(5, 5, 5, 5)
ioBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
ioScroll:SetScrollChild(ioBox)

-- Export button
local exportBtn = CreateFrame("Button", nil, generalPanel, "UIPanelButtonTemplate")
exportBtn:SetSize(100, 24)
exportBtn:SetPoint("TOPLEFT", ioScroll, "BOTTOMLEFT", 0, -8)
exportBtn:SetText("Export")
exportBtn:SetScript("OnClick", function()
    local export = ns.Core.ExportList()
    ioBox:SetText(export)
    ioBox:HighlightText()
    print("|cff39FF14Toxicify:|r List exported to box.")
end)

-- Import button
local importBtn = CreateFrame("Button", nil, generalPanel, "UIPanelButtonTemplate")
importBtn:SetSize(100, 24)
importBtn:SetPoint("LEFT", exportBtn, "RIGHT", 10, 0)
importBtn:SetText("Import")
importBtn:SetScript("OnClick", function()
    local text = ioBox:GetText()
    local ok, result = ns.Core.ImportList(text)
    if ok then
        print("|cff39FF14Toxicify:|r Import success: " .. result)
        RefreshList()
    else
        print("|cffff0000Toxicify:|r Import failed: " .. result)
    end
end)

---------------------------------------------------
-- Toxic & Pumper List Management Panel
---------------------------------------------------
local listPanel = CreateFrame("Frame", "ToxicifyListOptionsPanel")
listPanel.name = "Toxic List"

-- Title
local listTitle = listPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
listTitle:SetPoint("TOPLEFT", 16, -16)
listTitle:SetText("|cff39FF14Toxicify|r - Toxic & Pumper List Management")

-- Description
local listDesc = listPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
listDesc:SetPoint("TOPLEFT", listTitle, "BOTTOMLEFT", 0, -8)
listDesc:SetWidth(500)
listDesc:SetJustifyH("LEFT")
listDesc:SetText("Manage your toxic/pumper player list. They will be marked in party/raid frames and in the Group Finder.\n\nYou can add names manually below or with /toxic add Name-Realm.")

-- Input label
local inputLabel = listPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
inputLabel:SetPoint("TOPLEFT", listDesc, "BOTTOMLEFT", 0, -20)
inputLabel:SetText("Player Name:")
inputLabel:SetTextColor(1, 1, 1) -- White color

-- Input + add buttons
local input = CreateFrame("EditBox", nil, listPanel, "InputBoxTemplate")
input:SetSize(200, 30)
input:SetPoint("LEFT", inputLabel, "RIGHT", 10, 0)
input:SetAutoFocus(false)
input:SetMaxLetters(50)

-- Auto-completion using shared functionality
local suggestionBox = ns.Core.CreateAutoCompletion(input, listPanel)

local addToxicBtn = CreateFrame("Button", nil, listPanel, "UIPanelButtonTemplate")
addToxicBtn:SetSize(100, 30)
addToxicBtn:SetPoint("LEFT", input, "RIGHT", 10, 0)
addToxicBtn:SetText("Add Toxic")

local addPumperBtn = CreateFrame("Button", nil, listPanel, "UIPanelButtonTemplate")
addPumperBtn:SetSize(100, 30)
addPumperBtn:SetPoint("LEFT", addToxicBtn, "RIGHT", 10, 0)
addPumperBtn:SetText("Add Pumper")

-- ScrollFrame for list
local scrollFrame = CreateFrame("ScrollFrame", nil, listPanel, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", inputLabel, "BOTTOMLEFT", 0, -20)
scrollFrame:SetSize(500, 200)

local content = CreateFrame("Frame", nil, scrollFrame)
content:SetSize(500, 200)
scrollFrame:SetScrollChild(content)

local function RefreshList()
    if ns.UI and ns.UI.RefreshSharedList then
        ns.UI.RefreshSharedList(content)
    end
end


-- Add toxic
addToxicBtn:SetScript("OnClick", function()
    local name = input:GetText()
    if name and name ~= "" then
        ns.Player.MarkToxic(name)
        input:SetText("")
        suggestionBox:Hide()
        RefreshList()
        -- Also update the main UI list if it exists
        if ns.UI and ns.UI.RefreshSharedList then
            ns.UI.RefreshSharedList()
        end
    end
end)

-- Add pumper
addPumperBtn:SetScript("OnClick", function()
    local name = input:GetText()
    if name and name ~= "" then
        ns.Player.MarkPumper(name)
        input:SetText("")
        suggestionBox:Hide()
        RefreshList()
        -- Also update the main UI list if it exists
        if ns.UI and ns.UI.RefreshSharedList then
            ns.UI.RefreshSharedList()
        end
    end
end)

-- Panel OnShow
listPanel:SetScript("OnShow", function()
    RefreshList()
end)


---------------------------------------------------
-- Import/Export Panel
---------------------------------------------------
local ioPanel = CreateFrame("Frame", "ToxicifyIOOptionsPanel")
ioPanel.name = "Import/Export"

-- Title
local ioTitle = ioPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
ioTitle:SetPoint("TOPLEFT", 16, -16)
ioTitle:SetText("|cff39FF14Toxicify|r - Import / Export")

-- Description
local ioDesc = ioPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
ioDesc:SetPoint("TOPLEFT", ioTitle, "BOTTOMLEFT", 0, -8)
ioDesc:SetWidth(500)
ioDesc:SetJustifyH("LEFT")
ioDesc:SetText("Import or export your toxic/pumper player list. Use this to share your list with others or backup your data.")

-- Import/Export buttons
local exportBtn = CreateFrame("Button", nil, ioPanel, "UIPanelButtonTemplate")
exportBtn:SetSize(120, 22)
exportBtn:SetPoint("TOPLEFT", ioDesc, "BOTTOMLEFT", 0, -20)
exportBtn:SetText("Export List")
exportBtn:SetScript("OnClick", function()
    ns.UI.ShowIOPopup("export")
end)

local importBtn = CreateFrame("Button", nil, ioPanel, "UIPanelButtonTemplate")
importBtn:SetSize(120, 22)
importBtn:SetPoint("LEFT", exportBtn, "RIGHT", 10, 0)
importBtn:SetText("Import List")
importBtn:SetScript("OnClick", function()
    ns.UI.ShowIOPopup("import")
end)

---------------------------------------------------
-- Whisper & Ignore Panel
---------------------------------------------------
local whisperPanel = CreateFrame("Frame", "ToxicifyWhisperOptionsPanel")
whisperPanel.name = "Whisper Settings"

local title2 = whisperPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title2:SetPoint("TOPLEFT", 16, -16)
title2:SetText("|cff39FF14Toxicify|r - Whisper & Ignore Settings")

local desc2 = whisperPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
desc2:SetPoint("TOPLEFT", title2, "BOTTOMLEFT", 0, -8)
desc2:SetWidth(500)
desc2:SetJustifyH("LEFT")
desc2:SetText("Configure whisper behavior and automatic ignore. If enabled, Toxicify will whisper and/or ignore players when they are marked as toxic.")

local whisperCheck = CreateFrame("CheckButton", "ToxicifyWhisperCheck", whisperPanel, "InterfaceOptionsCheckButtonTemplate")
whisperCheck:SetPoint("TOPLEFT", desc2, "BOTTOMLEFT", 0, -10)
whisperCheck.Text:SetText("Whisper players when marked toxic")

local ignoreCheck = CreateFrame("CheckButton", "ToxicifyIgnoreCheck", whisperPanel, "InterfaceOptionsCheckButtonTemplate")
ignoreCheck:SetPoint("TOPLEFT", whisperCheck, "BOTTOMLEFT", 0, -10)
ignoreCheck.Text:SetText("Also add toxic players to Ignore list")

local partyWarningCheck = CreateFrame("CheckButton", "ToxicifyPartyWarningCheck", whisperPanel, "InterfaceOptionsCheckButtonTemplate")
partyWarningCheck:SetPoint("TOPLEFT", ignoreCheck, "BOTTOMLEFT", 0, -10)
partyWarningCheck.Text:SetText("Show warning when joining party with toxic/pumper players")
partyWarningCheck:SetChecked(ToxicifyDB.PartyWarningEnabled or true)

-- Create a label for the whisper box
local whisperLabel = whisperPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
whisperLabel:SetPoint("TOPLEFT", partyWarningCheck, "BOTTOMLEFT", 0, -10)
whisperLabel:SetText("Whisper:")
whisperLabel:SetTextColor(1, 1, 1) -- White color

-- Create a simple editbox with template
local whisperBox = CreateFrame("EditBox", "ToxicifyWhisperBox", whisperPanel, "InputBoxTemplate")
whisperBox:SetSize(400, 30)
whisperBox:SetPoint("LEFT", whisperLabel, "RIGHT", 10, 0)
whisperBox:SetAutoFocus(false)
whisperBox:SetMaxLetters(200)
whisperBox:SetFontObject("GameFontNormal")
whisperBox:SetTextColor(1, 1, 1)
whisperBox:SetTextInsets(5, 5, 0, 0)

-- Try to set text immediately after creation
local defaultMsg = "U have been marked as Toxic player by - Toxicify Addon"
InitializeEditBox(whisperBox, defaultMsg, "Whisper message")
whisperBox:ClearFocus()

-- Defaults
local function EnsureDefaults()
    if not ToxicifyDB.WhisperMessage or ToxicifyDB.WhisperMessage == "" then
        ToxicifyDB.WhisperMessage = "U have been marked as Toxic player by - Toxicify Addon"
    end
    if ToxicifyDB.WhisperOnMark == nil then
        ToxicifyDB.WhisperOnMark = false
    end
    if ToxicifyDB.IgnoreOnMark == nil then
        ToxicifyDB.IgnoreOnMark = false
    end
    if ToxicifyDB.DebugEnabled == nil then
        ToxicifyDB.DebugEnabled = false
    end
    -- Debug: print the current whisper message
end

-- Initialize defaults and set values
EnsureDefaults()
whisperCheck:SetChecked(ToxicifyDB.WhisperOnMark)
ignoreCheck:SetChecked(ToxicifyDB.IgnoreOnMark)
-- Force set the default message
local defaultMsg = "U have been marked as Toxic player by - Toxicify Addon"
local currentMsg = ToxicifyDB.WhisperMessage or defaultMsg
InitializeEditBox(whisperBox, currentMsg, "Whisper message (force)")


-- Delayed initialization to ensure editbox is fully loaded
C_Timer.After(0.5, function()
    local defaultMsg = "U have been marked as Toxic player by - Toxicify Addon"
    local currentMsg = ToxicifyDB.WhisperMessage or defaultMsg
    InitializeEditBox(whisperBox, currentMsg, "Delayed whisper message")
    
    -- Also initialize Auto-Close timer with delay
    InitializeEditBox(autoCloseEditBox, ToxicifyDB.PopupTimerSeconds or 25, "Delayed Auto-Close timer")
end)

whisperPanel:SetScript("OnShow", function()
    EnsureDefaults()
    whisperCheck:SetChecked(ToxicifyDB.WhisperOnMark)
    ignoreCheck:SetChecked(ToxicifyDB.IgnoreOnMark)
    partyWarningCheck:SetChecked(ToxicifyDB.PartyWarningEnabled)
    -- Force set the default message
    local defaultMsg = "U have been marked as Toxic player by - Toxicify Addon"
    local currentMsg = ToxicifyDB.WhisperMessage or defaultMsg
    InitializeEditBox(whisperBox, currentMsg, "OnShow whisper message")
end)

whisperCheck:SetScript("OnClick", function(self)
    ToxicifyDB.WhisperOnMark = self:GetChecked()
    -- Always keep the editbox enabled so users can see and edit the message
    whisperBox:Enable()

end)

ignoreCheck:SetScript("OnClick", function(self)
    ToxicifyDB.IgnoreOnMark = self:GetChecked()
end)

partyWarningCheck:SetScript("OnClick", function(self)
    ToxicifyDB.PartyWarningEnabled = self:GetChecked()
end)

whisperBox:SetScript("OnTextChanged", function(self)
    if whisperCheck:GetChecked() then
        ToxicifyDB.WhisperMessage = self:GetText()
    end
end)

-- Force set text after a short delay to ensure editbox is ready
C_Timer.After(0.1, function()
    local defaultMsg = "U have been marked as Toxic player by - Toxicify Addon"
    local currentMsg = ToxicifyDB.WhisperMessage or defaultMsg
    whisperBox:SetText(currentMsg)
    whisperBox:SetTextColor(1, 1, 1)
    whisperBox:SetFontObject("GameFontNormal")
    whisperBox:Show()
    whisperBox:Enable()
    
    -- Force text to be visible immediately
    whisperBox:SetCursorPosition(0)
    whisperBox:HighlightText(0, -1)
    whisperBox:ClearFocus()
end)

-- Additional delayed attempt
C_Timer.After(1.0, function()
    local defaultMsg = "U have been marked as Toxic player by - Toxicify Addon"
    local currentMsg = ToxicifyDB.WhisperMessage or defaultMsg
    whisperBox:SetText(currentMsg)
    whisperBox:SetTextColor(1, 1, 1)
    whisperBox:SetFontObject("GameFontNormal")
    whisperBox:Show() -- Force show
    whisperBox:Enable() -- Force enable
    
    -- Force text to be visible immediately
    whisperBox:SetCursorPosition(0)
    whisperBox:HighlightText(0, -1)
    whisperBox:ClearFocus()
end)

---------------------------------------------------
-- Root Info Panel
---------------------------------------------------
local rootPanel = CreateFrame("Frame", "ToxicifyRootPanel")
rootPanel.name = "|cff39FF14Toxicify|r"

local titleRoot = rootPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
titleRoot:SetPoint("TOPLEFT", 16, -16)
titleRoot:SetText("|cff39FF14Toxicify|r")

local descRoot = rootPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
descRoot:SetPoint("TOPLEFT", titleRoot, "BOTTOMLEFT", 0, -8)
descRoot:SetWidth(600)
descRoot:SetJustifyH("LEFT")
descRoot:SetText([[  
Toxicify helps you mark players as |cffff0000Toxic|r or |cff00ff00Pumper|r.  
Once added, they will be clearly highlighted in Party/Raid frames and in the Group Finder.  

Features:  
- Add players with /toxic add <name-realm>  
- Quickly mark via right-click context menus  
- Color-coded names + raid icons in Group Finder and tooltips  
- Options to auto-whisper and/or ignore toxic players  
- Import and export your list to share with friends  

Quick Commands
  
|cffFFFFFFAdd as Toxic|r
/toxic add <name-realm>

|cffFFFFFFAdd as Pumper|r
/toxic add pumper <name-realm>  

|cffFFFFFFRemove player from list|r
/toxic del <name-realm>         

|cffFFFFFFShow all stored players|r
/toxic list                     

|cffFFFFFFOpen the Toxicify list window|r
/toxic ui                       

|cffFFFFFFPrint export string in chat|r
/toxicexport                    

|cffFFFFFFImport a shared list|r
/toxicimport <string>           


Enjoy keeping your runs clean and smooth!  

|cffaaaaaaKind Regards,|r  
|cff39FF14Alvarín-Silvermoon|r  
]])

-- Root panel OnShow event
rootPanel:SetScript("OnShow", function()
    if ns.UI and ns.UI.RefreshSharedList then
        RefreshList()
    end
end)

-- Force refresh list when addon loads
C_Timer.After(2.0, function()
    if ns.UI and ns.UI.RefreshSharedList then
        RefreshList()
    end
end)

-- Additional refresh for list panel specifically
C_Timer.After(3.0, function()
    if ns.UI and ns.UI.RefreshSharedList then
        RefreshList()
    end
end)

---------------------------------------------------
-- Register Panels (Retail vs Classic)
---------------------------------------------------
if Settings and Settings.RegisterAddOnCategory then
    -- Retail (Dragonflight+)
    local root = Settings.RegisterCanvasLayoutCategory(rootPanel, rootPanel.name)

    -- Subpanels
    Settings.RegisterCanvasLayoutSubcategory(root, generalPanel, generalPanel.name)
    Settings.RegisterCanvasLayoutSubcategory(root, listPanel, listPanel.name)
    Settings.RegisterCanvasLayoutSubcategory(root, ioPanel, ioPanel.name)
    Settings.RegisterCanvasLayoutSubcategory(root, whisperPanel, whisperPanel.name)

    Settings.RegisterAddOnCategory(root)
else
    -- Classic
    InterfaceOptions_AddCategory(rootPanel)
    InterfaceOptions_AddCategory(generalPanel)
    InterfaceOptions_AddCategory(listPanel)
    InterfaceOptions_AddCategory(ioPanel)
    InterfaceOptions_AddCategory(whisperPanel)
end
