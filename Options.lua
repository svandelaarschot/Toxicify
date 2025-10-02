local addonName, ns = ...
ToxicifyDB = ToxicifyDB or {}

-- Central function for initializing editboxes
local function InitializeEditBox(editBox, value, debugName)
    if not editBox then return end
    
    local currentValue = value or ""
    if debugName and ToxicifyDB and ToxicifyDB.DebugEnabled == true then
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
    -- editBox:HighlightText(0, -1) -- Removed highlight
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
    
    -- Update description
    hideDesc:SetText("Filters out groups with toxic leaders in Premade Groups.")
end)

-- Hide Toxic Groups description
local hideDesc = generalPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
hideDesc:SetPoint("TOPLEFT", hideCheck, "BOTTOMLEFT", 0, -5)
hideDesc:SetWidth(400)
hideDesc:SetJustifyH("LEFT")
hideDesc:SetText("Filters out groups with toxic leaders in Premade Groups.")

-- Party warning
local partyWarningCheck = CreateFrame("CheckButton", nil, generalPanel, "InterfaceOptionsCheckButtonTemplate")
partyWarningCheck:SetPoint("TOPLEFT", hideDesc, "BOTTOMLEFT", 0, -15)
partyWarningCheck.Text:SetText("Show warning when joining party with toxic/pumper players")
partyWarningCheck:SetChecked(ToxicifyDB.PartyWarningEnabled or true)
partyWarningCheck:SetScript("OnClick", function(self)
    ns.Core.DebugPrint("Party warning checkbox clicked, new value: " .. tostring(self:GetChecked()))
    ToxicifyDB.PartyWarningEnabled = self:GetChecked()
    ns.Core.DebugPrint("PartyWarningEnabled set to: " .. tostring(ToxicifyDB.PartyWarningEnabled))
    
    -- Update description
    partyWarningDesc:SetText("Shows a warning popup when joining parties with toxic players.")
end)

-- Party Warning description
local partyWarningDesc = generalPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
partyWarningDesc:SetPoint("TOPLEFT", partyWarningCheck, "BOTTOMLEFT", 0, -5)
partyWarningDesc:SetWidth(400)
partyWarningDesc:SetJustifyH("LEFT")
partyWarningDesc:SetText("Shows a warning popup when joining parties with toxic players.")

-- Target Frame Indicator
local targetFrameCheck = CreateFrame("CheckButton", nil, generalPanel, "InterfaceOptionsCheckButtonTemplate")
targetFrameCheck:SetPoint("TOPLEFT", partyWarningDesc, "BOTTOMLEFT", 0, -15)
targetFrameCheck.Text:SetText("Show Toxic/Pumper indicator above target frame")
targetFrameCheck:SetChecked(ToxicifyDB.TargetFrameIndicatorEnabled or true)
targetFrameCheck:SetScript("OnClick", function(self)
    ToxicifyDB.TargetFrameIndicatorEnabled = self:GetChecked()
    ns.Core.DebugPrint("Target frame indicator " .. (self:GetChecked() and "enabled" or "disabled"))
    
    -- Update description
    targetFrameDesc:SetText("Shows a small indicator above the target frame when targeting toxic or pumper players.")
    
    -- Update target frame immediately - force update even if no target change
    if ns.Events and ns.Events.UpdateTargetFrame then
        -- Force a target frame update by calling it directly
        ns.Events.UpdateTargetFrame()
        
        -- Also trigger a PLAYER_TARGET_CHANGED event to ensure immediate reaction
        if _G.TargetFrame and UnitExists("target") then
            -- Force refresh the target frame indicator
            C_Timer.After(0.1, function()
                ns.Events.UpdateTargetFrame()
            end)
        end
    end
end)

-- Target Frame Indicator description
local targetFrameDesc = generalPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
targetFrameDesc:SetPoint("TOPLEFT", targetFrameCheck, "BOTTOMLEFT", 0, -5)
targetFrameDesc:SetWidth(400)
targetFrameDesc:SetJustifyH("LEFT")
targetFrameDesc:SetText("Shows a small indicator above the target frame when targeting toxic or pumper players")

