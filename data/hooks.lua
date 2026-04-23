local private = ETL.Private

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
    if not frame or not frame.ScrollBox then
        return false
    end

    local hooked = self:WatchFrames(frame.ScrollBox, function(selfRef, button)
        selfRef:DecorateRow(button)
    end)

    self:RefreshVisibleRows(frame.ScrollBox)
    return hooked
end

function ETL:InstallMixinHooks()
    local refreshRows = function(frameSelf)
        ETL:RefreshActivityCache()
        ETL:RefreshVisibleRows(frameSelf and frameSelf.ScrollBox)
    end

    local hooked = self:HookMany({
        {
            thing = _G.MonthlyActivitiesButtonMixin,
            action = "Init",
            thenDo = function(button)
                ETL:DecorateRow(button)
            end,
        },
        {
            thing = _G.MonthlyActivitiesButtonMixin,
            action = "UpdateButtonState",
            thenDo = function(button)
                ETL:DecorateRow(button)
            end,
        },
        {
            thing = _G.MonthlySupersedeActivitiesButtonMixin,
            action = "Init",
            thenDo = function(button)
                ETL:DecorateRow(button)
            end,
        },
        {
            thing = _G.MonthlySupersedeActivitiesButtonMixin,
            action = "UpdateButtonState",
            thenDo = function(button)
                ETL:DecorateRow(button)
            end,
        },
        {
            thing = _G.MonthlyActivitiesFrameMixin,
            action = "UpdateActivities",
            thenDo = refreshRows,
        },
        {
            thing = _G.MonthlyActivitiesFrameMixin,
            action = "SetActivities",
            thenDo = refreshRows,
        },
        {
            thing = _G.MonthlyActivitiesFrameMixin,
            action = "OnShow",
            thenDo = refreshRows,
        },
    })

    return hooked > 0
end

function ETL:Install()
    if private.installed then
        return
    end

    local frame = self:GetMonthlyActivitiesFrame()
    local viaScroll = self:InstallScrollBoxHook(frame)
    local viaMixins = self:InstallMixinHooks()

    if viaScroll or viaMixins then
        private.installed = true
        self:RefreshActivityCache()
        if frame and frame.ScrollBox then
            self:RefreshVisibleRows(frame.ScrollBox)
        end
        self:DebugMessage("Installed Monthly Activities hooks (" .. private.VERSION .. ").")
    end
end

function ETL:RefreshProgressBars()
    self:RefreshActivityCache()
    self:RefreshIfVisible()
end

function ETL:OpenTravelersLog()
    if InCombatLockdown and InCombatLockdown() then
        if _G.UIErrorsFrame then
            UIErrorsFrame:AddMessage("Cannot open Traveler's Log in combat.", 1, 0.2, 0.2)
        end
        return
    end

    if self:DetectDuplicateInstall() then
        return
    end

    if _G.C_PlayerInfo and C_PlayerInfo.IsTravelersLogAvailable and not C_PlayerInfo.IsTravelersLogAvailable() then
        if _G.UIErrorsFrame then
            UIErrorsFrame:AddMessage("Traveler's Log is not available right now.", 1, 0.2, 0.2)
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

    local ej = _G.EncounterJournal
    local tab = ej and (ej.MonthlyActivitiesTab or ej.TravelersLogTab)
    if tab and tab.Click then
        tab:Click()
    end
end

ETL:Watch("ADDON_LOADED", function(self, addonName)
    if addonName ~= private.ADDON_NAME
        and addonName ~= private.LEGACY_ADDON_NAME
        and addonName ~= "Blizzard_EncounterJournal" then
        return
    end

    self:EnsureSettings()
    self:QueueFrameworkRegistration()
    self:DetectDuplicateInstall()
    self:RefreshActivityCache()
    self:Install()
end)

ETL:Watch("PLAYER_LOGIN", function(self)
    self:EnsureSettings()
    self:QueueFrameworkRegistration()
    self:DetectDuplicateInstall()
    self:QueueSlashWrap()
    self:RefreshActivityCache()
    self:Install()
    self:ShowWelcomeMessage()
end)

ETL:WatchMany({
    "PERKS_ACTIVITY_COMPLETED",
    "PERKS_ACTIVITIES_UPDATED",
    "PERKS_ACTIVITIES_TRACKED_LIST_CHANGED",
    "PERKS_ACTIVITIES_TRACKED_UPDATED",
}, function(self)
    self:RefreshActivityCache()
    self:RefreshIfVisible()
end)
