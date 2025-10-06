-- ToxicifyOptions.lua
-- Main options file that imports and registers all option panels
local addonName, ns = ...

-- Import all option panels
-- Note: The individual panel files will be loaded by the TOC file
-- This file just handles the registration and late hydration

-- ==================================================
-- REGISTER ALL PANELS
-- ==================================================
if Settings and Settings.RegisterAddOnCategory then
  local root = Settings.RegisterCanvasLayoutCategory(ns.OptionsRoot.panel, ns.OptionsRoot.panel.name)
  Settings.RegisterCanvasLayoutSubcategory(root, ns.OptionsGeneral.panel, ns.OptionsGeneral.panel.name)
  Settings.RegisterCanvasLayoutSubcategory(root, ns.OptionsList.panel,    ns.OptionsList.panel.name)
  Settings.RegisterCanvasLayoutSubcategory(root, ns.OptionsIO.panel,      ns.OptionsIO.panel.name)
  Settings.RegisterCanvasLayoutSubcategory(root, ns.OptionsWhisper.panel, ns.OptionsWhisper.panel.name)
  Settings.RegisterAddOnCategory(root)
  _G.ToxicifySettingsCategory = root
else
  InterfaceOptions_AddCategory(ns.OptionsRoot.panel)
  InterfaceOptions_AddCategory(ns.OptionsGeneral.panel)
  InterfaceOptions_AddCategory(ns.OptionsList.panel)
  InterfaceOptions_AddCategory(ns.OptionsIO.panel)
  InterfaceOptions_AddCategory(ns.OptionsWhisper.panel)
end

-- ==================================================
-- LATE HYDRATION (na login; geen handwerk per control)
-- ==================================================
local lateHydrateFrame = CreateFrame("Frame")
lateHydrateFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
lateHydrateFrame:SetScript("OnEvent", function()
  C_Timer.After(0.25, function() ns.OptionsCore.Binder:hydrateAll("Post-PEW 0.25s") end)
  C_Timer.After(0.75, function() ns.OptionsCore.Binder:hydrateAll("Post-PEW 0.75s") end)
end)