-- Guild Toast Notifications
local guildToastCheck = CreateFrame("CheckButton", nil, generalPanel, "InterfaceOptionsCheckButtonTemplate")
guildToastCheck:SetPoint("TOPLEFT", targetFrameDesc, "BOTTOMLEFT", 0, -15)
guildToastCheck.Text:SetText("Show toast notifications when guild members come online")
guildToastCheck:SetChecked(ToxicifyDB.GuildToastEnabled or true)
guildToastCheck:SetScript("OnClick", function(self)
    ToxicifyDB.GuildToastEnabled = self:GetChecked()
    ns.Core.DebugPrint("Guild toast notifications " .. (self:GetChecked() and "enabled" or "disabled"))
end)

-- Guild Toast description
local guildToastDesc = generalPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
guildToastDesc:SetPoint("TOPLEFT", guildToastCheck, "BOTTOMLEFT", 0, -5)
guildToastDesc:SetWidth(400)
guildToastDesc:SetJustifyH("LEFT")
guildToastDesc:SetText("Shows a toast notification when guild members marked as toxic/pumper come online.")

-- Auto-Close Timer
local autoCloseLabel = generalPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
autoCloseLabel:SetPoint("TOPLEFT", guildToastDesc, "BOTTOMLEFT", 0, -15)
autoCloseLabel:SetText("Auto-Close Timer (seconds):")

-- Auto-Close Timer description
local autoCloseDesc = generalPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
autoCloseDesc:SetPoint("TOPLEFT", autoCloseLabel, "BOTTOMLEFT", 0, -5)
autoCloseDesc:SetWidth(400)
autoCloseDesc:SetJustifyH("LEFT")
autoCloseDesc:SetText("How long the warning popup stays open before automatically closing. Range: 1-300 seconds")

-- Auto-Close timer slider
local autoCloseSlider = CreateFrame("Slider", nil, generalPanel, "OptionsSliderTemplate")
autoCloseSlider:SetPoint("TOPLEFT", autoCloseDesc, "BOTTOMLEFT", 0, -10)
autoCloseSlider:SetSize(200, 20)
autoCloseSlider:SetMinMaxValues(1, 300)
autoCloseSlider:SetValue(ToxicifyDB.PopupTimerSeconds or 25)
autoCloseSlider:SetValueStep(1)
autoCloseSlider:SetObeyStepOnDrag(true)

-- Slider text
autoCloseSlider.Low:SetText("1s")
autoCloseSlider.High:SetText("300s")

-- Value display
local autoCloseValue = autoCloseSlider:CreateFontString(nil, "OVERLAY", "GameFontNormal")
autoCloseValue:SetPoint("LEFT", autoCloseSlider, "RIGHT", 10, 0)
autoCloseValue:SetText(tostring(ToxicifyDB.PopupTimerSeconds or 25) .. "s")

-- Initialize slider
autoCloseSlider:SetScript("OnValueChanged", function(self, value)
    local intValue = math.floor(value + 0.5)
    ToxicifyDB.PopupTimerSeconds = intValue
    autoCloseValue:SetText(intValue .. "s")
    ns.Core.DebugPrint("Auto-Close timer set to: " .. intValue .. " seconds")
end)

-- Lua errors toggle (only visible when debug is enabled)
local luaErrorsCheck = CreateFrame("CheckButton", nil, generalPanel, "InterfaceOptionsCheckButtonTemplate")
luaErrorsCheck:SetPoint("TOPLEFT", autoCloseSlider, "BOTTOMLEFT", 0, -15)
luaErrorsCheck.Text:SetText("Show Lua errors in chat (Debug mode only)")
luaErrorsCheck:SetChecked(ToxicifyDB.LuaErrorsEnabled or false)
-- Lua Errors description
local luaErrorsDesc = generalPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")

