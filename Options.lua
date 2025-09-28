local addonName, ns = ...
ToxicifyDB = ToxicifyDB or {}

---------------------------------------------------
-- General Settings Panel
---------------------------------------------------
local generalPanel = CreateFrame("Frame", "ToxicifyGeneralOptionsPanel")
generalPanel.name = "General"

local title = generalPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("|cff39FF14Toxicify|r - General Settings")

local desc = generalPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
desc:SetWidth(500)
desc:SetText("Manage your toxic/pumper player list. They will be marked in party/raid frames and in the Group Finder.\n\nYou can add names manually below or with /toxic add Name-Realm.")

-- Input + add buttons
local input = CreateFrame("EditBox", nil, generalPanel, "InputBoxTemplate")
input:SetSize(200, 30)
input:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -20)
input:SetAutoFocus(false)
input:SetMaxLetters(50)

local addToxicBtn = CreateFrame("Button", nil, generalPanel, "UIPanelButtonTemplate")
addToxicBtn:SetSize(100, 22)
addToxicBtn:SetPoint("LEFT", input, "RIGHT", 5, 0)
addToxicBtn:SetText("Add Toxic")

local addPumperBtn = CreateFrame("Button", nil, generalPanel, "UIPanelButtonTemplate")
addPumperBtn:SetSize(100, 22)
addPumperBtn:SetPoint("LEFT", addToxicBtn, "RIGHT", 5, 0)
addPumperBtn:SetText("Add Pumper")

-- Hide in finder
local hideCheck = CreateFrame("CheckButton", nil, generalPanel, "InterfaceOptionsCheckButtonTemplate")
hideCheck:SetPoint("TOPLEFT", input, "BOTTOMLEFT", 0, -20)
hideCheck.Text:SetText("Hide toxic groups in Premade Groups")
hideCheck:SetChecked(ToxicifyDB.HideInFinder or false)
hideCheck:SetScript("OnClick", function(self)
    ToxicifyDB.HideInFinder = self:GetChecked()
end)

