-- OptionsIO.lua
-- Import/Export panel for Toxicify
local addonName, ns = ...

-- ==================================================
-- IO PANEL
-- ==================================================
local ioPanel = CreateFrame("Frame", "ToxicifyIOOptionsPanel")
ioPanel.name = "Import/Export"

local ioTitle = ioPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
ioTitle:SetPoint("TOPLEFT", 16, -16)
ioTitle:SetText("|cff39FF14Toxicify|r - Import / Export")

local ioDesc = ioPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
ioDesc:SetPoint("TOPLEFT", ioTitle, "BOTTOMLEFT", 0, -8)
ioDesc:SetWidth(500); ioDesc:SetJustifyH("LEFT")
ioDesc:SetText("Share your toxic/pumper player lists with friends or backup your data. All data is securely encoded and automatically copied to/from clipboard.")

local howItWorksTitle = ioPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
howItWorksTitle:SetPoint("TOPLEFT", ioDesc, "BOTTOMLEFT", 0, -20)
howItWorksTitle:SetText("|cff39FF14How it works:|r")

local howItWorksText = ioPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
howItWorksText:SetPoint("TOPLEFT", howItWorksTitle, "BOTTOMLEFT", 0, -5)
howItWorksText:SetWidth(500); howItWorksText:SetJustifyH("LEFT")
howItWorksText:SetText("• Export: Creates a secure, encoded string that's automatically copied to your clipboard\n• Import: Automatically detects and loads data from your clipboard\n• Share: Simply paste the exported string to friends - they can import it instantly")

local exportTitle = ioPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
exportTitle:SetPoint("TOPLEFT", howItWorksText, "BOTTOMLEFT", 0, -25)
exportTitle:SetText("|cff39FF14Export Your List:|r")

local exportBtn = CreateFrame("Button", nil, ioPanel, "UIPanelButtonTemplate")
exportBtn:SetSize(200, 35); exportBtn:SetPoint("TOPLEFT", exportTitle, "BOTTOMLEFT", 0, -10)
exportBtn:SetText("Export & Copy to Clipboard")
exportBtn:SetScript("OnClick", function() if ns.UI and ns.UI.ShowIOPopup then ns.UI.ShowIOPopup("export") end end)

local exportDesc = ioPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
exportDesc:SetPoint("TOPLEFT", exportBtn, "BOTTOMLEFT", 0, -5)
exportDesc:SetWidth(400); exportDesc:SetJustifyH("LEFT")
exportDesc:SetText("Creates a secure export string and copies it to clipboard. Share this with friends!")

local importTitle = ioPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
importTitle:SetPoint("TOPLEFT", exportDesc, "BOTTOMLEFT", 0, -25)
importTitle:SetText("|cff39FF14Import a Shared List:|r")

local importBtn = CreateFrame("Button", nil, ioPanel, "UIPanelButtonTemplate")
importBtn:SetSize(200, 35); importBtn:SetPoint("TOPLEFT", importTitle, "BOTTOMLEFT", 0, -10)
importBtn:SetText("Import from Clipboard")
importBtn:SetScript("OnClick", function() if ns.UI and ns.UI.ShowIOPopup then ns.UI.ShowIOPopup("import") end end)

local importDesc = ioPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
importDesc:SetPoint("TOPLEFT", importBtn, "BOTTOMLEFT", 0, -5)
importDesc:SetWidth(400); importDesc:SetJustifyH("LEFT")
importDesc:SetText("Automatically loads and imports data from clipboard. Paste a friend's export string first!")

local ioFooter = ioPanel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
ioFooter:SetPoint("BOTTOMLEFT", 20, 20)
ioFooter:SetText(ns.Core.GetFooterText())

-- Export the panel for registration
ns.OptionsIO = {
  panel = ioPanel
}
