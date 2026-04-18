local private = ETL.Private

local function EnsureTable(target, defaults)
    return ETL:Remember(target, defaults)
end

local function MigrateCoreSettings(core)
    if type(core) ~= "table" then
        return core
    end

    local version = tonumber(core.layoutVersion) or 0
    if version < 5 then
        core.parentBarHeight = private.DEFAULTS.core.parentBarHeight
        core.childBarHeight = private.DEFAULTS.core.childBarHeight
        core.parentBottomInset = private.DEFAULTS.core.parentBottomInset
        core.childBottomInset = private.DEFAULTS.core.childBottomInset
        core.parentTextLift = private.DEFAULTS.core.parentTextLift
        core.childTextLift = private.DEFAULTS.core.childTextLift
        core.parentToggleLift = private.DEFAULTS.core.parentToggleLift
        core.childToggleLift = private.DEFAULTS.core.childToggleLift
        core.layoutVersion = private.DEFAULTS.core.layoutVersion
    end

    return core
end

function ETL:EnsureSettings()
    ETLDB = ETLDB or {}
    EnsureTable(ETLDB, private.DEFAULTS)
    MigrateCoreSettings(ETLDB.core)
    return ETLDB.core
end

function ETL:GetSettings()
    return self:EnsureSettings()
end

function ETL:PrintMessage(message)
    print(private.CHAT_PREFIX .. message)
end

function ETL:ShowWelcomeMessage()
    local settings = self:GetSettings()
    if settings.showWelcomeMessage == false then
        return
    end

    self:PrintMessage("Welcome. Use |cffbc6fa8/etl|r to open Traveler's Log or |cffbc6fa8/etl help|r for more commands.")
    self:PrintMessage("|cffffff00Version:|r |cff8080ff" .. tostring((self.Private and self.Private.VERSION) or "unknown") .. "|r")
end

function ETL:ToggleWelcomeMessage()
    local settings = self:GetSettings()
    settings.showWelcomeMessage = not (settings.showWelcomeMessage == false)

    if settings.showWelcomeMessage then
        self:PrintMessage("|cff58be81Welcome message enabled.|r")
    else
        self:PrintMessage("|cffff7b72Welcome message disabled.|r")
    end
end

function ETL:DebugMessage(message)
    if self:GetSettings().debug then
        self:PrintMessage("Debug: " .. message)
    end
end

function ETL:TrimInput(input)
    return (input or ""):match("^%s*(.-)%s*$")
end

function ETL:GetConfiguredBarColor()
    local color = self:GetSettings().barColor or {}
    local r = tonumber(color.r) or private.BAR_COLOR_R
    local g = tonumber(color.g) or private.BAR_COLOR_G
    local b = tonumber(color.b) or private.BAR_COLOR_B
    return r, g, b
end
