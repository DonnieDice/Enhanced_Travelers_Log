local ADDON_NAME = "EnhancedTravelersLog"
local DEFAULT_MINIMAP_ANGLE = 220
local TOOLTIP_ICON = "|TInterface\\AddOns\\EnhancedTravelersLog\\media\\logo.tga:18:18:0:0|t "
local TOOLTIP_TITLE = TOOLTIP_ICON .. "|cff950041Enhanced Traveler's Log|r |cffd9c6ffTraveler's Log HUD|r"

local function GetVisibleRowCount()
    local frame = ETL:GetMonthlyActivitiesFrame()
    if not (frame and frame.ScrollBox and frame.ScrollBox.ForEachFrame) then
        return 0
    end

    local count = 0
    frame.ScrollBox:ForEachFrame(function()
        count = count + 1
    end)
    return count
end

function ETL:UpdateMinimapTooltip(owner)
    if not GameTooltip then
        return
    end

    local settings = self:GetSettings()
    local frame = self:GetMonthlyActivitiesFrame()
    local isLogOpen = frame and frame:IsShown()
    local visibleRows = isLogOpen and GetVisibleRowCount() or 0

    GameTooltip:SetOwner(owner or self.minimapButton, "ANCHOR_LEFT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine(TOOLTIP_TITLE)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cffd9c6ffTrack Traveler's Log progress with cleaner bars and quick access from the minimap.|r", 1, 1, 1, true)
    GameTooltip:AddLine(" ")
    GameTooltip:AddDoubleLine("|cff950041Left-Click|r", "|cffffffffOpen Traveler's Log|r", 1, 1, 1, 1, 1, 1)
    GameTooltip:AddDoubleLine("|cff4ecdc4Left-Drag|r", "|cffffffffMove around minimap|r", 1, 1, 1, 1, 1, 1)
    GameTooltip:AddDoubleLine("|cffe74c3cCtrl+Right-Click|r", "|cffffffffHide minimap icon|r", 1, 1, 1, 1, 1, 1)
    GameTooltip:Show()
end

function ETL:CreateMinimapButton()
    if self.minimapButton or not Minimap then
        return
    end

    local button = self:MakeButton(Minimap, {
        name = "ETL_MinimapButton",
        template = "SecureActionButtonTemplate",
        size = {32, 32},
        strata = "MEDIUM",
        level = Minimap:GetFrameLevel() + 8,
    })
    self.minimapButton = button

    button:SetMovable(true)
    button:EnableMouse(true)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")

    local backdrop = self:MakePicture(button, {
        layer = "BACKGROUND",
        size = {24, 24},
        point = {"CENTER", button, "CENTER", 1, 0},
        texture = "Interface\\Buttons\\WHITE8X8",
    })
    if backdrop.SetMask then
        backdrop:SetMask("Interface\\CharacterFrame\\TempPortraitAlphaMaskSmall")
    end
    backdrop:SetVertexColor(0.03, 0.03, 0.03, 0.98)
    button.backdrop = backdrop

    local icon = self:MakePicture(button, {
        layer = "ARTWORK",
        size = {19, 19},
        point = {"CENTER", button, "CENTER", 1, -2},
        texture = "Interface\\AddOns\\EnhancedTravelersLog\\media\\logo",
        texCoord = {0.02, 0.98, 0.02, 0.98},
    })
    button.icon = icon

    local overlay = self:MakePicture(button, {
        layer = "OVERLAY",
        size = {54, 54},
        point = {"TOPLEFT", button, "TOPLEFT", 0, 0},
        texture = "Interface\\Minimap\\MiniMap-TrackingBorder",
    })
    button.overlay = overlay

    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    self:When(button, "PreClick", function(self, mouseButton)
        if self.isDragging then
            return
        end

        if mouseButton == "LeftButton" then
            ETL:HandleMinimapClick()
        end
    end)

    self:When(button, "OnDragStart", function(self)
        self.isDragging = true
        if GameTooltip then
            GameTooltip:Hide()
        end
        ETL:When(self, "OnUpdate", function()
            ETL:UpdateMinimapPositionFromCursor()
        end)
    end)

    self:When(button, "OnDragStop", function(self)
        self.isDragging = false
        ETL:When(self, "OnUpdate", function() end)
        self:SetScript("OnUpdate", nil)
        ETL:UpdateMinimapButtonPosition()
    end)

    self:When(button, "OnEnter", function(self)
        ETL:UpdateMinimapTooltip(self)
    end)

    self:When(button, "OnLeave", function()
        GameTooltip:Hide()
    end)

    self:When(button, "OnMouseDown", function(self, mouseButton)
        if mouseButton == "RightButton" and IsControlKeyDown() then
            self.isCtrlRightClick = true
        end
    end)

    self:When(button, "OnMouseUp", function(self, mouseButton)
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
        self:Say("Minimap icon shown.")
    else
        self:Say("Minimap icon hidden. Use /etl icon on to show it again.")
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
    self:Say("Minimap icon is " .. iconState .. ".")
    self:Say("Saved minimap angle: " .. string.format("%.1f", angle))
end

function ETL:DisplayHelp()
    self:Say("Available commands:")
    self:Say("/etl - Open Traveler's Log")
    self:Say("/etl icon - Show minimap icon commands")
    self:Say("/etl icon on - Show the minimap icon")
    self:Say("/etl icon off - Hide the minimap icon")
    self:Say("/etl status - Show minimap icon status")
    self:Say("/etl help - Show this help message")
end

function ETL:HandleSlashCommands(input)
    input = self:TrimInput(input):lower()

    if input == "" then
        self:HandleMinimapClick()
    elseif input == "icon" then
        self:Say("Use /etl icon on or /etl icon off.")
    elseif input == "icon on" then
        self:ToggleMinimapIcon(true)
    elseif input == "icon off" then
        self:ToggleMinimapIcon(false)
    elseif input == "status" then
        self:PrintStatus()
    elseif input == "help" then
        self:DisplayHelp()
    else
        self:Say("Unknown command. Type /etl help for a list of commands.")
    end
end

ETL:Watch("ADDON_LOADED", function(self, addonName)
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
end)

ETL:Watch("PLAYER_LOGIN", function(self)
    SLASH_ETL1 = "/etl"
    SlashCmdList["ETL"] = function(input)
        self:HandleSlashCommands(input)
    end

    self:CreateMinimapButton()
    self:ApplyMinimapVisibility()
end)
