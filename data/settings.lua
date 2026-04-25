local private = {}

local function DeepDefaults(target, defaults)
    for key, value in pairs(defaults) do
        if type(value) == "table" then
            target[key] = DeepDefaults(target[key] or {}, value)
        elseif target[key] == nil then
            target[key] = value
        end
    end
    return target
end

local function MigrateCoreSettings(core)
    if type(core) ~= "table" then return core end
    local version = tonumber(core.layoutVersion) or 0
    if version < 5 then
        local d = ETL.DEFAULTS.core
        core.parentBarHeight   = d.parentBarHeight
        core.childBarHeight    = d.childBarHeight
        core.parentBottomInset = d.parentBottomInset
        core.childBottomInset  = d.childBottomInset
        core.parentTextLift    = d.parentTextLift
        core.childTextLift     = d.childTextLift
        core.parentToggleLift  = d.parentToggleLift
        core.childToggleLift   = d.childToggleLift
        core.layoutVersion     = d.layoutVersion
    end
    return core
end

function ETL:EnsureSettings()
    ETLDB = ETLDB or {}
    DeepDefaults(ETLDB, ETL.DEFAULTS)
    MigrateCoreSettings(ETLDB.core)
    return ETLDB.core
end

function ETL:GetSettings()
    return self:EnsureSettings()
end

function ETL:PrintMessage(message)
    print(ETL.CHAT_PREFIX .. message)
end

function ETL:ShowWelcomeMessage()
    local settings = self:GetSettings()
    if settings.showWelcomeMessage == false then return end
    self:PrintMessage("Welcome. Use |cffbc6fa8/etl|r to open Traveler's Log or |cffbc6fa8/etl help|r for more commands.")
    self:PrintMessage("|cffffff00Version:|r |cff8080ff" .. ETL.VERSION .. "|r")
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
    return tonumber(color.r) or ETL.BAR_COLOR.r,
           tonumber(color.g) or ETL.BAR_COLOR.g,
           tonumber(color.b) or ETL.BAR_COLOR.b
end
