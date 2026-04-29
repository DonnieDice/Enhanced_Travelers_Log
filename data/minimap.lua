local RGX = _G.RGXFramework

local DEFAULT_ANGLE = 220

local function GetMinimapAngle()
    return (ETLDB and ETLDB.minimapAngle) or DEFAULT_ANGLE
end

local function SetMinimapAngle(v)
    if ETLDB then ETLDB.minimapAngle = v end
end

function ETL:OpenTravelersLog()
    if InCombatLockdown and InCombatLockdown() then
        if _G.UIErrorsFrame then
            UIErrorsFrame:AddMessage("Cannot open Traveler's Log in combat.", 1, 0.2, 0.2)
        end
        return
    end

    if _G.C_PlayerInfo and C_PlayerInfo.IsTravelersLogAvailable and not C_PlayerInfo.IsTravelersLogAvailable() then
        if _G.UIErrorsFrame then
            UIErrorsFrame:AddMessage("Traveler's Log is not available right now.", 1, 0.2, 0.2)
        end
        return
    end

    if _G.EncounterJournal_LoadUI    then EncounterJournal_LoadUI()    end
    if _G.EncounterJournal_OpenJournal then EncounterJournal_OpenJournal() end

    if _G.MonthlyActivitiesFrame_OpenFrame then
        MonthlyActivitiesFrame_OpenFrame()
        return
    end

    local ej = _G.EncounterJournal
    local tab = ej and (ej.MonthlyActivitiesTab or ej.TravelersLogTab)
    if tab and tab.Click then tab:Click() end
end

function ETL:HandleMinimapClick()
    local ej = _G.EncounterJournal
    local activities = self:GetMonthlyActivitiesFrame()

    if ej and ej:IsShown() and activities and activities:IsShown() then
        HideUIPanel(ej)
        return
    end

    self:OpenTravelersLog()
end

function ETL:ToggleMinimapIcon(show)
    if ETLDB then ETLDB.minimapIconEnabled = show end
    self:ApplyMinimapVisibility()
    self:PrintMessage(show and "Minimap icon shown." or "Minimap icon hidden. Use /etl icon on to show again.")
end

function ETL:ApplyMinimapVisibility()
    if not self._minimapBtn then return end
    self._minimapBtn:SetVisible(ETLDB and ETLDB.minimapIconEnabled ~= false)
end

function ETL:PrintStatus()
    self:PrintMessage("Minimap icon is " .. ((ETLDB and ETLDB.minimapIconEnabled ~= false) and "shown" or "hidden") .. ".")
end

function ETL:DisplayHelp()
    self:PrintMessage("Commands:")
    self:PrintMessage("/etl — Open Traveler's Log")
    self:PrintMessage("/etl icon on/off — Show or hide minimap icon")
    self:PrintMessage("/etl status — Show status")
    self:PrintMessage("/etl help — Show this help")
end

function ETL:HandleSlashCommands(input)
    input = self:TrimInput(input):lower()
    if     input == ""         then self:HandleMinimapClick()
    elseif input == "icon"     then self:PrintMessage("Use /etl icon on or /etl icon off.")
    elseif input == "icon on"  then self:ToggleMinimapIcon(true)
    elseif input == "icon off" then self:ToggleMinimapIcon(false)
    elseif input == "status"   then self:PrintStatus()
    elseif input == "help"     then self:DisplayHelp()
    else   self:HandleCoreSlashCommand(input)
    end
end

RGX:OnLoad("EnhancedTravelersLog", function()
    ETLDB = ETLDB or {}
    if ETLDB.minimapAngle == nil    then ETLDB.minimapAngle = DEFAULT_ANGLE end
    if ETLDB.minimapIconEnabled == nil then ETLDB.minimapIconEnabled = true end
end)

RGX:OnLogin(function()
    RGX:RegisterSlashCommand({"etl"}, function(input) ETL:HandleSlashCommands(input) end)

    ETL._minimapBtn = RGX:Minimap({
        name         = "ETL_MinimapButton",
        icon         = "Interface\\AddOns\\EnhancedTravelersLog\\media\\logo",
        defaultAngle = DEFAULT_ANGLE,
        getAngle     = GetMinimapAngle,
        setAngle     = SetMinimapAngle,
        tooltip = {
            title = "|TInterface\\AddOns\\EnhancedTravelersLog\\media\\logo:18:18:0:0|t |cffbc6fa8E|r|cffffffffnhanced|r |cffbc6fa8T|r|cffffffffraveler's|r |cffbc6fa8L|r|cffffffffog|r|cffbc6fa8!|r",
            lines = {
                { left = "|cffbc6fa8Left-Click|r",       right = "Open Traveler's Log" },
                { left = "|cff4ecdc4Left-Drag|r",        right = "Move around minimap" },
                { left = "|cffe74c3cCtrl+Right-Click|r", right = "Hide minimap icon" },
            },
        },
        onLeftClick  = function() ETL:HandleMinimapClick() end,
        onCtrlRight  = function() ETL:ToggleMinimapIcon(false) end,
    })

    ETL:ApplyMinimapVisibility()
end)
