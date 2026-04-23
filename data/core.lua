-- Enhanced Traveler's Log
-- v3.5 modular bootstrap for retail 12.x / Midnight-era Blizzard UI.

ETL = ETL or {}

local ADDON_NAME = "EnhancedTravelersLog"
local LEGACY_ADDON_NAME = "Enhanced_Travelers_Log"

if _G.ETL_CORE_OWNER and _G.ETL_CORE_OWNER ~= ADDON_NAME then
    return
end
_G.ETL_CORE_OWNER = ADDON_NAME

if _G.ETL_CORE_LOADED then
    return
end
_G.ETL_CORE_LOADED = true

ETL.Private = ETL.Private or {}

local private = ETL.Private

private.ADDON_NAME = ADDON_NAME
private.LEGACY_ADDON_NAME = LEGACY_ADDON_NAME
private.VERSION = "v0.1.1"

private.BAR_COLOR_R = 0.737
private.BAR_COLOR_G = 0.435
private.BAR_COLOR_B = 0.659 -- #bc6fa8
private.CHAT_PREFIX = "|TInterface\\AddOns\\EnhancedTravelersLog\\media\\logo.tga:16:16:0:0|t - |cffffffff[|r|cffbc6fa8ETL|r|cffffffff]|r "
private.DUPLICATE_ADDON_NAMES = {
    LEGACY_ADDON_NAME,
    "RGXEnhancedTravelersLog",
    "RGX_EnhancedTravelersLog",
    "RGX-EnhancedTravelersLog",
}

private.DEFAULTS = {
    core = {
        enabled = true,
        debug = false,
        showWelcomeMessage = true,
        barColor = {
            r = private.BAR_COLOR_R,
            g = private.BAR_COLOR_G,
            b = private.BAR_COLOR_B,
        },
        hideCompleted = true,
        parentBarHeight = 7,
        childBarHeight = 6,
        parentBottomInset = 8,
        childBottomInset = 7,
        parentTextLeft = 36,
        childTextLeft = 40,
        rightInsetParent = -60,
        rightInsetChild = -56,
        parentTextLift = 0,
        childTextLift = 0,
        parentToggleLift = 0,
        childToggleLift = 0,
        layoutVersion = 5,
    },
}

private.handler = CreateFrame("Frame")
private.installed = false
private.slashWrapped = false
private.duplicateWarned = false
private.frameworkAvailable = false
private.frameworkRegistered = false
private.frameworkInitHooked = false
private.localWowEventFrame = CreateFrame("Frame")
private.localWowEventHandlers = private.localWowEventHandlers or {}

ETL.activityCache = ETL.activityCache or {}

function ETL:GetFramework()
    return _G.RGXFramework or _G.RGX
end

function ETL:IsFrameworkAvailable()
    local rgx = self:GetFramework()
    return type(rgx) == "table"
        and (type(rgx.EnsureAddonBridge) == "function"
            or type(rgx.RegisterAddonBridge) == "function"
            or type(rgx.RegisterModule) == "function")
end

function ETL:GetFrameworkBridge()
    if private.frameworkBridge then
        return private.frameworkBridge
    end

    local rgx = self:GetFramework()
    if type(rgx) == "table" and type(rgx.CreateAddonBridge) == "function" then
        private.frameworkBridge = rgx:CreateAddonBridge("etl", {
            addonName = private.ADDON_NAME,
            version = private.VERSION,
            entrypoint = self,
            GetAddon = function()
                return ETL
            end,
        })
    else
        private.frameworkBridge = {
            name = "etl",
            kind = "addon-bridge",
            addonName = private.ADDON_NAME,
            version = private.VERSION,
            enabled = true,
            entrypoint = self,
            Init = function(module)
                module.enabled = true
            end,
            GetAddon = function()
                return ETL
            end,
        }
    end

    return private.frameworkBridge
end

