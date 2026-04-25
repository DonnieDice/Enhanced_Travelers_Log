local ADDON_NAMES = { "EnhancedTravelersLog", "Enhanced_Travelers_Log" }

function ETL:GetFrame(frameName)
    return _G[frameName]
end

function ETL:GetMonthlyActivitiesFrame()
    return self:GetFrame("EncounterJournalMonthlyActivitiesFrame")
        or (_G.EncounterJournal and _G.EncounterJournal.MonthlyActivitiesFrame)
end

function ETL:DetectDuplicateInstall()
    if self._duplicateWarned then
        return true
    end

    if _G.IsAddOnLoaded then
        for _, addonName in ipairs(ADDON_NAMES) do
            if addonName ~= "EnhancedTravelersLog" and IsAddOnLoaded(addonName) then
                self._duplicateWarned = true
                self:GetSettings().enabled = false
                self:PrintMessage("Duplicate ETL install detected (" .. addonName .. "). Progress bars disabled.")
                return true
            end
        end
    end

    return false
end

function ETL:RefreshActivityCache()
    if not (_G.C_PerksActivities and C_PerksActivities.GetPerksActivitiesInfo) then
        return
    end

    local info = C_PerksActivities.GetPerksActivitiesInfo()
    local activities = info and info.activities
    self.activityCache = {}

    if not activities then
        return
    end

    local function CacheActivity(activity)
        if activity and activity.ID then
            ETL.activityCache[activity.ID] = activity
        end
        if activity and activity.child then
            CacheActivity(activity.child)
        end
    end

    for _, activity in pairs(activities) do
        CacheActivity(activity)
    end
end

function ETL:CountCachedActivities()
    local count = 0
    for _ in pairs(self.activityCache) do
        count = count + 1
    end
    return count
end

function ETL:GetActivityData(button)
    if not button or not button.GetData then
        return nil
    end

    local data = button:GetData()
    if data and data.ID and _G.C_PerksActivities and C_PerksActivities.GetPerksActivityInfo then
        local freshData = C_PerksActivities.GetPerksActivityInfo(data.ID)
        if freshData then
            return freshData
        end
    end

    if data and data.ID and self.activityCache[data.ID] then
        return self.activityCache[data.ID]
    end

    return data
end

function ETL:GetActiveActivityNode(activity)
    local current = activity

    while current and current.completed and current.child do
        current = current.child
    end

    return current or activity
end

function ETL:IsActivityCompleted(activity)
    return activity and activity.completed == true
end

function ETL:NormalizeNumericToken(value)
    if value == nil then
        return nil
    end

    local digits = tostring(value):gsub("%D", "")
    if digits == "" then
        return nil
    end

    return tonumber(digits)
end

function ETL:ParseRequirementProgress(requirementText)
    if not requirementText or requirementText == "" then
        return nil, nil, nil
    end

    local current, total = string.match(requirementText, "([%d%.,%s]+)%s*/%s*([%d%.,%s]+)")
    if current and total then
        local normalizedCurrent = self:NormalizeNumericToken(current)
        local normalizedTotal = self:NormalizeNumericToken(total)
        if normalizedCurrent ~= nil and normalizedTotal ~= nil then
            return normalizedCurrent, normalizedTotal, string.format("%d / %d", normalizedCurrent, normalizedTotal)
        end
    end

    current, total = string.match(requirementText, "([%d%.,%s]+)%s+[oO][fF]%s+([%d%.,%s]+)")
    if current and total then
        local normalizedCurrent = self:NormalizeNumericToken(current)
        local normalizedTotal = self:NormalizeNumericToken(total)
        if normalizedCurrent ~= nil and normalizedTotal ~= nil then
            return normalizedCurrent, normalizedTotal, string.format("%d / %d", normalizedCurrent, normalizedTotal)
        end
    end

    local percent = string.match(requirementText, "(%d+)%s*%%")
    if percent then
        local normalizedPercent = self:NormalizeNumericToken(percent)
        if normalizedPercent ~= nil then
            normalizedPercent = math.max(0, math.min(100, normalizedPercent))
            return normalizedPercent, 100, string.format("%d%%", normalizedPercent)
        end
    end

    return nil, nil, nil
end

function ETL:BuildProgress(requirements)
    if not requirements or #requirements == 0 then
        return nil, nil, nil
    end

    local boolCurrent, boolTotal = 0, 0
    local numericEntries = {}

    for _, requirement in ipairs(requirements) do
        local current, total, label = self:ParseRequirementProgress(requirement.requirementText)
        if current ~= nil and total ~= nil then
            table.insert(numericEntries, {
                current = current,
                total = total,
                label = label,
                completed = requirement.completed == true,
            })
        end

        boolCurrent = boolCurrent + (requirement.completed and 1 or 0)
        boolTotal = boolTotal + 1
    end

    if #numericEntries > 0 then
        local selected = numericEntries[#numericEntries]

        -- Staged activities can expose both the completed stage and the
        -- next stage together; prefer the first incomplete numeric stage
        -- rather than summing them together.
        for _, entry in ipairs(numericEntries) do
            if not entry.completed and entry.total > 0 then
                selected = entry
                break
            end
        end

        if selected and selected.total > 0 then
            return selected.current, selected.total, selected.label or string.format("%d / %d", selected.current, selected.total)
        end
    end

    if boolTotal > 0 then
        return boolCurrent, boolTotal, string.format("%d / %d", boolCurrent, boolTotal)
    end

    return nil, nil, nil
end
