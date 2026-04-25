-- Local UI helpers — thin wrappers around raw WoW frame APIs.
local function MakeFrame(parent, config)
    local f = CreateFrame("Frame", config.name, parent, config.template)
    if config.strata then f:SetFrameStrata(config.strata) end
    return f
end

local function MakeBar(parent)
    return CreateFrame("StatusBar", nil, parent)
end

local function MakePicture(parent, layer)
    return parent:CreateTexture(nil, layer or "ARTWORK")
end

local function MakeText(parent, layer, fontObject)
    local t = parent:CreateFontString(nil, layer or "OVERLAY")
    if fontObject then t:SetFontObject(fontObject) end
    return t
end

local function Put(thing, points)
    thing:ClearAllPoints()
    for _, p in ipairs(points) do thing:SetPoint(unpack(p)) end
end

-- ─────────────────────────────────────────────────────────────────────────────

function ETL:GetProgressBarLayout(button, data)
    local s = self:GetSettings()
    local isChild = (data and data.isChild) or (button.GetHeight and button:GetHeight() < 60)

    if isChild then
        return {
            barHeight  = s.childBarHeight,
            bottomInset = s.childBottomInset,
            leftInset  = s.childTextLeft,
            rightInset = s.rightInsetChild,
            fontObject = "GameFontNormalSmall",
            inset      = 1,
            textLift   = s.childTextLift or 0,
        }
    end
    return {
        barHeight  = s.parentBarHeight,
        bottomInset = s.parentBottomInset,
        leftInset  = s.parentTextLeft,
        rightInset = s.rightInsetParent,
        fontObject = "GameFontHighlightSmall",
        inset      = 1,
        textLift   = s.parentTextLift or 0,
    }
end

function ETL:EnsureProgressWidgets(button)
    if button.ETL_ProgressBarBg and button.ETL_ProgressBar and button.ETL_ProgressTextFrame and button.ETL_ProgressBarText then
        return
    end

    local bg = MakeFrame(button, { strata = "MEDIUM" })
    button.ETL_ProgressBarBg = bg

    local bgFill = MakePicture(bg, "BACKGROUND")
    bgFill:SetTexture("Interface\\Buttons\\WHITE8X8")
    bgFill:SetAllPoints(bg)
    bgFill:SetVertexColor(0, 0, 0, 0.75)
    button.ETL_ProgressBarBgFill = bgFill

    local r, g, b = self:GetConfiguredBarColor()
    local bar = MakeBar(bg)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetStatusBarColor(r, g, b, 1)
    button.ETL_ProgressBar = bar

    local textFrame = MakeFrame(button, { strata = "HIGH" })
    button.ETL_ProgressTextFrame = textFrame

    local text = MakeText(textFrame, "OVERLAY", "GameFontNormalSmall")
    text:SetDrawLayer("OVERLAY", 7)
    text:SetJustifyH("CENTER")
    text:SetJustifyV("MIDDLE")
    text:SetTextColor(1, 1, 1, 1)
    text:SetShadowOffset(1, -1)
    text:SetShadowColor(0, 0, 0, 0.9)
    button.ETL_ProgressBarText = text

    -- Start hidden; UpdateProgressBar decides visibility.
    self:HideProgressBar(button)
end

function ETL:HideProgressBar(button)
    if button and button.ETL_ProgressBarBg     then button.ETL_ProgressBarBg:Hide() end
    if button and button.ETL_ProgressBar       then button.ETL_ProgressBar:Hide() end
    if button and button.ETL_ProgressTextFrame then button.ETL_ProgressTextFrame:Hide() end
    if button and button.ETL_ProgressBarText   then button.ETL_ProgressBarText:Hide() end
end