luaErrorsCheck:SetScript("OnClick", function(self)
    local enabled = self:GetChecked()
    ToxicifyDB.LuaErrorsEnabled = enabled
    
    -- Update description
    luaErrorsDesc:SetText("Shows Lua errors in chat for debugging. Requires debug mode to be enabled.")
    
    -- Set console scriptErrors based on toggle
    if enabled then
        SetCVar("scriptErrors", "1")
        print("|cff39FF14[Toxicify Debug]:|r Lua errors enabled - /console scriptErrors set to 1")
    else
        SetCVar("scriptErrors", "0")
        print("|cff39FF14[Toxicify Debug]:|r Lua errors disabled - /console scriptErrors set to 0")
    end
end)
luaErrorsDesc:SetPoint("TOPLEFT", luaErrorsCheck, "BOTTOMLEFT", 0, -5)
luaErrorsDesc:SetWidth(400)
luaErrorsDesc:SetJustifyH("LEFT")
luaErrorsDesc:SetText("Shows Lua errors in chat for debugging. Requires debug mode to be enabled.")


-- Panel OnShow
generalPanel:SetScript("OnShow", function()
    -- Initialize hide toxic groups checkbox and description
    hideCheck:SetChecked(ToxicifyDB.HideInFinder or false)
    hideDesc:SetText("Filters out groups with toxic leaders in Premade Groups.")
    
    -- Initialize party warning checkbox and description
    partyWarningCheck:SetChecked(ToxicifyDB.PartyWarningEnabled or true)
    partyWarningDesc:SetText("Shows a warning popup when joining parties with toxic players.")
    
    -- Initialize target frame indicator checkbox and description
    targetFrameCheck:SetChecked(ToxicifyDB.TargetFrameIndicatorEnabled or true)
    targetFrameDesc:SetText("Shows a small indicator above the target frame when targeting toxic or pumper players.")
    
    -- Initialize Auto-Close timer slider
    autoCloseSlider:SetValue(ToxicifyDB.PopupTimerSeconds or 25)
    autoCloseValue:SetText(tostring(ToxicifyDB.PopupTimerSeconds or 25) .. "s")
    
    -- Show/hide Lua errors toggle based on debug mode
    if ToxicifyDB.DebugEnabled then
        luaErrorsCheck:Show()
        luaErrorsDesc:Show()
        -- Sync toggle with current scriptErrors setting
        local scriptErrorsEnabled = GetCVar("scriptErrors") == "1"
        luaErrorsCheck:SetChecked(scriptErrorsEnabled)
        ToxicifyDB.LuaErrorsEnabled = scriptErrorsEnabled
        -- Update description
        luaErrorsDesc:SetText("Shows Lua errors in chat for debugging. Requires debug mode to be enabled.")
    else
        luaErrorsCheck:Hide()
        luaErrorsDesc:Hide()
    end
end)

---------------------------------------------------
-- Import / Export (elegant buttons)
---------------------------------------------------
local ioLabel = generalPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
ioLabel:SetPoint("TOPLEFT", luaErrorsDesc, "BOTTOMLEFT", 0, -30)
ioLabel:SetText("Import / Export List:")

-- Export button
local exportBtn = CreateFrame("Button", nil, generalPanel, "UIPanelButtonTemplate")
exportBtn:SetSize(120, 30)
exportBtn:SetPoint("TOPLEFT", ioLabel, "BOTTOMLEFT", 0, -10)
exportBtn:SetText("Export List")
exportBtn:SetScript("OnClick", function()
    ns.UI.ShowIOPopup("export")
end)

-- Import button
local importBtn = CreateFrame("Button", nil, generalPanel, "UIPanelButtonTemplate")
importBtn:SetSize(120, 30)
importBtn:SetPoint("LEFT", exportBtn, "RIGHT", 10, 0)
importBtn:SetText("Import List")
importBtn:SetScript("OnClick", function()
    ns.UI.ShowIOPopup("import")
end)

-- Footer for General Panel
local footer = generalPanel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
footer:SetPoint("BOTTOMLEFT", 20, 20)
footer:SetText(ns.Core.GetFooterText())

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

