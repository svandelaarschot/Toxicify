local addonName, ns = ...
ToxicifyDB = ToxicifyDB or {}

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
        ns.MarkToxic(name)
        input:SetText("")
        RefreshList()
    end
end)

-- Add pumper
addPumperBtn:SetScript("OnClick", function()
    local name = input:GetText()
    if name and name ~= "" then
        ns.MarkPumper(name)
        input:SetText("")
        RefreshList()
    end
end)

-- Zorg dat RefreshList er boven staat
local function RefreshList()
    if content and content:IsShown() then
        ns.RefreshSharedList(content)
    end
end

-- Panel OnShow
generalPanel:SetScript("OnShow", RefreshList)

-- Forceer 1x initial load zodat lijst meteen zichtbaar is
C_Timer.After(0.1, RefreshList)

---------------------------------------------------
-- Import / Export (strakke layout + textarea)
---------------------------------------------------
local ioLabel = generalPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
ioLabel:SetPoint("TOPLEFT", scrollFrame, "BOTTOMLEFT", 0, -30)
ioLabel:SetText("Import / Export List:")

-- ScrollFrame + Multiline EditBox
local ioScroll = CreateFrame("ScrollFrame", "ToxicifyIOScroll", generalPanel, "UIPanelScrollFrameTemplate")
ioScroll:SetPoint("TOPLEFT", ioLabel, "BOTTOMLEFT", 0, -10)
ioScroll:SetSize(400, 100)

local ioBox = CreateFrame("EditBox", "ToxicifyIOBox", ioScroll)
ioBox:SetMultiLine(true)
ioBox:SetSize(380, 100)
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
    local export = ns.ExportList()
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
    local ok, result = ns.ImportList(text)
    if ok then
        print("|cff39FF14Toxicify:|r Import success: " .. result)
        RefreshList()
    else
        print("|cffff0000Toxicify:|r Import failed: " .. result)
    end
end)

---------------------------------------------------
-- Whisper & Ignore Panel
---------------------------------------------------
local whisperPanel = CreateFrame("Frame", "ToxicifyWhisperOptionsPanel")
whisperPanel.name = "Whisper"

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

local whisperBox = CreateFrame("EditBox", "ToxicifyWhisperBox", whisperPanel, "InputBoxTemplate")
whisperBox:SetSize(400, 30)
whisperBox:SetPoint("TOPLEFT", ignoreCheck, "BOTTOMLEFT", 0, -10)
whisperBox:SetAutoFocus(false)
whisperBox:SetMaxLetters(200)

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
end

EnsureDefaults()
whisperCheck:SetChecked(ToxicifyDB.WhisperOnMark)
ignoreCheck:SetChecked(ToxicifyDB.IgnoreOnMark)
whisperBox:SetText(ToxicifyDB.WhisperMessage)
if whisperCheck:GetChecked() then whisperBox:Enable() else whisperBox:Disable() end

whisperPanel:SetScript("OnShow", function()
    EnsureDefaults()
    whisperCheck:SetChecked(ToxicifyDB.WhisperOnMark)
    ignoreCheck:SetChecked(ToxicifyDB.IgnoreOnMark)
    whisperBox:SetText(ToxicifyDB.WhisperMessage)
    if whisperCheck:GetChecked() then whisperBox:Enable() else whisperBox:Disable() end
end)

whisperCheck:SetScript("OnClick", function(self)
    ToxicifyDB.WhisperOnMark = self:GetChecked()
    if self:GetChecked() then whisperBox:Enable() else whisperBox:Disable() end
end)

ignoreCheck:SetScript("OnClick", function(self)
    ToxicifyDB.IgnoreOnMark = self:GetChecked()
end)

whisperBox:SetScript("OnTextChanged", function(self)
    if whisperCheck:GetChecked() then
        ToxicifyDB.WhisperMessage = self:GetText()
    end
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

---------------------------------------------------
-- Register Panels (Retail vs Classic)
---------------------------------------------------
if Settings and Settings.RegisterAddOnCategory then
    -- Retail (Dragonflight+)
    local root = Settings.RegisterCanvasLayoutCategory(rootPanel, rootPanel.name)

    -- Subpanels
    Settings.RegisterCanvasLayoutSubcategory(root, generalPanel, generalPanel.name)
    Settings.RegisterCanvasLayoutSubcategory(root, whisperPanel, whisperPanel.name)

    Settings.RegisterAddOnCategory(root)
else
    -- Classic
    InterfaceOptions_AddCategory(rootPanel)
    InterfaceOptions_AddCategory(generalPanel)
    InterfaceOptions_AddCategory(whisperPanel)
end