function ETL:ApplyProgressBarLayout(button, data)
    if not button.ETL_ProgressBarBg or not button.ETL_ProgressBar then return end

    local layout = self:GetProgressBarLayout(button, data)
    local bg     = button.ETL_ProgressBarBg
    local bar    = button.ETL_ProgressBar
    local text   = button.ETL_ProgressBarText

    Put(bg, {
        { "BOTTOMLEFT",  button, "BOTTOMLEFT",  layout.leftInset,  layout.bottomInset },
        { "BOTTOMRIGHT", button, "BOTTOMRIGHT", layout.rightInset, layout.bottomInset },
    })
    bg:SetHeight(layout.barHeight)

    if button.ETL_ProgressTextFrame then
        Put(button.ETL_ProgressTextFrame, {
            { "TOPLEFT",     bg, "TOPLEFT",     0, 0 },
            { "BOTTOMRIGHT", bg, "BOTTOMRIGHT", 0, 0 },
        })
    end

    Put(bar, {
        { "TOPLEFT",     bg, "TOPLEFT",     layout.inset,  -layout.inset },
        { "BOTTOMRIGHT", bg, "BOTTOMRIGHT", -layout.inset, layout.inset  },
    })
    text:SetPoint("CENTER", button.ETL_ProgressTextFrame or bg, "CENTER", 0, 1)

    if text.SetFontObject then text:SetFontObject(layout.fontObject) end
end

function ETL:ShowRow(button)
    if not button then return end
    if button.ETL_OriginalHeight and button.SetHeight then
        button:SetHeight(button.ETL_OriginalHeight)
    end
    button.ETL_HiddenByAddon = nil
    if button.SetAlpha   then button:SetAlpha(1) end
    if button.EnableMouse then button:EnableMouse(true) end
end

function ETL:HideRow(button)
    if not button then return end
    button.ETL_HiddenByAddon = true
    if button.GetHeight and button.SetHeight then
        button.ETL_OriginalHeight = button.ETL_OriginalHeight or button:GetHeight()
        button:SetHeight(1)
    end
    self:HideProgressBar(button)
    if button.SetAlpha   then button:SetAlpha(0) end
    if button.EnableMouse then button:EnableMouse(false) end
end

function ETL:ShouldHideActivityRow(data)
    return self:GetSettings().hideCompleted == true and self:IsActivityCompleted(data)
end

function ETL:UpdateProgressBar(button)
    if self:DetectDuplicateInstall() or not self:GetSettings().enabled then
        self:HideProgressBar(button)
        return
    end

    if not button or not button.ETL_ProgressBar then return end

    local data = self:GetActiveActivityNode(self:GetActivityData(button))
    local current, total, label = self:BuildProgress(data and data.requirementsList)

    if not current or not total or total <= 0 then
        -- WoW removes requirementsList from completed activities — show a full bar.
        if data and data.completed then
            current, total, label = 1, 1, "Complete"
        else
            self:HideProgressBar(button)
            return
        end
    end

    if data and data.completed then
        current = total
        if not label or label == "" then label = "Complete" end
    end

    local r, g, b = self:GetConfiguredBarColor()
    button.ETL_ProgressBar:SetStatusBarColor(r, g, b, 1)

    local shown = math.min(current, total)
    button.ETL_ProgressBarBg:Show()
    button.ETL_ProgressBar:Show()
    if button.ETL_ProgressTextFrame then button.ETL_ProgressTextFrame:Show() end
    if button.ETL_ProgressBarText   then button.ETL_ProgressBarText:Show() end
    button.ETL_ProgressBar:SetMinMaxValues(0, total)
    button.ETL_ProgressBar:SetValue(shown)
    if button.ETL_ProgressBarText then
        button.ETL_ProgressBarText:SetText(label or string.format("%d / %d", shown, total))
    end
end

function ETL:DecorateRow(button)
    if not button or type(button) ~= "table" then return end

    local data = self:GetActivityData(button)
    if self:ShouldHideActivityRow(data) then
        self:HideRow(button)
        return
    end

    self:ShowRow(button)
    data = self:GetActiveActivityNode(data)
    self:EnsureProgressWidgets(button)
    self:ApplyProgressBarLayout(button, data)
    self:UpdateProgressBar(button)
end

function ETL:HideVisibleRows(scrollBox)
    if not scrollBox or not scrollBox.ForEachFrame then return end
    scrollBox:ForEachFrame(function(_, button)
        ETL:HideProgressBar(button)
    end)
end

function ETL:RefreshVisibleRows(scrollBox)
    if not scrollBox or not scrollBox.ForEachFrame then return end
    scrollBox:ForEachFrame(function(_, button)
        ETL:DecorateRow(button)
    end)
end
