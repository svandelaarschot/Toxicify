-- OptionsList.lua
-- Toxic & Pumper List Management panel for Toxicify
local addonName, ns = ...

-- ==================================================
-- LIST PANEL
-- ==================================================
local listPanel = CreateFrame("Frame", "ToxicifyListOptionsPanel")
listPanel.name = "Toxic List"

local listTitle = listPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
listTitle:SetPoint("TOPLEFT", 16, -16)
listTitle:SetText("|cff39FF14Toxicify|r - Toxic & Pumper List Management")

local listDesc = listPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
listDesc:SetPoint("TOPLEFT", listTitle, "BOTTOMLEFT", 0, -8)
listDesc:SetWidth(500); listDesc:SetJustifyH("LEFT")
listDesc:SetText("Manage your toxic/pumper player list. They will be marked in party/raid frames and in the Group Finder.\n\nYou can add names manually below or with /toxic add Name-Realm.")

local inputLabel = listPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
inputLabel:SetPoint("TOPLEFT", listDesc, "BOTTOMLEFT", 0, -20)
inputLabel:SetText("Player Name:"); inputLabel:SetTextColor(1,1,1)

local input = CreateFrame("EditBox", nil, listPanel, "InputBoxTemplate")
input:SetSize(200, 30); input:SetPoint("LEFT", inputLabel, "RIGHT", 10, 0)
input:SetAutoFocus(false); input:SetMaxLetters(50)

local suggestionBox = ns.Core.CreateAutoCompletion(input, listPanel)

local addToxicBtn = CreateFrame("Button", nil, listPanel, "UIPanelButtonTemplate")
addToxicBtn:SetSize(100, 30); addToxicBtn:SetPoint("LEFT", input, "RIGHT", 10, 0)
addToxicBtn:SetText("Add Toxic")

local addPumperBtn = CreateFrame("Button", nil, listPanel, "UIPanelButtonTemplate")
addPumperBtn:SetSize(100, 30); addPumperBtn:SetPoint("LEFT", addToxicBtn, "RIGHT", 10, 0)
addPumperBtn:SetText("Add Pumper")

local scrollFrame = CreateFrame("ScrollFrame", nil, listPanel, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", inputLabel, "BOTTOMLEFT", -10, -10)
scrollFrame:SetSize(630, 450)
local content = CreateFrame("Frame", nil, scrollFrame)
content:SetSize(630, 450); scrollFrame:SetScrollChild(content)
content.children = {} -- Initialize children array for RefreshSharedList

local function RefreshList()
  if ns.UI and ns.UI.RefreshSharedList then 
    -- Ensure content frame is properly initialized
    if not content.children then
      content.children = {}
    end
    
    -- Debug: Check if we have any players
    local players = ns.Player and ns.Player.GetAllPlayers and ns.Player.GetAllPlayers() or {}
    local playerCount = 0
    for _ in pairs(players) do playerCount = playerCount + 1 end
    print("Toxicify Debug: Found " .. playerCount .. " players in database")
    
    ns.UI.RefreshSharedList(content) 
    -- Force content to be visible and update scroll
    content:Show()
    scrollFrame:Show()
    scrollFrame:UpdateScrollChildRect()
    scrollFrame:SetVerticalScroll(0)
  else
    print("Toxicify Debug: RefreshSharedList not available")
  end
end

addToxicBtn:SetScript("OnClick", function()
  local name = input:GetText()
  if name and name ~= "" then
    local me = GetUnitName("player", true); local meShort = GetUnitName("player", false)
    if name == me or name == meShort then
      print("|cffff0000Toxicify:|r You cannot mark yourself as toxic!")
    else
      if ns.Player and ns.Player.MarkToxic then ns.Player.MarkToxic(name) end
      input:SetText(""); 
      suggestionBox:Hide(); 
      RefreshList()
      C_Timer.After(0.1, function() RefreshList() end)
    end
  end
end)

addPumperBtn:SetScript("OnClick", function()
  local name = input:GetText()
  if name and name ~= "" then
    local me = GetUnitName("player", true); local meShort = GetUnitName("player", false)
    if name == me or name == meShort then
      print("|cffff0000Toxicify:|r You cannot mark yourself as pumper!")
    else
      if ns.Player and ns.Player.MarkPumper then ns.Player.MarkPumper(name) end
      input:SetText(""); suggestionBox:Hide(); RefreshList()
    end
  end
end)

listPanel:SetScript("OnShow", function() 
  RefreshList()
  -- Force refresh after a small delay to ensure proper display
  C_Timer.After(0.1, function() RefreshList() end)
  -- Additional refresh after longer delay to catch any late initialization
  C_Timer.After(0.5, function() RefreshList() end)
end)

local listFooter = listPanel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
listFooter:SetPoint("BOTTOMLEFT", 20, 20)
listFooter:SetText(ns.Core.GetFooterText())

C_Timer.After(0.1, function() RefreshList() end)
-- Export the panel for registration
ns.OptionsList = {
  panel = listPanel
}
