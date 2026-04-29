local ADDON_NAME = "EnhancedTravelersLog"
local RGX = assert(_G.RGXFramework, "EnhancedTravelersLog: RGX-Framework not loaded")

ETL = ETL or {}
ETL.activityCache = ETL.activityCache or {}

local LEGACY_ADDON_NAME = "Enhanced_Travelers_Log"

ETL.VERSION    = "v0.1.6"
ETL.BAR_COLOR  = { r = 0.737, g = 0.435, b = 0.659 }
ETL.CHAT_PREFIX = "|TInterface\\AddOns\\EnhancedTravelersLog\\media\\logo.tga:16:16:0:0|t - |cffffffff[|r|cffbc6fa8ETL|r|cffffffff]|r "

ETL.DEFAULTS = {
    core = {
        enabled            = true,
        debug              = false,
        showWelcomeMessage = true,
        barColor           = { r = 0.737, g = 0.435, b = 0.659 },
        hideCompleted      = false,
        parentBarHeight    = 7,
        childBarHeight     = 6,
        parentBottomInset  = 8,
        childBottomInset   = 7,
        parentTextLeft     = 36,
        childTextLeft      = 40,
        rightInsetParent   = -60,
        rightInsetChild    = -56,
        parentTextLift     = 0,
        childTextLift      = 0,
        parentToggleLift   = 0,
        childToggleLift    = 0,
        layoutVersion      = 5,
    },
}

local function OnAddonLoaded(event, addonName)
    if addonName ~= ADDON_NAME and addonName ~= LEGACY_ADDON_NAME and addonName ~= "Blizzard_EncounterJournal" then return end
    ETL:EnsureSettings()
    ETL:DetectDuplicateInstall()
    ETL:RefreshActivityCache()
    ETL:Install()
end

local function OnPlayerLogin()
    ETL:EnsureSettings()
    ETL:DetectDuplicateInstall()
    ETL:RefreshActivityCache()
    ETL:Install()
    ETL:ShowWelcomeMessage()
end

local function OnPerksUpdate()
    ETL:RefreshActivityCache()
    ETL:RefreshIfVisible()
end

RGX:RegisterEvent("ADDON_LOADED",                        OnAddonLoaded)
RGX:RegisterEvent("PLAYER_LOGIN",                        OnPlayerLogin)
RGX:RegisterEvent("PERKS_ACTIVITY_COMPLETED",            OnPerksUpdate)
RGX:RegisterEvent("PERKS_ACTIVITIES_UPDATED",            OnPerksUpdate)
RGX:RegisterEvent("PERKS_ACTIVITIES_TRACKED_LIST_CHANGED", OnPerksUpdate)
RGX:RegisterEvent("PERKS_ACTIVITIES_TRACKED_UPDATED",    OnPerksUpdate)
