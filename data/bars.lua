function ETL:GetProgressBarLayout(button, data)
    local settings = self:GetSettings()
    local isChild = (data and data.isChild) or (button.GetHeight and button:GetHeight() < 60)

    if isChild then
        return {
            barHeight = settings.childBarHeight,
            bottomInset = settings.childBottomInset,
            leftInset = settings.childTextLeft,
            rightInset = settings.rightInsetChild,
            textOffsetX = settings.childTextLeft,
            fontObject = "GameFontNormalSmall",
            inset = 1,
            textLift = settings.childTextLift or 0,
            toggleLift = settings.childToggleLift or 0,
        }
    end

    return {
        barHeight = settings.parentBarHeight,
        bottomInset = settings.parentBottomInset,
        leftInset = settings.parentTextLeft,
        rightInset = settings.rightInsetParent,
        textOffsetX = settings.parentTextLeft,
        fontObject = "GameFontHighlightSmall",
        inset = 1,
        textLift = settings.parentTextLift or 0,
        toggleLift = settings.parentToggleLift or 0,
    }
end

function ETL:ResetRowLayout(button)
    return
end

function ETL:ReserveProgressBarSpace(button, data)
    return
end

function ETL:EnsureProgressWidgets(button)
    if button.ETL_ProgressBarBg and button.ETL_ProgressBar and button.ETL_ProgressTextFrame and button.ETL_ProgressBarText then
        return
    end

    local bg = self:MakeBox(button, {
        strata = "MEDIUM",
        level = (button.GetFrameLevel and (button:GetFrameLevel() + 1)) or nil,
    })
    button.ETL_ProgressBarBg = bg

    local bgFill = self:MakePicture(bg, {
        layer = "BACKGROUND",
        texture = "Interface\\Buttons\\WHITE8X8",
        points = {
            {"TOPLEFT", bg, "TOPLEFT", 0, 0},
            {"BOTTOMRIGHT", bg, "BOTTOMRIGHT", 0, 0},
        },
    })
    bgFill:SetVertexColor(0, 0, 0, 0.75)
    button.ETL_ProgressBarBgFill = bgFill

    local r, g, b = self:GetConfiguredBarColor()
    local bar = self:MakeBar(bg, {
        statusBarTexture = "Interface\\TargetingFrame\\UI-StatusBar",
        statusBarColor = {r, g, b, 1},
    })
    button.ETL_ProgressBar = bar

    local textFrame = self:MakeBox(button, {
        strata = "HIGH",
        level = (button.GetFrameLevel and (button:GetFrameLevel() + 12)) or nil,
    })
    button.ETL_ProgressTextFrame = textFrame

    self:Put(textFrame, {
        {"TOPLEFT", bg, "TOPLEFT", 0, 0},
        {"BOTTOMRIGHT", bg, "BOTTOMRIGHT", 0, 0},
    })

    local text = self:MakeWords(textFrame, nil, {
        layer = "OVERLAY",
        fontObject = "GameFontNormalSmall",
        point = {"CENTER", textFrame, "CENTER", 0, 1},
    })
    if text.SetDrawLayer then
        text:SetDrawLayer("OVERLAY", 7)
    end
    if text.SetJustifyH then
        text:SetJustifyH("CENTER")
    end
    if text.SetJustifyV then
        text:SetJustifyV("MIDDLE")
    end
    if text.SetTextColor then
        text:SetTextColor(1, 1, 1, 1)
    end
    if text.SetShadowOffset then
        text:SetShadowOffset(1, -1)
    end
    if text.SetShadowColor then
        text:SetShadowColor(0, 0, 0, 0.9)
    end
    button.ETL_ProgressBarText = text
end

function ETL:HideProgressBar(button)
    if button and button.ETL_ProgressBarBg then
        button.ETL_ProgressBarBg:Hide()
    end
    if button and button.ETL_ProgressBar then
        button.ETL_ProgressBar:Hide()
    end
    if button and button.ETL_ProgressTextFrame then
        button.ETL_ProgressTextFrame:Hide()
    end
    if button and button.ETL_ProgressBarText then
        button.ETL_ProgressBarText:Hide()
    end
    self:ResetRowLayout(button)