-- Footer for List Panel
local listFooter = listPanel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
listFooter:SetPoint("BOTTOMLEFT", 20, 20)
listFooter:SetText(ns.Core.GetFooterText())

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
ioDesc:SetText("Import or export your toxic/pumper player list. Data is encoded for security and automatically handled via clipboard.")

-- Export button
local exportBtn = CreateFrame("Button", nil, ioPanel, "UIPanelButtonTemplate")
exportBtn:SetSize(150, 40)
exportBtn:SetPoint("TOPLEFT", ioDesc, "BOTTOMLEFT", 50, -30)
exportBtn:SetText("Export List")
exportBtn:SetScript("OnClick", function()
    ns.UI.ShowIOPopup("export")
end)

-- Import button
local importBtn = CreateFrame("Button", nil, ioPanel, "UIPanelButtonTemplate")
importBtn:SetSize(150, 40)
importBtn:SetPoint("LEFT", exportBtn, "RIGHT", 50, 0)
importBtn:SetText("Import List")
importBtn:SetScript("OnClick", function()
    ns.UI.ShowIOPopup("import")
end)

-- Footer for IO Panel
local ioFooter = ioPanel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
ioFooter:SetPoint("BOTTOMLEFT", 20, 20)
ioFooter:SetText(ns.Core.GetFooterText())

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

-- Whisper description
local whisperDesc = whisperPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
whisperDesc:SetPoint("TOPLEFT", whisperCheck, "BOTTOMLEFT", 0, -5)
whisperDesc:SetWidth(400)
whisperDesc:SetJustifyH("LEFT")
whisperDesc:SetText("Automatically whisper players when they are marked as toxic.")

local ignoreCheck = CreateFrame("CheckButton", "ToxicifyIgnoreCheck", whisperPanel, "InterfaceOptionsCheckButtonTemplate")
ignoreCheck:SetPoint("TOPLEFT", whisperDesc, "BOTTOMLEFT", 0, -15)
ignoreCheck.Text:SetText("Also add toxic players to Ignore list")

-- Ignore description
local ignoreDesc = whisperPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
ignoreDesc:SetPoint("TOPLEFT", ignoreCheck, "BOTTOMLEFT", 0, -5)
ignoreDesc:SetWidth(400)
ignoreDesc:SetJustifyH("LEFT")
ignoreDesc:SetText("Adds toxic players to your ignore list when they are marked as toxic.")

local partyWarningCheck = CreateFrame("CheckButton", "ToxicifyPartyWarningCheck", whisperPanel, "InterfaceOptionsCheckButtonTemplate")
partyWarningCheck:SetPoint("TOPLEFT", ignoreDesc, "BOTTOMLEFT", 0, -15)
partyWarningCheck.Text:SetText("Show warning when joining party with toxic/pumper players")
partyWarningCheck:SetChecked(ToxicifyDB.PartyWarningEnabled or true)

-- Create a label for the whisper box
local whisperLabel = whisperPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
whisperLabel:SetPoint("TOPLEFT", partyWarningCheck, "BOTTOMLEFT", 0, -15)
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
    
    -- Also initialize Auto-Close timer slider with delay
    autoCloseSlider:SetValue(ToxicifyDB.PopupTimerSeconds or 25)
    autoCloseValue:SetText(tostring(ToxicifyDB.PopupTimerSeconds or 25) .. "s")
end)

whisperPanel:SetScript("OnShow", function()
    EnsureDefaults()
    whisperCheck:SetChecked(ToxicifyDB.WhisperOnMark)
    ignoreCheck:SetChecked(ToxicifyDB.IgnoreOnMark)
    partyWarningCheck:SetChecked(ToxicifyDB.PartyWarningEnabled)
    
    -- Initialize descriptions
    whisperDesc:SetText("Automatically whisper players when they are marked as toxic.")
    ignoreDesc:SetText("Adds toxic players to your ignore list when they are marked as toxic.")
    
    -- Force set the default message
    local defaultMsg = "U have been marked as Toxic player by - Toxicify Addon"
    local currentMsg = ToxicifyDB.WhisperMessage or defaultMsg
    InitializeEditBox(whisperBox, currentMsg, "OnShow whisper message")
end)

