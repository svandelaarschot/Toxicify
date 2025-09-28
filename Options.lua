local addonName, ns = ...
local panel = CreateFrame("Frame", "ToxicifyOptionsPanel", InterfaceOptionsFramePanelContainer)
panel.name = "Toxicify"

local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("|cff39FF14Toxicify|r")

local desc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
desc:SetWidth(400)
desc:SetText("Beheer je lijst met toxic spelers. Deze worden rood gemarkeerd in je party en de Group Finder.\n\nJe kunt namen toevoegen met de knop of via /toxic add Naam.")

-- Editbox om naam toe te voegen
local input = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
input:SetSize(200, 30)
input:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -20)
input:SetAutoFocus(false)
input:SetMaxLetters(50)

-- Checkbox: verberg toxic spelers in Group Finder
local hideCheck = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
hideCheck:SetPoint("TOPLEFT", input, "BOTTOMLEFT", 0, -240)
hideCheck.Text:SetText("Verberg toxic spelers in Premade Groups")
hideCheck:SetChecked(ToxicifyDB.HideInFinder or false)

hideCheck:SetScript("OnClick", function(self)
    ToxicifyDB.HideInFinder = self:GetChecked()
end)

-- Toevoegen knop
local addBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
addBtn:SetSize(80, 22)
addBtn:SetPoint("LEFT", input, "RIGHT", 5, 0)
addBtn:SetText("Toevoegen")

-- ScrollFrame voor toxic lijst
local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", input, "BOTTOMLEFT", 0, -20)
scrollFrame:SetSize(300, 200)

local content = CreateFrame("Frame", nil, scrollFrame)
content:SetSize(300, 200)
scrollFrame:SetScrollChild(content)

local function RefreshList()
    for i, child in ipairs(content.children or {}) do
        child:Hide()
    end
    content.ch
