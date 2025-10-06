-- OptionsCore.lua
-- Shared utilities and Binder system for Toxicify options
local addonName, ns = ...

-- ---------- debug ----------
local function DPrint(msg)
  if ns and ns.Core and ns.Core.DebugPrint then ns.Core.DebugPrint(msg, true) end
end

-- ---------- ALWAYS access DB via getters ----------
local function DB() return ns.Core and ns.Core.GetDatabase and ns.Core.GetDatabase() or _G.ToxicifyDB end
local function DBGet(k, def) 
  local v = DB()[k]
  if v == nil or v == "" then 
    return def 
  end
  return v
end
local function DBSet(k, v) DB()[k] = v end

-- ==================================================
-- Binder: centrale registry voor alle hydrates
-- ==================================================
local Binder = { list = {} }

function Binder:register(hydrater)
  if type(hydrater) == "function" then
    table.insert(self.list, hydrater)
  end
  return hydrater
end

function Binder:hydrateAll(tag)
  for _, fn in ipairs(self.list) do
    -- elke hydrater moet zelf defensief zijn
    local ok, err = pcall(fn, tag)
    if not ok then
      DPrint(("Hydrate error: %s"):format(tostring(err)))
    end
  end
end

-- ==================================================
-- kleine UI helpers
-- ==================================================
local function InitializeEditBox(editBox, value)
  if not editBox then return end
  editBox:SetText(tostring(value or ""))
  editBox:SetTextColor(1,1,1)
  editBox:SetFontObject("GameFontNormal")
  editBox:Show()
  editBox:Enable()
  editBox:SetCursorPosition(0)
end

-- Bind een checkbox aan een DB-key en registreer de hydrater
local function BindCheckbox(cb, key, defaultValue, afterChange, logName)
  if not cb then return function() end end
  if DBGet(key, nil) == nil then DBSet(key, defaultValue and true or false) end

  cb:SetScript("OnClick", function(self)
    local v = self:GetChecked() and true or false
    DBSet(key, v)
    if logName then DPrint(("Click   CB %-28s -> %s"):format(logName, tostring(v))) end
    if afterChange then pcall(afterChange, self, v) end
  end)

  -- registreer hydrater in Binder
  return Binder:register(function(tag)
    local v = DBGet(key, defaultValue and true or false) and true or false
    cb:SetChecked(v)
    if logName then DPrint(("Hydrate CB %-28s = %s (%s)"):format(logName, tostring(v), tag or "")) end
  end)
end

-- Bind een slider aan een DB-key en registreer de hydrater
local function BindSlider(sl, key, minV, maxV, stepV, valueLabel, afterChange, logName)
  if not sl then return function() end end
  if DBGet(key, nil) == nil then DBSet(key, minV) end

  sl:SetMinMaxValues(minV, maxV)
  sl:SetValueStep(stepV or 1)
  sl:SetObeyStepOnDrag(true)

  local function setLabel(v) if valueLabel then valueLabel:SetText(tostring(v).."s") end end

  sl:SetScript("OnValueChanged", function(self, value)
    local v = math.floor((value or 0)+0.5)
    DBSet(key, v); setLabel(v)
    if logName then DPrint(("Change  SL %-28s -> %s"):format(logName, tostring(v))) end
    if afterChange then pcall(afterChange, self, v) end
  end)

  -- registreer hydrater in Binder
  return Binder:register(function(tag)
    local v = tonumber(DBGet(key, minV)) or minV
    sl:SetValue(v); setLabel(v)
    if logName then DPrint(("Hydrate SL %-28s = %s (%s)"):format(logName, tostring(v), tag or "")) end
  end)
end

-- Bind een editbox aan een DB-key en registreer de hydrater
local function BindEditBoxText(editBox, key, defaultValue, whenEnabledFn, logName)
  if not editBox then return function() end end
  if DBGet(key, nil) == nil then DBSet(key, defaultValue) end

  editBox:SetScript("OnTextChanged", function(self)
    -- optioneel: alleen saven als whenEnabledFn true teruggeeft
    if not whenEnabledFn or whenEnabledFn() then
      DBSet(key, self:GetText() or "")
      if logName then DPrint(("Change  EB %-28s -> '%s'"):format(logName, tostring(self:GetText() or ""))) end
    end
  end)

  return Binder:register(function(tag)
    local v = DBGet(key, defaultValue)
    InitializeEditBox(editBox, v)
    if logName then DPrint(("Hydrate EB %-28s = '%s' (%s)"):format(logName, tostring(v or ""), tag or "")) end
  end)
end

-- Export the utilities for use in other option files
ns.OptionsCore = {
  Binder = Binder,
  DB = DB,
  DBGet = DBGet,
  DBSet = DBSet,
  DPrint = DPrint,
  InitializeEditBox = InitializeEditBox,
  BindCheckbox = BindCheckbox,
  BindSlider = BindSlider,
  BindEditBoxText = BindEditBoxText
}
