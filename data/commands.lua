function ETL:PrintCoreStatus()
    local frame = self:GetMonthlyActivitiesFrame()
    local visibleRows = 0

    if frame and frame.ScrollBox and frame.ScrollBox.ForEachFrame then
        frame.ScrollBox:ForEachFrame(function()
            visibleRows = visibleRows + 1
        end)
    end

    local settings = self:GetSettings()
    self:PrintMessage("Core status:")
    self:PrintMessage("version " .. ETL.VERSION)
    self:PrintMessage("bars " .. (settings.enabled and "enabled" or "disabled"))
    self:PrintMessage("hide completed " .. (settings.hideCompleted and "enabled" or "disabled"))
    self:PrintMessage("debug " .. (settings.debug and "enabled" or "disabled"))
    self:PrintMessage("duplicate " .. (self:DetectDuplicateInstall() and "detected" or "not detected"))
    self:PrintMessage("visible rows " .. visibleRows)
    self:PrintMessage("hooks " .. (self._installed and "installed" or "pending"))
    self:PrintMessage("cached activities " .. self:CountCachedActivities())
end

function ETL:PrintCoreHelp()
    self:PrintMessage("Core commands:")
    self:PrintMessage("/etl debug - Toggle ETL core debug output")
    self:PrintMessage("/etl refresh - Re-scan visible Traveler's Log rows")
    self:PrintMessage("/etl welcome - Toggle ETL login welcome message")
    self:PrintMessage("/etl bars on - Enable ETL progress bars")
    self:PrintMessage("/etl bars off - Disable ETL progress bars")
    self:PrintMessage("/etl completed on - Hide completed Traveler's Log rows")
    self:PrintMessage("/etl completed off - Show completed Traveler's Log rows")
    self:PrintMessage("/etl version - Show ETL version")
end

function ETL:HandleCoreSlashCommand(input)
    input = self:TrimInput(input):lower()

    if input == "debug" then
        local settings = self:GetSettings()
        settings.debug = not settings.debug
        self:PrintMessage("Debug " .. (settings.debug and "enabled." or "disabled."))
        return true
    end

    if input == "refresh" then
        self:RefreshProgressBars()
        self:PrintMessage("Refreshed visible Traveler's Log rows.")
        return true
    end

    if input == "welcome" then
        self:ToggleWelcomeMessage()
        return true
    end

    if input == "bars on" then
        self:GetSettings().enabled = true
        self:RefreshProgressBars()
        self:PrintMessage("Progress bars enabled.")
        return true
    end

    if input == "bars off" then
        self:GetSettings().enabled = false
        self:RefreshProgressBars()
        self:PrintMessage("Progress bars disabled.")
        return true
    end

    if input == "completed on" then
        self:GetSettings().hideCompleted = true
        self:RefreshProgressBars()
        self:PrintMessage("Completed Traveler's Log rows hidden.")
        return true
    end

    if input == "completed off" then
        self:GetSettings().hideCompleted = false
        self:RefreshProgressBars()
        self:PrintMessage("Completed Traveler's Log rows shown.")
        return true
    end

    if input == "version" then
        self:PrintMessage("Version " .. ETL.VERSION)
        return true
    end

    return false
end
