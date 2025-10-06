-- OptionsWhisper.lua
-- Whisper & Ignore Settings panel for Toxicify
local addonName, ns = ...

-- Get utilities from OptionsCore
local Binder = ns.OptionsCore.Binder
local BindCheckbox = ns.OptionsCore.BindCheckbox
local BindEditBoxText = ns.OptionsCore.BindEditBoxText

-- ==================================================
-- WHISPER PANEL
-- ==================================================
local whisperPanel = CreateFrame("Frame", "ToxicifyWhisperOptionsPanel")
whisperPanel.name = "Whisper Settings"

local title2 = whisperPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title2:SetPoint("TOPLEFT", 16, -16)
title2:SetText("|cff39FF14Toxicify|r - Whisper & Ignore Settings")

local desc2 = whisperPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
desc2:SetPoint("TOPLEFT", title2, "BOTTOMLEFT", 0, -8)
desc2:SetWidth(500); desc2:SetJustifyH("LEFT")
desc2:SetText("Configure whisper behavior and automatic ignore. If enabled, Toxicify will whisper and/or ignore players when they are marked as toxic.")

local whisperCheck = CreateFrame("CheckButton", "ToxicifyWhisperCheck", whisperPanel, "InterfaceOptionsCheckButtonTemplate")
whisperCheck:SetPoint("TOPLEFT", desc2, "BOTTOMLEFT", 0, -10)
whisperCheck.Text:SetText("Whisper players when marked toxic")

local whisperDesc = whisperPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
whisperDesc:SetPoint("TOPLEFT", whisperCheck, "BOTTOMLEFT", 0, -5)
whisperDesc:SetWidth(400); whisperDesc:SetJustifyH("LEFT")
whisperDesc:SetText("Automatically whisper players when they are marked as toxic.")

local ignoreCheck = CreateFrame("CheckButton", "ToxicifyIgnoreCheck", whisperPanel, "InterfaceOptionsCheckButtonTemplate")
ignoreCheck:SetPoint("TOPLEFT", whisperDesc, "BOTTOMLEFT", 0, -15)
ignoreCheck.Text:SetText("Also add toxic players to Ignore list")

local ignoreDesc = whisperPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
ignoreDesc:SetPoint("TOPLEFT", ignoreCheck, "BOTTOMLEFT", 0, -5)
ignoreDesc:SetWidth(400); ignoreDesc:SetJustifyH("LEFT")
ignoreDesc:SetText("Adds toxic players to your ignore list when they are marked as toxic.")

-- unieke naam (W)
local partyWarningCheck_W = CreateFrame("CheckButton", "ToxicifyPartyWarningCheck", whisperPanel, "InterfaceOptionsCheckButtonTemplate")
partyWarningCheck_W:SetPoint("TOPLEFT", ignoreDesc, "BOTTOMLEFT", 0, -15)
partyWarningCheck_W.Text:SetText("Show warning when joining party with toxic/pumper players")

local whisperLabel = whisperPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
whisperLabel:SetPoint("TOPLEFT", partyWarningCheck_W, "BOTTOMLEFT", 0, -15)
whisperLabel:SetText("Whisper:"); whisperLabel:SetTextColor(1,1,1)

local whisperBox = CreateFrame("EditBox", "ToxicifyWhisperBox", whisperPanel, "InputBoxTemplate")
whisperBox:SetSize(400, 30)
whisperBox:SetPoint("LEFT", whisperLabel, "RIGHT", 10, 0)
whisperBox:SetAutoFocus(false); whisperBox:SetMaxLetters(200)
whisperBox:SetFontObject("GameFontNormal"); whisperBox:SetTextColor(1,1,1)
whisperBox:SetTextInsets(5,5,0,0)

-- Bindings (alles registreert zichzelf in Binder)
BindCheckbox(whisperCheck,        "WhisperOnMark",       false, nil, "WhisperOnMark")
BindCheckbox(ignoreCheck,         "IgnoreOnMark",        false, nil, "IgnoreOnMark")
BindCheckbox(partyWarningCheck_W, "PartyWarningEnabled", true,  nil, "PartyWarningEnabled(W)")

-- Editbox: saven mag altijd (of alleen bij enabled: geef whenEnabledFn mee)
BindEditBoxText(
  whisperBox,
  "WhisperMessage",
  "U have been marked as Toxic player by - Toxicify Addon",
  nil, -- of: function() return DBGet("WhisperOnMark", false) end
  "WhisperMessage"
)

whisperPanel:SetScript("OnShow", function()
  Binder:hydrateAll("Whisper:OnShow")
end)

local whisperFooter = whisperPanel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
whisperFooter:SetPoint("BOTTOMLEFT", 20, 20)
whisperFooter:SetText(ns.Core.GetFooterText())

-- Export the panel for registration
ns.OptionsWhisper = {
  panel = whisperPanel
}
