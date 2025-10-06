-- OptionsGeneral.lua
-- General settings panel for Toxicify
local addonName, ns = ...

-- Get utilities from OptionsCore
local Binder = ns.OptionsCore.Binder
local DBGet = ns.OptionsCore.DBGet
local DBSet = ns.OptionsCore.DBSet
local DPrint = ns.OptionsCore.DPrint
local BindCheckbox = ns.OptionsCore.BindCheckbox
local BindSlider = ns.OptionsCore.BindSlider

-- ==================================================
-- GENERAL PANEL
-- ==================================================
local generalPanel = CreateFrame("Frame", "ToxicifyGeneralOptionsPanel")
generalPanel.name = "General"

local title = generalPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("|cff39FF14Toxicify|r - General Settings")

local desc = generalPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
desc:SetWidth(500); desc:SetJustifyH("LEFT")
desc:SetText("General settings for the Toxicify addon. Configure basic behavior and party warnings.")

-- Hide in finder
local hideCheck = CreateFrame("CheckButton", nil, generalPanel, "InterfaceOptionsCheckButtonTemplate")
hideCheck:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -20)
hideCheck.Text:SetText("Hide toxic groups in Premade Groups")
local hideDesc = generalPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
hideDesc:SetPoint("TOPLEFT", hideCheck, "BOTTOMLEFT", 0, -5)
hideDesc:SetWidth(400); hideDesc:SetJustifyH("LEFT")
hideDesc:SetText("Filters out groups with toxic leaders in Premade Groups.")
BindCheckbox(hideCheck, "HideInFinder", false, nil, "HideInFinder")

-- Party warning
local partyWarningCheck = CreateFrame("CheckButton", nil, generalPanel, "InterfaceOptionsCheckButtonTemplate")
partyWarningCheck:SetPoint("TOPLEFT", hideDesc, "BOTTOMLEFT", 0, -15)
partyWarningCheck.Text:SetText("Show warning when joining party with toxic/pumper players")
local partyWarningDesc = generalPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
partyWarningDesc:SetPoint("TOPLEFT", partyWarningCheck, "BOTTOMLEFT", 0, -5)
partyWarningDesc:SetWidth(400); partyWarningDesc:SetJustifyH("LEFT")
partyWarningDesc:SetText("Shows a warning popup when joining parties with toxic players.")
BindCheckbox(partyWarningCheck, "PartyWarningEnabled", true, function(_, v)
  DPrint("PartyWarningEnabled now "..tostring(v))
end, "PartyWarningEnabled")

-- Suppress warnings during runs
local suppressRunWarningCheck = CreateFrame("CheckButton", nil, generalPanel, "InterfaceOptionsCheckButtonTemplate")
suppressRunWarningCheck:SetPoint("TOPLEFT", partyWarningDesc, "BOTTOMLEFT", 0, -15)
suppressRunWarningCheck.Text:SetText("Suppress warnings during key runs/dungeons")
local suppressRunWarningDesc = generalPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
suppressRunWarningDesc:SetPoint("TOPLEFT", suppressRunWarningCheck, "BOTTOMLEFT", 0, -5)
suppressRunWarningDesc:SetWidth(400); suppressRunWarningDesc:SetJustifyH("LEFT")
suppressRunWarningDesc:SetText("Prevents toxic/pumper warnings during active dungeon or key runs.")
BindCheckbox(suppressRunWarningCheck, "SuppressWarningsDuringRuns", false, nil, "SuppressWarningsDuringRuns")

-- Target Frame Indicator
local targetFrameCheck = CreateFrame("CheckButton", nil, generalPanel, "InterfaceOptionsCheckButtonTemplate")
targetFrameCheck:SetPoint("TOPLEFT", suppressRunWarningDesc, "BOTTOMLEFT", 0, -15)
targetFrameCheck.Text:SetText("Show Toxic/Pumper indicator above target frame")
local targetFrameDesc = generalPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
targetFrameDesc:SetPoint("TOPLEFT", targetFrameCheck, "BOTTOMLEFT", 0, -5)
targetFrameDesc:SetWidth(400); targetFrameDesc:SetJustifyH("LEFT")
targetFrameDesc:SetText("Shows a small indicator above the target frame when targeting toxic or pumper players")
BindCheckbox(targetFrameCheck, "TargetFrameIndicatorEnabled", true, function()
  if ns.Events and ns.Events.UpdateTargetFrame then
    ns.Events.UpdateTargetFrame()
    if _G.TargetFrame and UnitExists("target") then
      C_Timer.After(0.1, function() ns.Events.UpdateTargetFrame() end)
    end
  end
end, "TargetFrameIndicatorEnabled")

