local private = ETL.Private

function ETL:PrintCoreStatus()
    local frame = self:GetMonthlyActivitiesFrame()
    local visibleRows = 0

    if frame and frame.ScrollBox and frame.ScrollBox.ForEachFrame then
        frame.ScrollBox:ForEachFrame(function()
            visibleRows = visibleRows + 1
        end)
    end

    local settings = self:GetSettings()
    self:Say("Core status:")
    self:Say("version " .. private.VERSION)
    self:Say("bars " .. (settings.enabled and "enabled" or "disabled"))
    self:Say("hide completed " .. (settings.hideCompleted and "enabled" or "disabled"))
    self:Say("debug " .. (settings.debug and "enabled" or "disabled"))
    self:Say("duplicate " .. (self:DetectDuplicateInstall() and "detected" or "not detected"))
    self:Say("visible rows " .. visibleRows)
    self:Say("hooks " .. (private.installed and "installed" or "pending"))
    self:Say("cached activities " .. self:CountCachedActivities())
end

function ETL:PrintCoreHelp()
    self:Say("Core commands:")
    self:Say("/etl debug - Toggle ETL core debug output")
    self:Say("/etl refresh - Re-scan visible Traveler's Log rows")
    self:Say("/etl welcome - Toggle ETL login welcome message")
    self:Say("/etl bars on - Enable ETL progress bars")
    self:Say("/etl bars off - Disable ETL progress bars")
    self:Say("/etl completed on - Hide completed Traveler's Log rows")
    self:Say("/etl completed off - Show completed Traveler's Log rows")
    self:Say("/etl version - Show ETL core version")
end

function ETL:HandleCoreSlashCommand(input)
    input = self:TrimInput(input):lower()

    if input == "debug" then
        local settings = self:GetSettings()
        settings.debug = not settings.debug
        self:Say("Debug " .. (settings.debug and "enabled." or "disabled."))
        return true
    end

    if input == "refresh" then
        self:RefreshProgressBars()
        self:Say("Refreshed visible Traveler's Log rows.")
        return true
    end

    if input == "welcome" then
        self:ToggleWelcomeMessage()
        return true
    end

    if input == "bars on" then
        self:GetSettings().enabled = true
        self:RefreshProgressBars()
        self:Say("Progress bars enabled.")
        return true
    end

    if input == "bars off" then
        self:GetSettings().enabled = false
        self:RefreshProgressBars()
        self:Say("Progress bars disabled.")
        return true
    end

    if input == "completed on" then
        self:GetSettings().hideCompleted = true
        self:RefreshProgressBars()
        self:Say("Completed Traveler's Log rows hidden.")
        return true
    end

    if input == "completed off" then
        self:GetSettings().hideCompleted = false
        self:RefreshProgressBars()
        self:Say("Completed Traveler's Log rows shown.")
        return true
    end

    if input == "version" then
        self:Say("Core " .. private.VERSION)
        return true
    end

    return false
end

function ETL:WrapSlashCommand()
    if private.slashWrapped then
        return true
    end

    local previous = SlashCmdList["ETL"]
    if type(previous) ~= "function" then
        return false
    end

    SlashCmdList["ETL"] = function(input)
        local trimmed = ETL:TrimInput(input):lower()

        if trimmed == "status" then
            ETL:PrintCoreStatus()
            previous(input)
            return
        end

        if trimmed == "help" then
            previous(input)
            ETL:PrintCoreHelp()
            return
        end

        if ETL:HandleCoreSlashCommand(input) then
            return
        end

        previous(input)
    end

    private.slashWrapped = true
    return true
end

function ETL:QueueSlashWrap()
    if self:WrapSlashCommand() then
        return
    end

    self:After(0, function(me) me:WrapSlashCommand() end)
    self:After(1, function(me) me:WrapSlashCommand() end)
end
