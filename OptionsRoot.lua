-- OptionsRoot.lua
-- Main description panel for Toxicify
local addonName, ns = ...

-- ==================================================
-- ROOT PANEL
-- ==================================================
local rootPanel = CreateFrame("Frame", "ToxicifyRootPanel")
rootPanel.name = "Toxicify"

local titleRoot = rootPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
titleRoot:SetPoint("TOPLEFT", 16, -16)
titleRoot:SetText("|cff39FF14Toxicify|r")

local descScrollFrame = CreateFrame("ScrollFrame", nil, rootPanel, "UIPanelScrollFrameTemplate")
descScrollFrame:SetPoint("TOPLEFT", titleRoot, "BOTTOMLEFT", 0, -8)
descScrollFrame:SetPoint("BOTTOMRIGHT", rootPanel, "BOTTOMRIGHT", -21, 16)
descScrollFrame:SetWidth(595)

local descScrollChild = CreateFrame("Frame", nil, descScrollFrame)
descScrollChild:SetSize(575, 1)
descScrollFrame:SetScrollChild(descScrollChild)

local descRoot = descScrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
descRoot:SetPoint("TOPLEFT", descScrollChild, "TOPLEFT", 0, 0)
descRoot:SetWidth(575); descRoot:SetJustifyH("LEFT")
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

local textHeight = descRoot:GetStringHeight()
descScrollChild:SetHeight(textHeight)

rootPanel:SetScript("OnShow", function()
  if ns.UI and ns.UI.RefreshSharedList then ns.UI.RefreshSharedList() end
end)

local rootFooter = rootPanel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
rootFooter:SetPoint("BOTTOMLEFT", 20, 20)
rootFooter:SetText(ns.Core.GetFooterText())

-- Export the panel for registration
ns.OptionsRoot = {
  panel = rootPanel
}