whisperCheck:SetScript("OnClick", function(self)
    ToxicifyDB.WhisperOnMark = self:GetChecked()
    -- Always keep the editbox enabled so users can see and edit the message
    whisperBox:Enable()
    
    -- Update description
    whisperDesc:SetText("Automatically whisper players when they are marked as toxic.")
end)

ignoreCheck:SetScript("OnClick", function(self)
    ToxicifyDB.IgnoreOnMark = self:GetChecked()
    
    -- Update description
    ignoreDesc:SetText("Adds toxic players to your ignore list when they are marked as toxic.")
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
    whisperBox:ClearFocus()
end)

-- Footer for Whisper Panel
local whisperFooter = whisperPanel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
whisperFooter:SetPoint("BOTTOMLEFT", 20, 20)
whisperFooter:SetText(ns.Core.GetFooterText())

---------------------------------------------------
-- Root Info Panel
---------------------------------------------------
local rootPanel = CreateFrame("Frame", "ToxicifyRootPanel")
rootPanel.name = "Toxicify"

local titleRoot = rootPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
titleRoot:SetPoint("TOPLEFT", 16, -16)
titleRoot:SetText("|cff39FF14Toxicify|r")

-- Create scrollable frame for description
local descScrollFrame = CreateFrame("ScrollFrame", nil, rootPanel, "UIPanelScrollFrameTemplate")
descScrollFrame:SetPoint("TOPLEFT", titleRoot, "BOTTOMLEFT", 0, -8)
descScrollFrame:SetPoint("BOTTOMRIGHT", rootPanel, "BOTTOMRIGHT", -21, 16)
descScrollFrame:SetWidth(595)

-- Create the scroll child frame
local descScrollChild = CreateFrame("Frame", nil, descScrollFrame)
descScrollChild:SetSize(575, 1) -- Height will be set by content
descScrollFrame:SetScrollChild(descScrollChild)

-- Create the text in the scroll child
local descRoot = descScrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
descRoot:SetPoint("TOPLEFT", descScrollChild, "TOPLEFT", 0, 0)
descRoot:SetWidth(575)
descRoot:SetJustifyH("LEFT")
descRoot:SetText([[
|cff39FF14Toxicify|r - Mark players as |cffff0000Toxic|r or |cff00ff00Pumper|r

|cff39FF14Core Features:|r
• Highlight toxic/pumper players in Party/Raid frames
• Warning popup when joining parties with toxic players
• Filter toxic groups in Group Finder
• Import/Export player lists

|cff39FF14Essential Commands:|r
|cffFFFFFF/toxic add <name>|r - Mark as Toxic
|cffFFFFFF/toxic addpumper <name>|r - Mark as Pumper
|cffFFFFFF/toxic del <name>|r - Remove player
|cffFFFFFF/toxic ui|r - Open player list
|cffFFFFFF/toxic settings|r - Open settings

Keep your runs clean and enjoyable!

|cff39FF14Alvarín-Silvermoon|r
]])

-- Update scroll child height based on text content
local textHeight = descRoot:GetStringHeight()
descScrollChild:SetHeight(textHeight)

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

-- Footer for Root Panel
local rootFooter = rootPanel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
rootFooter:SetPoint("BOTTOMLEFT", 20, 20)
rootFooter:SetText(ns.Core.GetFooterText())

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
    
    -- Store reference globally for easy access from commands
    _G.ToxicifySettingsCategory = root
else
    -- Classic
    InterfaceOptions_AddCategory(rootPanel)
    InterfaceOptions_AddCategory(generalPanel)
    InterfaceOptions_AddCategory(listPanel)
    InterfaceOptions_AddCategory(ioPanel)
    InterfaceOptions_AddCategory(whisperPanel)
end