end

function ETL:ShowRow(button)
    if not button then
        return
    end

    if button.ETL_OriginalHeight and button.SetHeight then
        button:SetHeight(button.ETL_OriginalHeight)
    end

    button.ETL_HiddenByAddon = nil
    if button.SetAlpha then
        button:SetAlpha(1)
    end
    if button.EnableMouse then
        button:EnableMouse(true)
    end
end

function ETL:HideRow(button)
    if not button then
        return
    end

    button.ETL_HiddenByAddon = true
    if button.GetHeight and button.SetHeight then
        button.ETL_OriginalHeight = button.ETL_OriginalHeight or button:GetHeight()
        button:SetHeight(1)
    end
    self:HideProgressBar(button)
    if button.SetAlpha then
        button:SetAlpha(0)
    end
    if button.EnableMouse then
        button:EnableMouse(false)
    end
end

function ETL:ShouldHideActivityRow(data)
    local settings = self:GetSettings()
    return settings.hideCompleted == true and self:IsActivityCompleted(data)
end

function ETL:ApplyProgressBarLayout(button, data)
    if not button.ETL_ProgressBarBg or not button.ETL_ProgressBar then
        return
    end

    local layout = self:GetProgressBarLayout(button, data)
    local bg = button.ETL_ProgressBarBg
    local bar = button.ETL_ProgressBar
    local text = button.ETL_ProgressBarText

    self:StretchAcross(bg, button, layout.leftInset, layout.rightInset, layout.bottomInset)
    self:Resize(bg, {0, layout.barHeight})

    if button.ETL_ProgressTextFrame then
        self:Put(button.ETL_ProgressTextFrame, {
            {"TOPLEFT", bg, "TOPLEFT", 0, 0},
            {"BOTTOMRIGHT", bg, "BOTTOMRIGHT", 0, 0},
        })
    end

    self:Fill(bar, bg, layout.inset)

    self:Paint(text, {
        fontObject = layout.fontObject,
    })
end

function ETL:UpdateProgressBar(button)
    if self:DetectDuplicateInstall() or not self:GetSettings().enabled then
        self:HideProgressBar(button)
        return
    end

    if not button or not button.ETL_ProgressBar then
        return
    end

    local data = self:GetActiveActivityNode(self:GetActivityData(button))
    local current, total, label = self:BuildProgress(data and data.requirementsList)

    if not current or not total or total <= 0 then
        self:HideProgressBar(button)
        return
    end

    if data and data.completed and current < total then
        current = total
    end

    do
        local r, g, b = self:GetConfiguredBarColor()
        button.ETL_ProgressBar:SetStatusBarColor(r, g, b, 1)
    end

    local shown = math.min(current, total)
    self:ShowThing(button.ETL_ProgressBarBg)
    self:ShowThing(button.ETL_ProgressBar)
    self:ShowThing(button.ETL_ProgressTextFrame)
    self:ShowThing(button.ETL_ProgressBarText)
    button.ETL_ProgressBar:SetMinMaxValues(0, total)
    button.ETL_ProgressBar:SetValue(shown)
    self:Write(button.ETL_ProgressBarText, label or string.format("%d / %d", shown, total))
end

function ETL:DecorateRow(button)
    if not button or type(button) ~= "table" then
        return
    end

    local data = self:GetActivityData(button)
    if self:ShouldHideActivityRow(data) then
        self:HideRow(button)
        return
    end

    self:ShowRow(button)
    data = self:GetActiveActivityNode(data)
    self:EnsureProgressWidgets(button)
    self:ReserveProgressBarSpace(button, data)
    self:ApplyProgressBarLayout(button, data)
    self:UpdateProgressBar(button)
end

function ETL:HideVisibleRows(scrollBox)
    self:ForEachVisible(scrollBox, function(selfRef, button)
        selfRef:HideProgressBar(button)
    end)
end

function ETL:RefreshVisibleRows(scrollBox)
    self:ForEachVisible(scrollBox, function(selfRef, button)
        selfRef:DecorateRow(button)
    end)
end