function ETL:QueueFrameworkRegistration()
    local rgx = self:GetFramework()
    if type(rgx) ~= "table" then
        return false
    end

    local bridge = self:GetFrameworkBridge()

    if type(rgx.EnsureAddonBridge) == "function" then
        local registered = rgx:EnsureAddonBridge("etl", bridge)
        if registered then
            private.frameworkAvailable = true
            private.frameworkRegistered = registered.entrypoint == self or registered == self
            return private.frameworkRegistered
        end
    elseif type(rgx.RegisterAddonBridge) == "function" then
        local ok = rgx:RegisterAddonBridge("etl", bridge)
        if ok ~= false then
            private.frameworkAvailable = true
            private.frameworkRegistered = true
            return true
        end
    elseif type(rgx.RegisterModule) == "function" then
        local ok = rgx:RegisterModule("etl", bridge)
        if ok ~= false then
            private.frameworkAvailable = true
            private.frameworkRegistered = true
            return true
        end
    end

    if type(rgx.RegisterEvent) == "function" and not private.frameworkInitHooked then
        private.frameworkInitHooked = true
        rgx:RegisterEvent("FRAMEWORK_INITIALIZED", function()
            ETL:QueueFrameworkRegistration()
        end)
        return true
    end

    return false
end

if not private.localWowEventFrame._etlDispatcherBound then
    private.localWowEventFrame:SetScript("OnEvent", function(_, event, ...)
        local handlers = private.localWowEventHandlers[event]
        if not handlers then
            return
        end

        for _, func in ipairs(handlers) do
            pcall(func, ETL, ...)
        end
    end)
    private.localWowEventFrame._etlDispatcherBound = true
end

function ETL:Say(message)
    self:PrintMessage(message)
end

function ETL:Remember(target, defaults)
    local rgx = self:GetFramework()
    if type(rgx) == "table" and type(rgx.Remember) == "function" then
        return rgx:Remember(target, defaults)
    end

    target = target or {}
    defaults = defaults or {}

    for key, value in pairs(defaults) do
        if type(value) == "table" then
            target[key] = self:Remember(target[key] or {}, value)
        elseif target[key] == nil then
            target[key] = value
        end
    end

    return target
end

function ETL:Watch(event, thenDo)
    local rgx = self:GetFramework()
    if type(rgx) == "table" and type(rgx.Watch) == "function" then
        return rgx:Watch(event, function(...)
            thenDo(ETL, ...)
        end)
    end

    private.localWowEventHandlers[event] = private.localWowEventHandlers[event] or {}
    table.insert(private.localWowEventHandlers[event], thenDo)
    private.localWowEventFrame:RegisterEvent(event)
    return thenDo
end

function ETL:WatchMany(events, thenDo)
    local bindings = {}
    for _, event in ipairs(events or {}) do
        table.insert(bindings, self:Watch(event, thenDo))
    end
    return bindings
end

function ETL:StopWatching(event, thenDo)
    local rgx = self:GetFramework()
    if type(rgx) == "table" and type(rgx.StopWatching) == "function" then
        return rgx:StopWatching(event, thenDo)
    end

    local handlers = private.localWowEventHandlers[event]
    if not handlers then
        return false
    end

    for index, func in ipairs(handlers) do
        if func == thenDo then
            table.remove(handlers, index)
            if #handlers == 0 then
                private.localWowEventHandlers[event] = nil
                private.localWowEventFrame:UnregisterEvent(event)
            end
            return true
        end
    end

    return false
end

function ETL:WatchOnce(event, thenDo)
    local wrapped
    wrapped = self:Watch(event, function(selfRef, ...)
        selfRef:StopWatching(event, wrapped)
        thenDo(selfRef, ...)
    end)
    return wrapped
end

function ETL:After(seconds, thenDo)
    local rgx = self:GetFramework()
    if type(rgx) == "table" and type(rgx.After) == "function" then
        return rgx:After(seconds, function()
            thenDo(ETL)
        end)
    end

    if _G.C_Timer and C_Timer.After then
        C_Timer.After(seconds or 0, function()
            thenDo(ETL)
        end)
        return true
    end

    thenDo(ETL)
    return true
end

function ETL:Hook(thing, action, thenDo)
    local rgx = self:GetFramework()
    if type(rgx) == "table" and type(rgx.Hook) == "function" then
        return rgx:Hook(thing, action, thenDo)
    end

    if not thing or type(action) ~= "string" or type(thenDo) ~= "function" then
        return false
    end

    hooksecurefunc(thing, action, thenDo)
    return true
end

function ETL:HookMany(hooks)
    local rgx = self:GetFramework()
    if type(rgx) == "table" and type(rgx.HookMany) == "function" then
        return rgx:HookMany(hooks)
    end

    local count = 0
    for _, hookInfo in ipairs(hooks or {}) do
        if self:Hook(hookInfo.thing or hookInfo[1], hookInfo.action or hookInfo[2], hookInfo.thenDo or hookInfo[3]) then
            count = count + 1
        end
    end
    return count
