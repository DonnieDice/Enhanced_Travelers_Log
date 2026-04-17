-- Enhanced Traveler's Log
-- Adds a per-row progress bar to the Traveler's Log (Monthly Activities)
-- panel of the Encounter Journal, and exposes ETL:OpenTravelersLog() for
-- the minimap icon click handler.
--
-- Midnight-era mainline still uses the historical MonthlyActivities frame
-- and mixin names in public Blizzard UI source. Requirement data currently
-- exposes only { completed, requirementText }, so progress has to be parsed
-- from the display string when Blizzard includes an "N / N" value.

ETL = ETL or {}

local ADDON_NAME = "EnhancedTravelersLog"
local BAR_COLOR_R, BAR_COLOR_G, BAR_COLOR_B = 0.584, 0, 0.255 -- #950041
local BAR_BG_HEIGHT = 20

local function HideProgressBar(button)
    if button.ETL_ProgressBarBg then
        button.ETL_ProgressBarBg:Hide()
    end
    if button.ETL_ProgressBar then
        button.ETL_ProgressBar:Hide()
    end
end

local function CreateProgressBar(button)
    if button.ETL_ProgressBarBg then return end

    local bg = CreateFrame("Frame", nil, button, "BackdropTemplate")
    bg:SetFrameStrata("MEDIUM")
    bg:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 36, 4)
    bg:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -60, 4)
    bg:SetHeight(BAR_BG_HEIGHT)
    bg:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, tileSize = 32, tileEdge = false, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    bg:SetBackdropColor(0, 0, 0, 0.9)
    button.ETL_ProgressBarBg = bg

    local bar = CreateFrame("StatusBar", nil, bg)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetStatusBarColor(BAR_COLOR_R, BAR_COLOR_G, BAR_COLOR_B, 1)
    bar:SetPoint("TOPLEFT", bg, "TOPLEFT", 3, -3)
    bar:SetPoint("BOTTOMRIGHT", bg, "BOTTOMRIGHT", -3, 3)
    button.ETL_ProgressBar = bar

    local text = bg:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("CENTER", bg, "CENTER")
    button.ETL_ProgressBarText = text
end

local function ReadRequirementProgress(req)
    local text = req.requirementText or ""
    local c, t = string.match(text, "(%d+)%s*/%s*(%d+)")
    if c and t then
        return tonumber(c), tonumber(t)
    end

    return nil, nil
end

local function UpdateProgressBar(button)
    if not button.ETL_ProgressBar then return end

    local data = button.GetData and button:GetData()
    local requirements = (data and data.requirementsList) or button.requirementsList
    if not requirements or #requirements == 0 then
        HideProgressBar(button)
        return
    end

    local current, total = 0, 0
    local sawAny = false
    local completedCount, totalCount = 0, #requirements

    for _, req in ipairs(requirements) do
        if req.completed then completedCount = completedCount + 1 end
        local c, t = ReadRequirementProgress(req)
        if c then sawAny = true; current = current + c end
        if t then total = total + t end
    end

    -- Prefer numeric progress when we could parse it; otherwise fall
    -- back to "X of Y requirements completed".
    if total == 0 then
        current = completedCount
        total = totalCount
        sawAny = true
    end

    local completed = (data and data.completed) or button.completed
    if completed and current < total then current = total end

    if not sawAny or total == 0 then
        HideProgressBar(button)
        return
    end

    local shown = math.min(current, total)
    button.ETL_ProgressBarBg:Show()
    button.ETL_ProgressBar:Show()
    button.ETL_ProgressBar:SetMinMaxValues(0, total)
    button.ETL_ProgressBar:SetValue(shown)
    button.ETL_ProgressBarText:SetFormattedText("%d / %d", shown, total)
end

local function DecorateRow(button)
    if not button or type(button) ~= "table" then return end
    -- Supersede/child rows are 48px tall -- skip them to avoid overlap.
    if button.GetHeight and button:GetHeight() < 60 then
        HideProgressBar(button)
        return
    end
    CreateProgressBar(button)
    UpdateProgressBar(button)
end

local function InstallScrollBoxHook(frame)
    if not frame or not frame.ScrollBox then return false end
    if not (_G.ScrollUtil and ScrollUtil.AddAcquiredFrameCallback) then
        return false
    end
    ScrollUtil.AddAcquiredFrameCallback(frame.ScrollBox, function(_, button)
        DecorateRow(button)
    end, ETL, true)
    return true
end

local function InstallMixinHooks()
    local hooked = false
    if _G.MonthlyActivitiesButtonMixin and MonthlyActivitiesButtonMixin.Init then
        hooksecurefunc(MonthlyActivitiesButtonMixin, "Init", DecorateRow)
        hooked = true
    end
    -- Supersede rows are intentionally skipped in DecorateRow, but we
    -- still hook so a future taller template would get decorated.
    if _G.MonthlySupersedeActivitiesButtonMixin
        and MonthlySupersedeActivitiesButtonMixin.Init then
        hooksecurefunc(MonthlySupersedeActivitiesButtonMixin, "Init", DecorateRow)
        hooked = true
    end
    return hooked
end

local installed = false
local function Install()
    if installed then return end
    local frame = _G.EncounterJournalMonthlyActivitiesFrame
        or (_G.EncounterJournal and _G.EncounterJournal.MonthlyActivitiesFrame)
    local viaScroll = InstallScrollBoxHook(frame)
    local viaMixin = InstallMixinHooks()
    if viaScroll or viaMixin then
        installed = true
    end
end

function ETL:OpenTravelersLog()
    if InCombatLockdown and InCombatLockdown() then
        if _G.UIErrorsFrame then
            UIErrorsFrame:AddMessage("Cannot open Traveler's Log in combat.", 1, 0.2, 0.2)
        end
        return
    end

    if _G.EncounterJournal_LoadUI then
        EncounterJournal_LoadUI()
    end

    if _G.EncounterJournal_OpenJournal then
        EncounterJournal_OpenJournal()
    end

    if _G.MonthlyActivitiesFrame_OpenFrame then
        MonthlyActivitiesFrame_OpenFrame()
        return
    end

    -- Fallback: click the tab directly.
    local ej = _G.EncounterJournal
    local tab = ej and (ej.MonthlyActivitiesTab or ej.TravelersLogTab)
    if tab and tab.Click then tab:Click() end
end

local handler = CreateFrame("Frame")
handler:RegisterEvent("ADDON_LOADED")
handler:SetScript("OnEvent", function(self, event, name)
    if event ~= "ADDON_LOADED" then return end
    if name ~= ADDON_NAME
        and name ~= "Enhanced_Travelers_Log"
        and name ~= "Blizzard_EncounterJournal" then
        return
    end
    Install()
    if installed then self:UnregisterEvent("ADDON_LOADED") end
end)
