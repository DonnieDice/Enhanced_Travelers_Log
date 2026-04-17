ETL = ETL or {}

local ADDON_NAME = "EnhancedTravelersLog"
local DEFAULT_MINIMAP_ANGLE = 220
local PREFIX = "|cff950041[ETL]|r "

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")

local function PrintMessage(message)
    print(PREFIX .. message)
end

local function TrimInput(input)
    return (input or ""):match("^%s*(.-)%s*$")
end

function ETL:CreateMinimapButton()
    if self.minimapButton or not Minimap then
        return
    end

    local button = CreateFrame("Button", "ETL_MinimapButton", Minimap, "SecureActionButtonTemplate")
    self.minimapButton = button

    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(Minimap:GetFrameLevel() + 8)
    button:SetMovable(true)
    button:EnableMouse(true)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", button, "CENTER", 0, -1)
    icon:SetTexture("Interface\\AddOns\\EnhancedTravelersLog\\images\\icon")
    icon:SetTexCoord(0.02, 0.98, 0.02, 0.98)
    button.icon = icon

    local overlay = button:CreateTexture(nil, "OVERLAY")
    overlay:SetSize(54, 54)
    overlay:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    button.overlay = overlay

    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    button:SetScript("PreClick", function(self, mouseButton)
        if self.isDragging then
            return
        end

        if mouseButton == "LeftButton" then
            ETL:HandleMinimapClick()
        end
    end)

    button:SetScript("OnDragStart", function(self)
        self.isDragging = true
        if GameTooltip then
            GameTooltip:Hide()
        end
        self:SetScript("OnUpdate", function()
            ETL:UpdateMinimapPositionFromCursor()
        end)
    end)

    button:SetScript("OnDragStop", function(self)
        self.isDragging = false
        self:SetScript("OnUpdate", nil)
        ETL:UpdateMinimapButtonPosition()
    end)

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("Enhanced Traveler's Log")
        GameTooltip:AddLine("Left-click: Open Traveler's Log", 1, 1, 1)
        GameTooltip:AddLine("Left-drag: Move icon", 1, 1, 1)
        GameTooltip:AddLine("Ctrl+Right-click: Hide icon", 1, 1, 1)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    button:SetScript("OnMouseDown", function(self, mouseButton)
        if mouseButton == "RightButton" and IsControlKeyDown() then
            self.isCtrlRightClick = true
        end
    end)

    button:SetScript("OnMouseUp", function(self, mouseButton)
        if mouseButton == "RightButton" and self.isCtrlRightClick and IsControlKeyDown() then
            self.isCtrlRightClick = false
            GameTooltip:Hide()
            ETL:ToggleMinimapIcon(false)
            return
        end

        self.isCtrlRightClick = false
    end)
end

function ETL:UpdateMinimapButtonPosition()
    if not self.minimapButton or not Minimap then
        return
    end

    local angle = math.rad((ETLDB and ETLDB.minimapAngle) or DEFAULT_MINIMAP_ANGLE)
    local minimapRadius = math.max(Minimap:GetWidth() or 140, Minimap:GetHeight() or 140) / 2 + 10
    local x = math.cos(angle) * minimapRadius
    local y = math.sin(angle) * minimapRadius

    self.minimapButton:ClearAllPoints()
    self.minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function ETL:UpdateMinimapPositionFromCursor()
    if not self.minimapButton or not ETLDB or not Minimap then
        return
    end

    local mx, my = Minimap:GetCenter()
    local scale = Minimap:GetEffectiveScale()
    local cx, cy = GetCursorPosition()
    cx = cx / scale
    cy = cy / scale

    if not mx or not my then
        return
    end

    local dy = cy - my
    local dx = cx - mx
    local angle = math.deg((math.atan2 and math.atan2(dy, dx)) or math.atan(dy, dx))
    if angle < 0 then
        angle = angle + 360
    end

    ETLDB.minimapAngle = angle
    self:UpdateMinimapButtonPosition()
end

function ETL:ToggleMinimapIcon(show)
    ETLDB.minimapIconEnabled = show
    self:ApplyMinimapVisibility()

    if show then
        PrintMessage("Minimap icon shown.")
    else
        PrintMessage("Minimap icon hidden. Use /etl icon on to show it again.")
    end
end

function ETL:ApplyMinimapVisibility()
    if not self.minimapButton then
        return
    end

    if ETLDB and ETLDB.minimapIconEnabled then
        self.minimapButton:Show()
        self:UpdateMinimapButtonPosition()
    else
        self.minimapButton:Hide()
    end
end

function ETL:HandleMinimapClick()
    if ETL.OpenTravelersLog then ETL:OpenTravelersLog() end
end

function ETL:PrintStatus()
    local iconState = (ETLDB and ETLDB.minimapIconEnabled) and "shown" or "hidden"
    local angle = ETLDB and ETLDB.minimapAngle or DEFAULT_MINIMAP_ANGLE
    PrintMessage("Minimap icon is " .. iconState .. ".")
    PrintMessage("Saved minimap angle: " .. string.format("%.1f", angle))
end

function ETL:DisplayHelp()
    PrintMessage("Available commands:")
    PrintMessage("/etl - Open Traveler's Log")
    PrintMessage("/etl icon - Show minimap icon commands")
    PrintMessage("/etl icon on - Show the minimap icon")
    PrintMessage("/etl icon off - Hide the minimap icon")
    PrintMessage("/etl status - Show minimap icon status")
    PrintMessage("/etl help - Show this help message")
end

function ETL:HandleSlashCommands(input)
    input = TrimInput(input):lower()

    if input == "" then
        self:HandleMinimapClick()
    elseif input == "icon" then
        PrintMessage("Use /etl icon on or /etl icon off.")
    elseif input == "icon on" then
        self:ToggleMinimapIcon(true)
    elseif input == "icon off" then
        self:ToggleMinimapIcon(false)
    elseif input == "status" then
        self:PrintStatus()
    elseif input == "help" then
        self:DisplayHelp()
    else
        PrintMessage("Unknown command. Type /etl help for a list of commands.")
    end
end

frame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName ~= ADDON_NAME and addonName ~= "Enhanced_Travelers_Log" then
            return
        end

        ETLDB = ETLDB or {}
        if ETLDB.minimapAngle == nil then
            ETLDB.minimapAngle = DEFAULT_MINIMAP_ANGLE
        end
        if ETLDB.minimapIconEnabled == nil then
            ETLDB.minimapIconEnabled = true
        end
    elseif event == "PLAYER_LOGIN" then
        SLASH_ETL1 = "/etl"
        SlashCmdList["ETL"] = function(input)
            ETL:HandleSlashCommands(input)
        end

        ETL:CreateMinimapButton()
        ETL:ApplyMinimapVisibility()
    end
end)