end

function ETL:WatchFrames(scrollBox, thenDo)
    local rgx = self:GetFramework()
    if type(rgx) == "table" and type(rgx.WatchFrames) == "function" then
        return rgx:WatchFrames(scrollBox, function(frame, ...)
            thenDo(ETL, frame, ...)
        end, ETL)
    end

    if not scrollBox or not (_G.ScrollUtil and ScrollUtil.AddAcquiredFrameCallback) or type(thenDo) ~= "function" then
        return false
    end

    ScrollUtil.AddAcquiredFrameCallback(scrollBox, function(_, frame, ...)
        thenDo(ETL, frame, ...)
    end, ETL)
    return true
end

function ETL:ForEachVisible(scrollBox, thenDo)
    local rgx = self:GetFramework()
    if type(rgx) == "table" and type(rgx.ForEachVisible) == "function" then
        return rgx:ForEachVisible(scrollBox, function(frame, ...)
            thenDo(ETL, frame, ...)
        end)
    end

    if not scrollBox or not scrollBox.ForEachFrame or type(thenDo) ~= "function" then
        return 0
    end

    local count = 0
    scrollBox:ForEachFrame(function(frame, ...)
        count = count + 1
        thenDo(ETL, frame, ...)
    end)
    return count
end

function ETL:Put(thing, points)
    local rgx = self:GetFramework()
    if type(rgx) == "table" and type(rgx.Put) == "function" then
        return rgx:Put(thing, points)
    end

    if not thing or not thing.SetPoint then
        return thing
    end

    local list = points
    if list and list[1] and type(list[1]) ~= "table" then
        list = { list }
    end

    if thing.ClearAllPoints then
        thing:ClearAllPoints()
    end

    for _, point in ipairs(list or {}) do
        thing:SetPoint(unpack(point))
    end

    return thing
end

function ETL:Resize(thing, sizeOrWidth, height)
    local rgx = self:GetFramework()
    if type(rgx) == "table" and type(rgx.Resize) == "function" then
        return rgx:Resize(thing, sizeOrWidth, height)
    end

    if not thing or not thing.SetSize then
        return thing
    end

    if type(sizeOrWidth) == "table" then
        thing:SetSize(unpack(sizeOrWidth))
    else
        thing:SetSize(sizeOrWidth, height)
    end

    return thing
end

function ETL:Paint(thing, style)
    local rgx = self:GetFramework()
    if type(rgx) == "table" and type(rgx.Paint) == "function" then
        return rgx:Paint(thing, style)
    end

    if not thing or type(style) ~= "table" then
        return thing
    end

    if style.backdrop and thing.SetBackdrop then
        thing:SetBackdrop(style.backdrop)
    end
    if style.backdropColor and thing.SetBackdropColor then
        thing:SetBackdropColor(unpack(style.backdropColor))
    end
    if style.statusBarTexture and thing.SetStatusBarTexture then
        thing:SetStatusBarTexture(style.statusBarTexture)
    end
    if style.statusBarColor and thing.SetStatusBarColor then
        thing:SetStatusBarColor(unpack(style.statusBarColor))
    end
    if style.fontObject and thing.SetFontObject then
        thing:SetFontObject(style.fontObject)
    end
    if style.texture and thing.SetTexture then
        thing:SetTexture(style.texture)
    end
    if style.texCoord and thing.SetTexCoord then
        thing:SetTexCoord(unpack(style.texCoord))
    end
    if style.strata and thing.SetFrameStrata then
        thing:SetFrameStrata(style.strata)
    end

    return thing
end

function ETL:Write(thing, text)
    local rgx = self:GetFramework()
    if type(rgx) == "table" and type(rgx.Write) == "function" then
        return rgx:Write(thing, text)
    end

    if thing and thing.SetText then
        thing:SetText(text)
    end
    return thing
end

function ETL:When(thing, scriptName, thenDo)
    local rgx = self:GetFramework()
    if type(rgx) == "table" and type(rgx.When) == "function" then
        return rgx:When(thing, scriptName, thenDo)
    end

    if not thing or not thing.SetScript or type(scriptName) ~= "string" or type(thenDo) ~= "function" then
        return false
    end

    thing:SetScript(scriptName, thenDo)
    return true
end

function ETL:ShowThing(thing)
    if thing and thing.Show then
        thing:Show()
    end
    return thing
end