-- Guild toast
local guildToastCheck = CreateFrame("CheckButton", nil, generalPanel, "InterfaceOptionsCheckButtonTemplate")
guildToastCheck:SetPoint("TOPLEFT", targetFrameDesc, "BOTTOMLEFT", 0, -15)
guildToastCheck.Text:SetText("Show toast notifications when guild members come online")
local guildToastDesc = generalPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
guildToastDesc:SetPoint("TOPLEFT", guildToastCheck, "BOTTOMLEFT", 0, -5)
guildToastDesc:SetWidth(400); guildToastDesc:SetJustifyH("LEFT")
guildToastDesc:SetText("Shows a toast notification when guild members marked as toxic/pumper come online.")
BindCheckbox(guildToastCheck, "GuildToastEnabled", false, nil, "GuildToastEnabled")

-- Auto-Close Timer
local autoCloseLabel = generalPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
autoCloseLabel:SetPoint("TOPLEFT", guildToastDesc, "BOTTOMLEFT", 0, -15)
autoCloseLabel:SetText("Auto-Close Timer (seconds):")
local autoCloseDesc = generalPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
autoCloseDesc:SetPoint("TOPLEFT", autoCloseLabel, "BOTTOMLEFT", 0, -5)
autoCloseDesc:SetWidth(400); autoCloseDesc:SetJustifyH("LEFT")
autoCloseDesc:SetText("How long the warning popup stays open before automatically closing. Range: 1-300 seconds")
local autoCloseSlider = CreateFrame("Slider", nil, generalPanel, "OptionsSliderTemplate")
autoCloseSlider:SetPoint("TOPLEFT", autoCloseDesc, "BOTTOMLEFT", 0, -10)
autoCloseSlider:SetSize(200, 20)
autoCloseSlider.Low:SetText("1s"); autoCloseSlider.High:SetText("300s")
local autoCloseValue = autoCloseSlider:CreateFontString(nil, "OVERLAY", "GameFontNormal")
autoCloseValue:SetPoint("LEFT", autoCloseSlider, "RIGHT", 10, 0)
BindSlider(autoCloseSlider, "PopupTimerSeconds", 1, 300, 1, autoCloseValue, nil, "PopupTimerSeconds")

-- Lua errors (debug only)
local luaErrorsCheck = CreateFrame("CheckButton", nil, generalPanel, "InterfaceOptionsCheckButtonTemplate")
luaErrorsCheck:SetPoint("TOPLEFT", autoCloseSlider, "BOTTOMLEFT", 0, -15)
luaErrorsCheck.Text:SetText("Show Lua errors in chat (Debug mode only)")
local luaErrorsDesc = generalPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
luaErrorsDesc:SetPoint("TOPLEFT", luaErrorsCheck, "BOTTOMLEFT", 0, -5)
luaErrorsDesc:SetWidth(400); luaErrorsDesc:SetJustifyH("LEFT")
luaErrorsDesc:SetText("Shows Lua errors in chat for debugging. Requires debug mode to be enabled.")
BindCheckbox(luaErrorsCheck, "LuaErrorsEnabled", false, function(_, v)
  SetCVar("scriptErrors", v and "1" or "0")
end, "LuaErrorsEnabled")

-- Visibility van debug-sectie ook als hydrater registreren
Binder:register(function(tag)
  if generalPanel:IsShown() then
    if DBGet("DebugEnabled", false) then
      luaErrorsCheck:Show(); luaErrorsDesc:Show()
      local scriptErrorsEnabled = (GetCVar("scriptErrors") == "1")
      luaErrorsCheck:SetChecked(scriptErrorsEnabled)
      DBSet("LuaErrorsEnabled", scriptErrorsEnabled)
      DPrint(("Hydrate DebugVisibility -> show (scriptErrors=%s) (%s)"):format(scriptErrorsEnabled and "1" or "0", tag or ""))
    else
      luaErrorsCheck:Hide(); luaErrorsDesc:Hide()
      DPrint(("Hydrate DebugVisibility -> hide (%s)"):format(tag or ""))
    end
  end
end)

generalPanel:SetScript("OnShow", function()
  Binder:hydrateAll("General:OnShow")
end)

local generalFooter = generalPanel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
generalFooter:SetPoint("BOTTOMLEFT", 20, 20)
generalFooter:SetText(ns.Core.GetFooterText())

-- Export the panel for registration
ns.OptionsGeneral = {
  panel = generalPanel
}