-- ScrollFrame for list
local scrollFrame = CreateFrame("ScrollFrame", nil, generalPanel, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", hideCheck, "BOTTOMLEFT", 0, -20)
scrollFrame:SetSize(400, 200)

local content = CreateFrame("Frame", nil, scrollFrame)
content:SetSize(400, 200)
scrollFrame:SetScrollChild(content)

local function RefreshList()
    ns.RefreshSharedList(content)
end

-- Add toxic
addToxicBtn:SetScript("OnClick", function()
    local name = input:GetText()
    if name and name ~= "" then
        ToxicifyDB[name] = "toxic"
        input:SetText("")
        RefreshList()
        print("|cffff0000Toxicify:|r Added toxic: " .. name)
    end
end)

-- Add pumper
addPumperBtn:SetScript("OnClick", function()
    local name = input:GetText()
    if name and name ~= "" then
        ToxicifyDB[name] = "pumper"
        input:SetText("")
        RefreshList()
        print("|cff00ff00Toxicify:|r Added pumper: " .. name)
    end
end)

generalPanel:SetScript("OnShow", RefreshList)

---------------------------------------------------
-- Whisper Settings Panel
---------------------------------------------------
local whisperPanel = CreateFrame("Frame", "ToxicifyWhisperOptionsPanel")
whisperPanel:SetScript("OnShow", function()
    whisperBox:SetText(ToxicifyDB.WhisperMessage or "U have been marked as Toxic player by - Toxicify Addon")
    whisperCheck:SetChecked(ToxicifyDB.WhisperOnMark or false)

    if whisperCheck:GetChecked() then
        whisperBox:Enable()
    else
        whisperBox:Disable()
    end
end)

whisperPanel.name = "Whisper"

local title2 = whisperPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title2:SetPoint("TOPLEFT", 16, -16)
title2:SetText("|cff39FF14Toxicify|r - Whisper Settings")

local desc2 = whisperPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
desc2:SetPoint("TOPLEFT", title2, "BOTTOMLEFT", 0, -8)
desc2:SetWidth(500)
desc2:SetText("Configure whisper behavior. If enabled, Toxicify will automatically whisper players when they are marked as toxic.")

local whisperCheck = CreateFrame("CheckButton", "ToxicifyWhisperCheck", whisperPanel, "InterfaceOptionsCheckButtonTemplate")
whisperCheck:SetPoint("TOPLEFT", desc2, "BOTTOMLEFT", 0, -10)
whisperCheck.Text:SetText("Whisper players when marked toxic")
whisperCheck:SetChecked(ToxicifyDB.WhisperOnMark or false)
---------------------------------------------------
-- Whisper Settings Panel
---------------------------------------------------
local whisperPanel = CreateFrame("Frame", "ToxicifyWhisperOptionsPanel")
whisperPanel.name = "Whisper"

local title2 = whisperPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title2:SetPoint("TOPLEFT", 16, -16)
title2:SetText("|cff39FF14Toxicify|r - Whisper Settings")

local desc2 = whisperPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
desc2:SetPoint("TOPLEFT", title2, "BOTTOMLEFT", 0, -8)
desc2:SetWidth(500)
desc2:SetText("Configure whisper behavior. If enabled, Toxicify will automatically whisper players when they are marked as toxic.")

-- Checkbox
local whisperCheck = CreateFrame("CheckButton", "ToxicifyWhisperCheck", whisperPanel, "InterfaceOptionsCheckButtonTemplate")
whisperCheck:SetPoint("TOPLEFT", desc2, "BOTTOMLEFT", 0, -10)
whisperCheck.Text:SetText("Whisper players when marked toxic")
---------------------------------------------------
-- Whisper Settings Panel
---------------------------------------------------
local whisperPanel = CreateFrame("Frame", "ToxicifyWhisperOptionsPanel")
whisperPanel.name = "Whisper"

local title2 = whisperPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title2:SetPoint("TOPLEFT", 16, -16)
title2:SetText("|cff39FF14Toxicify|r - Whisper & Ignore Settings")

local desc2 = whisperPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
desc2:SetPoint("TOPLEFT", title2, "BOTTOMLEFT", 0, -8)
desc2:SetWidth(500)
desc2:SetText("Configure whisper behavior and automatic ignore. If enabled, Toxicify will whisper and/or ignore players when they are marked as toxic.")

-- Checkbox: Whisper
local whisperCheck = CreateFrame("CheckButton", "ToxicifyWhisperCheck", whisperPanel, "InterfaceOptionsCheckButtonTemplate")
whisperCheck:SetPoint("TOPLEFT", desc2, "BOTTOMLEFT", 0, -10)
whisperCheck.Text:SetText("Whisper players when marked toxic")

-- Checkbox: Ignore
local ignoreCheck = CreateFrame("CheckButton", "ToxicifyIgnoreCheck", whisperPanel, "InterfaceOptionsCheckButtonTemplate")
ignoreCheck:SetPoint("TOPLEFT", whisperCheck, "BOTTOMLEFT", 0, -10)
ignoreCheck.Text:SetText("Also add toxic players to Ignore list")

-- Editbox
local whisperBox = CreateFrame("EditBox", "ToxicifyWhisperBox", whisperPanel, "InputBoxTemplate")
whisperBox:SetSize(400, 30)
whisperBox:SetPoint("TOPLEFT", ignoreCheck, "BOTTOMLEFT", 0, -10)
whisperBox:SetAutoFocus(false)
whisperBox:SetMaxLetters(200)

-- Ensure defaults
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
end

EnsureDefaults()

-- Init values
whisperCheck:SetChecked(ToxicifyDB.WhisperOnMark)
ignoreCheck:SetChecked(ToxicifyDB.IgnoreOnMark)
whisperBox:SetText(ToxicifyDB.WhisperMessage)

if whisperCheck:GetChecked() then
    whisperBox:Enable()
else
    whisperBox:Disable()
end

-- Refresh on show
whisperPanel:SetScript("OnShow", function()
    EnsureDefaults()
    whisperCheck:SetChecked(ToxicifyDB.WhisperOnMark)
    ignoreCheck:SetChecked(ToxicifyDB.IgnoreOnMark)
    whisperBox:SetText(ToxicifyDB.WhisperMessage)

    if whisperCheck:GetChecked() then
        whisperBox:Enable()
    else
        whisperBox:Disable()
    end
end)

-- Scripts
whisperCheck:SetScript("OnClick", function(self)
    ToxicifyDB.WhisperOnMark = self:GetChecked()
    if self:GetChecked() then
        whisperBox:Enable()
    else
        whisperBox:Disable()
    end
end)

ignoreCheck:SetScript("OnClick", function(self)
    ToxicifyDB.IgnoreOnMark = self:GetChecked()
end)

whisperBox:SetScript("OnTextChanged", function(self)
    if whisperCheck:GetChecked() then
        ToxicifyDB.WhisperMessage = self:GetText()
    end
end)

-- Add Toxic
local addToxicBtn = CreateFrame("Button", nil, generalPanel, "UIPanelButtonTemplate")
addToxicBtn:SetSize(100, 22)
addToxicBtn:SetPoint("LEFT", input, "RIGHT", 5, 0)
addToxicBtn:SetText("Add Toxic")
addToxicBtn:SetScript("OnClick", function()
    local name = input:GetText()
    if name and name ~= "" then
        ns.MarkToxic(name)
        input:SetText("")
        RefreshList()
    end
end)

-- Add Pumper
local addPumperBtn = CreateFrame("Button", nil, generalPanel, "UIPanelButtonTemplate")
addPumperBtn:SetSize(100, 22)
addPumperBtn:SetPoint("LEFT", addToxicBtn, "RIGHT", 5, 0)
addPumperBtn:SetText("Add Pumper")
addPumperBtn:SetScript("OnClick", function()
    local name = input:GetText()
    if name and name ~= "" then
        ns.MarkPumper(name)
        input:SetText("")
        RefreshList()
    end
end)


---------------------------------------------------
-- Register Panels
---------------------------------------------------
if Settings and Settings.RegisterAddOnCategory then
    -- Retail
    local root = Settings.RegisterVerticalLayoutCategory("|cff39FF14Toxicify|r")
    Settings.RegisterCanvasLayoutSubcategory(root, generalPanel, generalPanel.name)
    Settings.RegisterCanvasLayoutSubcategory(root, whisperPanel, whisperPanel.name)
    Settings.RegisterAddOnCategory(root)
else
    -- Classic
    InterfaceOptions_AddCategory(generalPanel)
    InterfaceOptions_AddCategory(whisperPanel)
end