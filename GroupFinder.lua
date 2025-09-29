-- GroupFinder.lua - Group Finder integration
local addonName, ns = ...

-- GroupFinder namespace
ns.GroupFinder = {}

-- Initialize GroupFinder module
function ns.GroupFinder.Initialize()
    -- GroupFinder initialization if needed
end

-- Create Group Finder button
local function CreateGroupFinderButton()
    if _G.ToxicifyToggleButton then return end
    if not (LFGListFrame and LFGListFrame.SearchPanel) then return end

    local toggleBtn = CreateFrame("Button", "ToxicifyToggleButton", LFGListFrame.SearchPanel, "UIPanelButtonTemplate")
    toggleBtn:SetSize(80, 22)
    toggleBtn:SetText("Toxicify")

    -- Plaats hem netjes naast Filter
    if _G.LFGListFrameSearchPanelFilterButton then
        toggleBtn:SetPoint("LEFT", _G.LFGListFrameSearchPanelFilterButton, "RIGHT", 5, 0)
    else
        toggleBtn:SetPoint("LEFT", LFGListFrame.SearchPanel.RefreshButton, "RIGHT", -110, 0)
    end

    toggleBtn:SetScript("OnClick", function()
        if not _G.ToxicifyListFrame then
            ns.UI.CreateToxicifyUI()
        end
        if _G.ToxicifyListFrame:IsShown() then
            _G.ToxicifyListFrame:Hide()
        else
            _G.ToxicifyListFrame:Refresh()
            _G.ToxicifyListFrame:Show()
        end
    end)
end

-- Initialize Group Finder integration
function ns.GroupFinder.Initialize()
    -- Loader to wait for Blizzard's GroupFinder UI
    local gfLoader = CreateFrame("Frame")
    gfLoader:RegisterEvent("ADDON_LOADED")
    gfLoader:RegisterEvent("PLAYER_ENTERING_WORLD")
    gfLoader:RegisterEvent("LFG_LIST_SEARCH_RESULTS_RECEIVED")
    gfLoader:SetScript("OnEvent", function(self, event, addon)
        if event == "PLAYER_ENTERING_WORLD"
           or event == "LFG_LIST_SEARCH_RESULTS_RECEIVED"
           or (event == "ADDON_LOADED" and addon == "Blizzard_LookingForGroupUI") then
            C_Timer.After(1, function()
                if LFGListFrame and LFGListFrame.SearchPanel then
                    CreateGroupFinderButton()
                end
            end)
        end
    end)
    
    -- Hook into LFG search results
    hooksecurefunc("LFGListSearchEntry_Update", function(entry)
        if not entry or not entry.resultID then return end
        local info = C_LFGList.GetSearchResultInfo(entry.resultID)
        if not info or not info.leaderName then return end

        local leader = info.leaderName

        -- Reset group name
        entry.Name:SetText(info.name)

        -- === LEADER HIGHLIGHT ===
        if ns.Player.IsToxic(leader) then
            entry.Name:SetText("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:14:14|t |cffff0000"..info.name.."|r")
        elseif ns.Player.IsPumper(leader) then
            entry.Name:SetText("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:14:14|t |cff00ff00"..info.name.."|r")
        end

        -- === CLASS ICON OVERLAY ===
        if entry.DataDisplay and entry.DataDisplay.Enumerate and entry.DataDisplay.Enumerate.MemberFrames then
            local leaderButton = entry.DataDisplay.Enumerate.MemberFrames[1]
            if leaderButton then
                -- Toxic overlay
                if not leaderButton.ToxicOverlay then
                    leaderButton.ToxicOverlay = leaderButton:CreateTexture(nil, "OVERLAY")
                    leaderButton.ToxicOverlay:SetSize(14, 14)
                    leaderButton.ToxicOverlay:SetPoint("TOPRIGHT", leaderButton, "TOPRIGHT", -1, -1)
                    leaderButton.ToxicOverlay:Hide()
                end
                -- Pumper overlay
                if not leaderButton.PumperOverlay then
                    leaderButton.PumperOverlay = leaderButton:CreateTexture(nil, "OVERLAY")
                    leaderButton.PumperOverlay:SetSize(14, 14)
                    leaderButton.PumperOverlay:SetPoint("BOTTOMRIGHT", leaderButton, "BOTTOMRIGHT", -1, 1)
                    leaderButton.PumperOverlay:Hide()
                end

                -- Reset
                leaderButton.ToxicOverlay:Hide()
                leaderButton.PumperOverlay:Hide()

                -- Apply
                if ns.Player.IsToxic(leader) then
                    leaderButton.ToxicOverlay:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_8")
                    leaderButton.ToxicOverlay:Show()
                elseif ns.Player.IsPumper(leader) then
                    leaderButton.PumperOverlay:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_1")
                    leaderButton.PumperOverlay:Show()
                end
            end
        end
    end)
end