function ETL:HideThing(thing)
    if thing and thing.Hide then
        thing:Hide()
    end
    return thing
end

function ETL:MakeBox(parent, config)
    local rgx = self:GetFramework()
    if type(rgx) == "table" and type(rgx.MakeBox) == "function" then
        return rgx:MakeBox(parent, config)
    end

    config = config or {}
    local thing = CreateFrame("Frame", config.name, parent or config.parent or UIParent, config.template)
    self:Paint(thing, config)
    if config.points then
        self:Put(thing, config.points)
    end
    if config.size then
        self:Resize(thing, config.size)
    end
    return thing
end

function ETL:MakeButton(parent, config)
    local rgx = self:GetFramework()
    if type(rgx) == "table" and type(rgx.MakeButton) == "function" then
        return rgx:MakeButton(parent, config)
    end

    config = config or {}
    local thing = CreateFrame("Button", config.name, parent or config.parent or UIParent, config.template)
    self:Paint(thing, config)
    if config.points then
        self:Put(thing, config.points)
    end
    if config.size then
        self:Resize(thing, config.size)
    end
    return thing
end

function ETL:MakeBar(parent, config)
    local rgx = self:GetFramework()
    if type(rgx) == "table" and type(rgx.MakeBar) == "function" then
        return rgx:MakeBar(parent, config)
    end

    config = config or {}
    local thing = CreateFrame("StatusBar", config.name, parent or config.parent or UIParent, config.template)
    self:Paint(thing, config)
    if config.points then
        self:Put(thing, config.points)
    end
    if config.size then
        self:Resize(thing, config.size)
    end
    return thing
end

function ETL:MakeWords(parent, text, config)
    local rgx = self:GetFramework()
    if type(rgx) == "table" and type(rgx.MakeWords) == "function" then
        return rgx:MakeWords(parent, text, config)
    end

    config = config or {}
    local thing = (parent or config.parent or UIParent):CreateFontString(config.name, config.layer or "OVERLAY")
    self:Paint(thing, config)
    if config.points then
        self:Put(thing, config.points)
    elseif config.point then
        thing:SetPoint(unpack(config.point))
    end
    if config.fontObject then
        thing:SetFontObject(config.fontObject)
    end
    if text ~= nil then
        self:Write(thing, text)
    end
    return thing
end

function ETL:MakePicture(parent, config)
    local rgx = self:GetFramework()
    if type(rgx) == "table" and type(rgx.MakePicture) == "function" then
        return rgx:MakePicture(parent, config)
    end

    config = config or {}
    local thing = (parent or config.parent or UIParent):CreateTexture(config.name, config.layer or "ARTWORK")
    self:Paint(thing, config)
    if config.points then
        self:Put(thing, config.points)
    elseif config.point then
        thing:SetPoint(unpack(config.point))
    end
    if config.size then
        self:Resize(thing, config.size)
    end
    return thing
end

function ETL:StretchAcross(thing, parent, leftInset, rightInset, bottomInset)
    local rgx = self:GetFramework()
    if type(rgx) == "table" and type(rgx.StretchAcross) == "function" then
        return rgx:StretchAcross(thing, parent, leftInset, rightInset, bottomInset)
    end

    return self:Put(thing, {
        {"BOTTOMLEFT", parent, "BOTTOMLEFT", leftInset or 0, bottomInset or 0},
        {"BOTTOMRIGHT", parent, "BOTTOMRIGHT", rightInset or 0, bottomInset or 0},
    })
end

function ETL:Fill(thing, parent, inset)
    local rgx = self:GetFramework()
    if type(rgx) == "table" and type(rgx.Fill) == "function" then
        return rgx:Fill(thing, parent, inset)
    end

    inset = inset or 0
    return self:Put(thing, {
        {"TOPLEFT", parent, "TOPLEFT", inset, -inset},
        {"BOTTOMRIGHT", parent, "BOTTOMRIGHT", -inset, inset},
    })
end

function ETL:PutTextAbove(thing, thingBelow, leftThing, leftInset, leftY)
    local rgx = self:GetFramework()
    if type(rgx) == "table" and type(rgx.PutTextAbove) == "function" then
        return rgx:PutTextAbove(thing, thingBelow, leftThing, leftInset, leftY)
    end

    return self:Put(thing, {
        {"LEFT", leftThing or thing:GetParent(), "LEFT", leftInset or 0, leftY or 0},
        {"BOTTOM", thingBelow, "TOP", 0, 0},
    })
end
