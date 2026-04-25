local RGX = _G.RGXFramework

function ETL:RefreshIfVisible()
    local frame = self:GetMonthlyActivitiesFrame()
    if frame and frame:IsShown() then
        if self:DetectDuplicateInstall() or not self:GetSettings().enabled then
            self:HideVisibleRows(frame.ScrollBox)
        else
            self:RefreshVisibleRows(frame.ScrollBox)
        end
    end
end

function ETL:InstallScrollBoxHook(frame)
    if not frame or not frame.ScrollBox then return false end
    if not (_G.ScrollUtil and ScrollUtil.AddAcquiredFrameCallback) then return false end

    ScrollUtil.AddAcquiredFrameCallback(frame.ScrollBox, function(_, button)
        ETL:DecorateRow(button)
    end, ETL)

    self:RefreshVisibleRows(frame.ScrollBox)
    return true
end

function ETL:InstallMixinHooks()
    local function refreshRows(frameSelf)
        ETL:RefreshActivityCache()
        ETL:RefreshVisibleRows(frameSelf and frameSelf.ScrollBox)
    end

    local mixins = {
        { _G.MonthlyActivitiesButtonMixin,           "Init",            function(btn) ETL:DecorateRow(btn) end },
        { _G.MonthlyActivitiesButtonMixin,           "UpdateButtonState", function(btn) ETL:DecorateRow(btn) end },
        { _G.MonthlySupersedeActivitiesButtonMixin,  "Init",            function(btn) ETL:DecorateRow(btn) end },
        { _G.MonthlySupersedeActivitiesButtonMixin,  "UpdateButtonState", function(btn) ETL:DecorateRow(btn) end },
        { _G.MonthlyActivitiesFrameMixin,            "UpdateActivities", refreshRows },
        { _G.MonthlyActivitiesFrameMixin,            "SetActivities",   refreshRows },
        { _G.MonthlyActivitiesFrameMixin,            "OnShow",          refreshRows },
    }

    local count = 0
    for _, h in ipairs(mixins) do
        if h[1] and type(h[2]) == "string" and type(h[3]) == "function" then
            RGX:Hook(h[1], h[2], h[3])
            count = count + 1
        end
    end
    return count > 0
end

function ETL:Install()
    if self._installed then return end

    local frame = self:GetMonthlyActivitiesFrame()
    local viaScroll = self:InstallScrollBoxHook(frame)
    local viaMixins = self:InstallMixinHooks()

    if viaScroll or viaMixins then
        self._installed = true
        self:RefreshActivityCache()
        if frame and frame.ScrollBox then
            self:RefreshVisibleRows(frame.ScrollBox)
        end
        self:DebugMessage("Hooks installed (" .. ETL.VERSION .. ").")
    end
end

function ETL:RefreshProgressBars()
    self:RefreshActivityCache()
    self:RefreshIfVisible()
end
