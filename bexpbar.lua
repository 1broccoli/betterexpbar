-- Initialize Ace3 addon
local BetterExpBar = LibStub("AceAddon-3.0"):NewAddon("BetterExpBar", "AceConsole-3.0", "AceEvent-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDB = LibStub("AceDB-3.0")
local LDB = LibStub("LibDataBroker-1.1", true)
local LDBIcon = LibStub("LibDBIcon-1.0", true)

-- Default settings
local defaults = {
    profile = {
        enabled = true,
        repBarEnabled = true,
        minimap = {
            hide = false,
            minimapPos = 225,
            lock = false,
        },
        barStyle = {
            backdropOpacity = 0.5,
            borderColor = { r = 1, g = 1, b = 1, a = 1 },
            scale = 1.0,
            synchronizeStyle = false,
            gloss = true,
            showBorder = true,
        },
        tooltip = {
            enabled = true,
            fontSize = 12,
            backgroundColor = { r = 0, g = 0, b = 0, a = 0.8 },
            borderColor = { r = 1, g = 1, b = 1, a = 1 },
            showOnHover = true,
            offsetY = 10,
            -- Experience bar tooltip options
            expTooltip = {
                showLevel = true,
                showCurrent = true,
                showRested = true,
                showRemaining = true,
                showPercentage = true,
            },
            -- Reputation bar tooltip options
            repTooltip = {
                showFactionName = true,
                showStanding = true,
                showCurrent = true,
                showRemaining = true,
                showPercentage = true,
            },
        },
        largerFrame = {
            point = "CENTER",
            relativePoint = "CENTER",
            xOfs = 0,
            yOfs = 0,
            width = 1034,
            height = 30,
        },
        expBar = {
            point = "TOP",
            relativePoint = "TOP",
            xOfs = 0,
            yOfs = -50,
            width = 1024,
            height = 20,
            opacity = 0.8,
            textSize = 12,
            showText = true,
            textFormat = "percentage", -- Options: percentage, none
        },
        repBar = {
            point = "TOP",
            relativePoint = "TOP",
            xOfs = 0,
            yOfs = -80,
            width = 1024,
            height = 20,
            opacity = 0.8,
            textSize = 12,
            showText = true,
            textFormat = "full", -- Options: full, percentage, name, none
        },
        colors = {
            exp = { r = 0.58, g = 0, b = 0.55, a = 0.8 },
            rested = { r = 0, g = 0.39, b = 0.88, a = 0.5 },
        },
    },
}

-- Frame references
local expBarContainer, largerFrame, expBarFrame, restedBar, expText, tooltipFrame, tooltipText, resizeHandle
local repBarFrame, repBarInner, repText, repTooltipFrame, repTooltipText, repResizeHandle

function BetterExpBar:OnInitialize()
    -- Initialize database with defaults
    self.db = AceDB:New("BetterExpBarDB", defaults, true)
    
    -- Register options
    self:RegisterOptions()
    
    -- Register slash commands
    self:RegisterChatCommand("beb", "SlashCommand")
    self:RegisterChatCommand("resetexpbar", "ResetPosition")
    self:RegisterChatCommand("enableexpbar", "EnableAddon")
    
    -- Create minimap button
    self:CreateMinimapButton()
end

function BetterExpBar:CreateMinimapButton()
    if not LDB or not LDBIcon then return end
    
    -- Create LDB data object
    local minimapButton = LDB:NewDataObject("BetterExpBar", {
        type = "launcher",
        text = "Better Exp Bar",
        icon = "Interface\\Icons\\XP_Icon",
        OnClick = function(self, button)
            if button == "LeftButton" then
                AceConfigDialog:Open("BetterExpBar")
            elseif button == "RightButton" then
                BetterExpBar:ResetPosition()
            end
        end,
        OnTooltipShow = function(tooltip)
            if not tooltip or not tooltip.AddLine then return end
            tooltip:AddLine("|cFF3B9C9CBetter Exp & Rep Bars|r")
            tooltip:AddLine(" ")
            tooltip:AddLine("|cFFFFFFFFLeft-click|r to open options")
            tooltip:AddLine("|cFFFFFFFFRight-click|r to reset position")
            tooltip:AddLine("|cFFFFFFFFDrag|r to move minimap icon")
        end,
    })
    
    -- Register with LibDBIcon
    LDBIcon:Register("BetterExpBar", minimapButton, self.db.profile.minimap)
end

function BetterExpBar:OnEnable()
    if not self.db.profile.enabled then
        self:Print("Better Exp Bar is disabled. Use /beb enable to enable it.")
        return
    end
    
    self:CreateFrames()
    
    -- XP Events
    self:RegisterEvent("PLAYER_XP_UPDATE", "UpdateExpBar")
    self:RegisterEvent("PLAYER_LEVEL_UP", "OnLevelUp")
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEnteringWorld")
    self:RegisterEvent("PLAYER_LOGOUT", "OnLogout")
    
    -- Rep Events
    if self.db.profile.repBarEnabled then
        self:RegisterEvent("UPDATE_FACTION", "UpdateRepBar")
    end
end

function BetterExpBar:OnDisable()
    if expBarContainer then expBarContainer:Hide() end
    if largerFrame then largerFrame:Hide() end
end

function BetterExpBar:SaveFramePosition(frame, configKey)
    if not self.db or not self.db.profile then return end
    if not self.db.profile[configKey] then
        self.db.profile[configKey] = {}
    end
    local point, _, relativePoint, xOfs, yOfs = frame:GetPoint()
    self.db.profile[configKey].point = point
    self.db.profile[configKey].relativePoint = relativePoint
    self.db.profile[configKey].xOfs = xOfs
    self.db.profile[configKey].yOfs = yOfs
    self.db.profile[configKey].width = frame:GetWidth()
    self.db.profile[configKey].height = frame:GetHeight()
end

function BetterExpBar:RestoreFramePosition(frame, configKey)
    if not self.db or not self.db.profile then return end
    local config = self.db.profile[configKey]
    if not config then return end
    if config.point and config.relativePoint then
        frame:ClearAllPoints()
        frame:SetPoint(config.point, UIParent, config.relativePoint, config.xOfs, config.yOfs)
    end
    if config.width and config.height then
        frame:SetSize(config.width, config.height)
    end
end

function BetterExpBar:ApplyBarStyle(frame, configKey)
    if not frame or not self.db or not self.db.profile then return end
    
    local styleConfig = self.db.profile.barStyle
    local barConfig = self.db.profile[configKey]
    
    if not barConfig then return end
    
    -- Apply opacity
    frame:SetAlpha(barConfig.opacity or 0.8)
    
    -- Apply scale
    frame:SetScale(styleConfig.scale or 1.0)
    
    -- Apply border color
    local bc = styleConfig.borderColor
    frame:SetBackdropBorderColor(bc.r or 1, bc.g or 1, bc.b or 1, bc.a or 1)
    
    -- Apply backdrop opacity
    frame:SetBackdropColor(0, 0, 0, styleConfig.backdropOpacity or 0.5)
end

function BetterExpBar:ApplyTooltipStyle(tooltipFrame, tooltipText)
    if not tooltipFrame or not tooltipText or not self.db or not self.db.profile then return end
    
    local tooltipConfig = self.db.profile.tooltip
    local bgColor = tooltipConfig.backgroundColor
    local borderColor = tooltipConfig.borderColor
    
    -- Apply colors
    tooltipFrame:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a)
    tooltipFrame:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)
    
    -- Apply font size
    tooltipText:SetFont("Fonts\\FRIZQT__.TTF", tooltipConfig.fontSize, "OUTLINE")
end

function BetterExpBar:UpdateAllTooltips()
    if tooltipFrame and tooltipText then
        self:ApplyTooltipStyle(tooltipFrame, tooltipText)
    end
    if repTooltipFrame and repTooltipText then
        self:ApplyTooltipStyle(repTooltipFrame, repTooltipText)
    end
end

function BetterExpBar:SynchronizeBarStyles()
    if not self.db.profile.barStyle.synchronizeStyle then return end
    
    if expBarFrame and largerFrame then
        self:ApplyBarStyle(largerFrame, "largerFrame")
        self:ApplyBarStyle(expBarFrame, "expBar")
    end
    
    if repBarFrame then
        self:ApplyBarStyle(repBarFrame, "repBar")
    end
end

function BetterExpBar:UpdateBarTextSize(barFrame, fontSize)
    if barFrame == expBarFrame and expText then
        expText:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "OUTLINE")
    elseif barFrame == repBarFrame and repText then
        repText:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "OUTLINE")
    end
end

function BetterExpBar:CreateFrames()
    -- Create container frame
    expBarContainer = CreateFrame("Frame", "CustomExpBarContainer", UIParent, "BackdropTemplate")
    expBarContainer:SetSize(self.db.profile.expBar.width, self.db.profile.expBar.height)
    expBarContainer:SetPoint("TOP", UIParent, "TOP", 0, -50)
    expBarContainer:SetBackdropColor(0, 0, 0, 0.8)
    expBarContainer:SetBackdropBorderColor(0, 0, 0)
    expBarContainer:SetFrameLevel(1)
    expBarContainer:EnableMouse(true)
    expBarContainer:SetMovable(true)
    expBarContainer:RegisterForDrag("LeftButton")
    expBarContainer:SetScript("OnDragStart", function(self) self:StartMoving() end)
    expBarContainer:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        BetterExpBar:SaveFramePosition(self, "expBar")
    end)
    expBarContainer:Show()

    -- Create larger frame
    largerFrame = CreateFrame("Frame", "LargerExpBarFrame", UIParent, "BackdropTemplate")
    largerFrame:SetSize(self.db.profile.largerFrame.width, self.db.profile.largerFrame.height)
    largerFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    largerFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 16,
    })
    largerFrame:SetBackdropColor(0, 0, 0, 0.5)
    largerFrame:SetBackdropBorderColor(1, 1, 1, 1)
    largerFrame:SetFrameLevel(1)
    largerFrame:EnableMouse(true)
    largerFrame:SetMovable(true)
    largerFrame:RegisterForDrag("LeftButton")
    largerFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    largerFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        BetterExpBar:SaveFramePosition(self, "largerFrame")
    end)
    largerFrame:SetResizable(true)

    -- Add the resize handle
    resizeHandle = CreateFrame("Frame", nil, largerFrame)
    resizeHandle:SetSize(8, 8)
    resizeHandle:SetPoint("BOTTOMRIGHT", largerFrame, "BOTTOMRIGHT", 0, 0)
    resizeHandle:EnableMouse(true)
    resizeHandle.texture = resizeHandle:CreateTexture(nil, "OVERLAY")
    resizeHandle.texture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeHandle.texture:SetSize(8, 8)
    resizeHandle.texture:SetPoint("CENTER", resizeHandle, "CENTER")
    resizeHandle:SetScript("OnEnter", function(self)
        self.texture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    end)
    resizeHandle:SetScript("OnLeave", function(self)
        self.texture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    end)
    resizeHandle:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            largerFrame:StartSizing("BOTTOMRIGHT")
            
            -- Add an OnUpdate handler to enforce size limits in real-time
            largerFrame:SetScript("OnUpdate", function(self)
                local currentWidth = self:GetWidth()
                local currentHeight = self:GetHeight()
                
                -- Enforce minimum and maximum width
                if currentWidth < 40 then
                    self:SetWidth(40)
                elseif currentWidth > 1500 then
                    self:SetWidth(1500)
                end
                
                -- Enforce minimum and maximum height
                if currentHeight < 20 then
                    self:SetHeight(20)
                elseif currentHeight > 200 then
                    self:SetHeight(200)
                end
            end)
        end
    end)
    resizeHandle:SetScript("OnMouseUp", function(self)
        self.texture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        largerFrame:StopMovingOrSizing()
        largerFrame:SetScript("OnUpdate", nil)
        BetterExpBar:SaveFramePosition(largerFrame, "largerFrame")
    end)

    -- Create experience bar
    expBarFrame = CreateFrame("StatusBar", "CustomExpBar", largerFrame, "TextStatusBar, BackdropTemplate")
    expBarFrame:SetSize(self.db.profile.expBar.width, self.db.profile.expBar.height)
    expBarFrame:SetPoint("CENTER", largerFrame, "CENTER", 0, 0)
    expBarFrame:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    expBarFrame:EnableMouse(true)
    expBarFrame:SetMovable(true)
    expBarFrame:RegisterForDrag("LeftButton")
    expBarFrame:SetScript("OnDragStart", function(self)
        largerFrame:StartMoving()
    end)
    expBarFrame:SetScript("OnDragStop", function(self)
        largerFrame:StopMovingOrSizing()
        BetterExpBar:SaveFramePosition(largerFrame, "largerFrame")
    end)
    local expColor = self.db.profile.colors.exp
    expBarFrame:SetStatusBarColor(expColor.r, expColor.g, expColor.b)
    expBarFrame:SetAlpha(self.db.profile.expBar.opacity)
    expBarFrame:SetFrameLevel(2)
    expBarFrame:Show()

    -- Create rested bar
    restedBar = CreateFrame("StatusBar", nil, expBarFrame)
    restedBar:SetAllPoints(expBarFrame)
    restedBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    local restedColor = self.db.profile.colors.rested
    restedBar:SetStatusBarColor(restedColor.r, restedColor.g, restedColor.b, restedColor.a)
    restedBar:SetFrameLevel(1)
    restedBar:Show()

    -- Create experience text
    expText = expBarFrame:CreateFontString(nil, "OVERLAY")
    expText:SetFont("Fonts\\FRIZQT__.TTF", self.db.profile.expBar.textSize, "OUTLINE")
    expText:SetPoint("CENTER", expBarFrame, "CENTER", 0, 0)

    -- Create tooltip frame
    tooltipFrame = CreateFrame("Frame", "ExpBarTooltipFrame", UIParent, "BackdropTemplate")
    tooltipFrame:SetSize(200, 100)
    tooltipFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 10,
    })
    tooltipFrame:SetPoint("BOTTOM", expBarFrame, "TOP", 0, self.db.profile.tooltip.offsetY)
    tooltipFrame:SetFrameStrata("TOOLTIP")
    tooltipFrame:Hide()

    tooltipText = tooltipFrame:CreateFontString(nil, "OVERLAY")
    tooltipText:SetFont("Fonts\\FRIZQT__.TTF", self.db.profile.tooltip.fontSize, "OUTLINE")
    tooltipText:SetPoint("TOPLEFT", tooltipFrame, "TOPLEFT", 10, -10)
    tooltipText:SetJustifyH("LEFT")
    tooltipText:SetJustifyV("TOP")
    tooltipText:SetText("")
    
    -- Apply tooltip styling
    self:ApplyTooltipStyle(tooltipFrame, tooltipText)

    -- Setup frame interactions
    expBarFrame:SetScript("OnEnter", function(self)
        if BetterExpBar.db.profile.tooltip.enabled then
            BetterExpBar:UpdateTooltipText()
            tooltipFrame:ClearAllPoints()
            tooltipFrame:SetPoint("BOTTOM", expBarFrame, "TOP", 0, BetterExpBar.db.profile.tooltip.offsetY)
            tooltipFrame:Show()
        end
    end)

    expBarFrame:SetScript("OnLeave", function(self)
        tooltipFrame:Hide()
    end)

    expBarFrame:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" then
            AceConfigDialog:Open("BetterExpBar")
        end
    end)

    expBarContainer:HookScript("OnSizeChanged", function()
        BetterExpBar:UpdateLargerFrame()
    end)

    largerFrame:HookScript("OnSizeChanged", function(self)
        local newWidth = math.max(self:GetWidth() - 10, 10)
        local newHeight = math.max(self:GetHeight() - 10, 5)
        expBarContainer:SetSize(newWidth, newHeight)
        expBarFrame:SetSize(newWidth, newHeight)
        BetterExpBar:UpdateExpBar()
    end)

    -- Restore saved positions
    self:RestoreFramePosition(largerFrame, "largerFrame")
    self:RestoreFramePosition(expBarContainer, "expBar")
    
    -- Apply initial styles
    self:ApplyBarStyle(largerFrame, "largerFrame")
    self:SynchronizeBarStyles()
    
    -- Hide default bars
    self:HideDefaultExpBar()
    
    -- Create reputation bar if enabled
    if self.db.profile.repBarEnabled then
        self:CreateRepBar()
    end
end

function BetterExpBar:CreateRepBar()
    -- Create reputation bar frame
    repBarFrame = CreateFrame("StatusBar", "BetterRepBar_MainBar", UIParent, "TextStatusBar, BackdropTemplate")
    repBarFrame:SetSize(self.db.profile.repBar.width, self.db.profile.repBar.height)
    repBarFrame:SetPoint("TOP", UIParent, "TOP", 0, -80)
    repBarFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 16,
    })
    repBarFrame:SetBackdropColor(0, 0, 0, 0.5)
    repBarFrame:SetBackdropBorderColor(1, 1, 1, 1)
    repBarFrame:SetFrameLevel(1)
    repBarFrame:EnableMouse(true)
    repBarFrame:SetMovable(true)
    repBarFrame:SetResizable(true)
    repBarFrame:RegisterForDrag("LeftButton")
    repBarFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    repBarFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        BetterExpBar:SaveFramePosition(self, "repBar")
    end)
    repBarFrame:Show()

    -- Create inner status bar (inset from border)
    repBarInner = CreateFrame("StatusBar", nil, repBarFrame)
    repBarInner:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    repBarInner:SetStatusBarColor(0, 0.39, 0.88)
    repBarInner:SetAlpha(self.db.profile.repBar.opacity)
    repBarInner:SetFrameLevel(repBarFrame:GetFrameLevel() + 1)
    local inset = 5
    repBarInner:SetPoint("TOPLEFT", repBarFrame, "TOPLEFT", inset, -inset)
    repBarInner:SetPoint("BOTTOMRIGHT", repBarFrame, "BOTTOMRIGHT", -inset, inset)
    repBarInner:SetMinMaxValues(0, 1)
    repBarInner:SetValue(0)
    repBarInner:Show()

    -- Create reputation text
    repText = repBarInner:CreateFontString(nil, "OVERLAY")
    repText:SetFont("Fonts\\FRIZQT__.TTF", self.db.profile.repBar.textSize, "OUTLINE")
    repText:SetPoint("CENTER", repBarInner, "CENTER", 0, 0)

    -- Create tooltip
    repTooltipFrame = CreateFrame("Frame", "RepBarTooltipFrame", UIParent, "BackdropTemplate")
    repTooltipFrame:SetSize(250, 100)
    repTooltipFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 10,
    })
    repTooltipFrame:SetPoint("BOTTOM", repBarFrame, "TOP", 0, self.db.profile.tooltip.offsetY)
    repTooltipFrame:SetFrameStrata("TOOLTIP")
    repTooltipFrame:Hide()

    repTooltipText = repTooltipFrame:CreateFontString(nil, "OVERLAY")
    repTooltipText:SetFont("Fonts\\FRIZQT__.TTF", self.db.profile.tooltip.fontSize, "OUTLINE")
    repTooltipText:SetPoint("TOPLEFT", repTooltipFrame, "TOPLEFT", 10, -10)
    repTooltipText:SetJustifyH("LEFT")
    repTooltipText:SetJustifyV("TOP")
    repTooltipText:SetText("")
    
    -- Apply tooltip styling
    self:ApplyTooltipStyle(repTooltipFrame, repTooltipText)

    -- Resize handle
    repResizeHandle = CreateFrame("Frame", nil, repBarFrame)
    repResizeHandle:SetSize(8, 8)
    repResizeHandle:SetPoint("BOTTOMRIGHT", repBarFrame, "BOTTOMRIGHT", 0, 0)
    repResizeHandle:EnableMouse(true)
    repResizeHandle.texture = repResizeHandle:CreateTexture(nil, "OVERLAY")
    repResizeHandle.texture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    repResizeHandle.texture:SetSize(8, 8)
    repResizeHandle.texture:SetPoint("CENTER", repResizeHandle, "CENTER")
    repResizeHandle:SetScript("OnEnter", function(self)
        self.texture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    end)
    repResizeHandle:SetScript("OnLeave", function(self)
        self.texture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    end)
    repResizeHandle:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            repBarFrame:StartSizing("BOTTOMRIGHT")
            repBarFrame:SetScript("OnUpdate", function(self)
                local currentWidth = self:GetWidth()
                local currentHeight = self:GetHeight()
                if currentWidth < 40 then
                    self:SetWidth(40)
                elseif currentWidth > 1500 then
                    self:SetWidth(1500)
                end
                if currentHeight < 20 then
                    self:SetHeight(20)
                elseif currentHeight > 200 then
                    self:SetHeight(200)
                end
            end)
        end
    end)
    repResizeHandle:SetScript("OnMouseUp", function(self)
        self.texture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        repBarFrame:StopMovingOrSizing()
        repBarFrame:SetScript("OnUpdate", nil)
        BetterExpBar:SaveFramePosition(repBarFrame, "repBar")
    end)

    -- Tooltip handlers
    repBarFrame:SetScript("OnEnter", function()
        if BetterExpBar.db.profile.tooltip.enabled then
            BetterExpBar:UpdateRepTooltip()
            repTooltipFrame:ClearAllPoints()
            repTooltipFrame:SetPoint("BOTTOM", repBarFrame, "TOP", 0, BetterExpBar.db.profile.tooltip.offsetY)
            repTooltipFrame:Show()
        end
    end)
    repBarFrame:SetScript("OnLeave", function()
        repTooltipFrame:Hide()
    end)
    repBarFrame:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" then
            AceConfigDialog:Open("BetterExpBar")
        end
    end)

    -- Size changed handler
    repBarFrame:HookScript("OnSizeChanged", function(frame)
        local newWidth = math.max(frame:GetWidth(), 40)
        local newHeight = math.max(frame:GetHeight(), 10)
        BetterExpBar:UpdateRepBar()
    end)

    -- Restore saved position
    self:RestoreFramePosition(repBarFrame, "repBar")
    
    -- Apply styles
    self:ApplyBarStyle(repBarFrame, "repBar")
    
    -- Initial update
    self:UpdateRepBar()
end

function BetterExpBar:FormatNumber(number)
    return tostring(number)
end

function BetterExpBar:UpdateTooltipText()
    local currentXP = UnitXP and UnitXP("player") or 0
    local maxXP = UnitXPMax and UnitXPMax("player") or 1
    local restedXP = GetXPExhaustion and (GetXPExhaustion() or 0) or 0
    local remainingXP = maxXP - currentXP
    local playerLevel = UnitLevel("player") or 0

    -- Calculate rested percent of level
    local restedPercent = 0
    if maxXP > 0 then
        restedPercent = math.floor((restedXP / maxXP) * 100 + 0.5)
    end

    local tooltipConfig = self.db.profile.tooltip.expTooltip
    local tooltipLines = {}

    -- Build tooltip based on settings
    if tooltipConfig.showLevel then
        table.insert(tooltipLines, string.format("Level: |cff00ff00%d|r", playerLevel))
    end
    
    if tooltipConfig.showCurrent then
        local percent = (maxXP > 0) and (currentXP / maxXP) * 100 or 0
        table.insert(tooltipLines, string.format("Current: %s / %s", 
            "|cffffff00" .. self:FormatNumber(currentXP) .. "|r",
            self:FormatNumber(maxXP)))
    end
    
    if tooltipConfig.showRested then
        table.insert(tooltipLines, string.format("Rested: |cff3399ff+%s|r |cff3399ff(%d%%)|r", 
            self:FormatNumber(restedXP),
            restedPercent))
    end
    
    if tooltipConfig.showRemaining then
        table.insert(tooltipLines, string.format("Remaining: |cffa335ee%s|r", 
            self:FormatNumber(remainingXP)))
    end

    tooltipText:SetText(table.concat(tooltipLines, "\n"))
    tooltipFrame:SetSize(tooltipText:GetStringWidth() + 20, tooltipText:GetStringHeight() + 20)
end

function BetterExpBar:UpdateLargerFrame()
    if not largerFrame.isResizing then
        largerFrame.isResizing = true
        largerFrame:SetSize(expBarContainer:GetWidth() + 10, expBarContainer:GetHeight() + 10)
        largerFrame.isResizing = false
    end
end

function BetterExpBar:UpdateExpBar()
    local currentXP = UnitXP("player")
    local maxXP = UnitXPMax("player")
    local restedXP = GetXPExhaustion() or 0

    expBarFrame:SetMinMaxValues(0, maxXP)
    expBarFrame:SetValue(currentXP)
    restedBar:SetMinMaxValues(0, maxXP)
    restedBar:SetValue(math.min(currentXP + restedXP, maxXP))
    
    -- Update text based on user preference
    if maxXP > 0 then
        local textFormat = self.db.profile.expBar.textFormat or "percentage"
        if textFormat == "percentage" then
            expText:SetText(string.format("%d%%", (currentXP / maxXP) * 100))
        elseif textFormat == "none" then
            expText:SetText("")
        else
            expText:SetText(string.format("%d%%", (currentXP / maxXP) * 100))
        end
    else
        expText:SetText("0%")
    end

    -- Update tooltip if visible
    if tooltipFrame and tooltipFrame:IsShown() then
        self:UpdateTooltipText()
    end
end

function BetterExpBar:UpdateRepBar()
    if not repBarInner or not repText then return end
    
    local name, standing, minRep, maxRep, currentRep, factionID
    
    -- Try GetWatchedFactionInfo if available
    if GetWatchedFactionInfo then
        name, standing, minRep, maxRep, currentRep, factionID = GetWatchedFactionInfo()
    else
        -- Fallback: look for watched faction in the UI
        if ReputationFrame and ReputationFrame.activeCategory then
            local scrollFrame = ReputationFrame.ScrollFrame
            if scrollFrame and scrollFrame.ScrollChild then
                for i = 1, scrollFrame.ScrollChild:GetNumChildren() do
                    local child = select(i, scrollFrame.ScrollChild:GetChildren())
                    if child and child.factionIndex then
                        -- GetFactionInfo returns: name, description, standing, min, max, value, atWar, canToggle, isHeader, collapsed, hasRep, isWatched
                        local n, desc, s, min, max, val = GetFactionInfo(child.factionIndex)
                        if n and child.HighlightTexture and child.HighlightTexture:IsShown() then
                            name, standing, minRep, maxRep, currentRep = n, s, min, max, val
                            factionID = child.factionIndex
                            break
                        end
                    end
                end
            end
        end
        
        -- Last resort: find the highest reputation faction
        if not name and GetNumFactions then
            local bestIndex, bestRep = nil, -42999
            for i = 1, GetNumFactions() do
                local n, desc, s, min, max, val = GetFactionInfo(i)
                if n and val then
                    local repVal = val - min
                    if repVal > bestRep then
                        bestRep = repVal
                        bestIndex = i
                        name, standing, minRep, maxRep, currentRep, factionID = n, s, min, max, val, i
                    end
                end
            end
        end
    end
    
    -- Ensure we have valid data before proceeding
    if not name or not currentRep or not minRep or not maxRep then
        repText:SetText("No Faction Tracked")
        repBarInner:SetStatusBarColor(0, 0, 0, 0)
        repBarInner:SetMinMaxValues(0, 1)
        repBarInner:SetValue(0)
        return
    end
    
    local maxValue = maxRep - minRep
    local currentValue = currentRep - minRep
    if maxValue <= 0 then maxValue = 1 end
    
    repBarInner:SetMinMaxValues(0, maxValue)
    repBarInner:SetValue(currentValue)
    
    -- Set color based on standing
    local color = FACTION_BAR_COLORS and FACTION_BAR_COLORS[standing]
    if color then
        repBarInner:SetStatusBarColor(color.r, color.g, color.b, 1)
    else
        repBarInner:SetStatusBarColor(1, 1, 1, 1)
    end
    
    -- Update text based on user preference
    local percent = (maxValue > 0) and (currentValue / maxValue) * 100 or 0
    local standingText = self:GetStandingText(standing)
    
    local color = "|cffffffff"
    if FACTION_BAR_COLORS and FACTION_BAR_COLORS[standing] then
        local c = FACTION_BAR_COLORS[standing]
        color = string.format("|cFF%02X%02X%02X", c.r*255, c.g*255, c.b*255)
    end
    
    local percentColor = "|cff33ffcc"
    local factionColor = "|cffffffff"
    
    local textFormat = self.db.profile.repBar.textFormat or "full"
    local displayText = ""
    if textFormat == "full" then
        displayText = string.format("%s%s|r: %s%d%%%s (%s%s|r)", factionColor, name, percentColor, percent, "|r", color, standingText)
    elseif textFormat == "percentage" then
        displayText = string.format("%d%%", percent)
    elseif textFormat == "name" then
        displayText = string.format("%s%s|r", factionColor, name)
    elseif textFormat == "none" then
        displayText = ""
    else
        displayText = string.format("%s%s|r: %s%d%%%s (%s%s|r)", factionColor, name, percentColor, percent, "|r", color, standingText)
    end
    
    repText:SetText(displayText)
    
    -- Update tooltip if visible
    if repTooltipFrame and repTooltipFrame:IsShown() then
        self:UpdateRepTooltip()
    end
end

function BetterExpBar:GetStandingText(standingID)
    local standingTexts = {
        [1] = "Hated",
        [2] = "Hostile",
        [3] = "Unfriendly",
        [4] = "Neutral",
        [5] = "Friendly",
        [6] = "Honored",
        [7] = "Revered",
        [8] = "Exalted",
    }
    return standingTexts[standingID] or "Unknown"
end

function BetterExpBar:UpdateRepTooltip()
    if not repTooltipText then return end
    
    local name, standing, minRep, maxRep, currentRep, factionID
    
    -- Try GetWatchedFactionInfo if available
    if GetWatchedFactionInfo then
        name, standing, minRep, maxRep, currentRep, factionID = GetWatchedFactionInfo()
    else
        -- Fallback: look for watched faction in the UI
        if ReputationFrame and ReputationFrame.activeCategory then
            local scrollFrame = ReputationFrame.ScrollFrame
            if scrollFrame and scrollFrame.ScrollChild then
                for i = 1, scrollFrame.ScrollChild:GetNumChildren() do
                    local child = select(i, scrollFrame.ScrollChild:GetChildren())
                    if child and child.factionIndex then
                        -- GetFactionInfo returns: name, description, standing, min, max, value, atWar, canToggle, isHeader, collapsed, hasRep, isWatched
                        local n, desc, s, min, max, val = GetFactionInfo(child.factionIndex)
                        if n and child.HighlightTexture and child.HighlightTexture:IsShown() then
                            name, standing, minRep, maxRep, currentRep = n, s, min, max, val
                            factionID = child.factionIndex
                            break
                        end
                    end
                end
            end
        end
        
        -- Last resort: find the highest reputation faction
        if not name and GetNumFactions then
            local bestIndex, bestRep = nil, -42999
            for i = 1, GetNumFactions() do
                local n, desc, s, min, max, val = GetFactionInfo(i)
                if n and val then
                    local repVal = val - min
                    if repVal > bestRep then
                        bestRep = repVal
                        bestIndex = i
                        name, standing, minRep, maxRep, currentRep, factionID = n, s, min, max, val, i
                    end
                end
            end
        end
    end
    
    -- Ensure we have valid data before proceeding
    if not name or not currentRep or not minRep or not maxRep then
        return
    end
    
    if name then
        local currentValue = currentRep - minRep
        local maxValue = maxRep - minRep
        local remainingValue = maxValue - currentValue
        
        local tooltipConfig = self.db.profile.tooltip.repTooltip
        local tooltipLines = {}
        
        local factionColor = "|cffffff00"
        local currentValueColor = "|cff3399ff"
        local standingColor = FACTION_BAR_COLORS[standing] and string.format("|cFF%02X%02X%02X", 
            FACTION_BAR_COLORS[standing].r * 255, 
            FACTION_BAR_COLORS[standing].g * 255, 
            FACTION_BAR_COLORS[standing].b * 255) or "|cFFFFFFFF"
        local remainingValueColor = "|cffa335ee"
        local whiteColor = "|cFFFFFFFF"
        
        -- Build tooltip based on settings
        if tooltipConfig.showFactionName then
            table.insert(tooltipLines, string.format("%s%s|r", factionColor, name))
        end
        
        if tooltipConfig.showStanding then
            table.insert(tooltipLines, string.format("%s%s|r", standingColor, self:GetStandingText(standing)))
        end
        
        if tooltipConfig.showCurrent then
            table.insert(tooltipLines, string.format("%sCurrent: %s%d|r%s / %d|r", 
                whiteColor, currentValueColor, currentValue, whiteColor, maxValue))
        end
        
        if tooltipConfig.showRemaining then
            table.insert(tooltipLines, string.format("%sRemaining: %s%d|r", 
                whiteColor, remainingValueColor, remainingValue))
        end
        
        repTooltipText:SetText(table.concat(tooltipLines, "\n"))
        
        repTooltipFrame:SetSize(repTooltipText:GetStringWidth() + 20, repTooltipText:GetStringHeight() + 20)
    else
        repTooltipText:SetText("No faction is currently being tracked.")
        repTooltipFrame:SetSize(repTooltipText:GetStringWidth() + 20, repTooltipText:GetStringHeight() + 20)
    end
end

function BetterExpBar:HideDefaultExpBar()
    if MainMenuBar and MainMenuBar.ExpBar then
        MainMenuBar.ExpBar:Hide()
        MainMenuBar.ExpBar:UnregisterAllEvents()
    end
    if ReputationWatchBar then
        ReputationWatchBar:Hide()
        ReputationWatchBar:UnregisterAllEvents()
    end
end

function BetterExpBar:OnEnteringWorld()
    self:HideDefaultExpBar()
    self:UpdateExpBar()
    if self.db.profile.repBarEnabled and repBarInner then
        self:UpdateRepBar()
    end
end

function BetterExpBar:OnLevelUp()
    self:UpdateExpBar()
end

function BetterExpBar:OnLogout()
    if largerFrame then
        self:SaveFramePosition(largerFrame, "largerFrame")
    end
    if expBarContainer then
        self:SaveFramePosition(expBarContainer, "expBar")
    end
    if repBarFrame then
        self:SaveFramePosition(repBarFrame, "repBar")
    end
end

-- Slash command handlers
function BetterExpBar:ResetPosition()
    if not largerFrame or not expBarContainer then
        self:Print("Frames not initialized yet.")
        return
    end
    
    -- Reset larger frame
    largerFrame:ClearAllPoints()
    largerFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    self.db.profile.largerFrame.point = "CENTER"
    self.db.profile.largerFrame.relativePoint = "CENTER"
    self.db.profile.largerFrame.xOfs = 0
    self.db.profile.largerFrame.yOfs = 0

    -- Reset exp bar container
    expBarContainer:ClearAllPoints()
    expBarContainer:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    self.db.profile.expBar.point = "CENTER"
    self.db.profile.expBar.relativePoint = "CENTER"
    self.db.profile.expBar.xOfs = 0
    self.db.profile.expBar.yOfs = 0

    -- Reset rep bar container if it exists
    if repBarFrame then
        repBarFrame:ClearAllPoints()
        repBarFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        self.db.profile.repBar.point = "CENTER"
        self.db.profile.repBar.relativePoint = "CENTER"
        self.db.profile.repBar.xOfs = 0
        self.db.profile.repBar.yOfs = 0
    end

    self:Print("Bar positions have been reset to the center.")
end

function BetterExpBar:EnableAddon()
    self.db.profile.enabled = true
    ReloadUI()
end

function BetterExpBar:DisableAddon()
    self.db.profile.enabled = false
    if expBarContainer then expBarContainer:Hide() end
    if largerFrame then largerFrame:Hide() end
    self:Print("Experience bar has been disabled.")
end

function BetterExpBar:SlashCommand(input)
    local command = string.lower(input or "")

    if command == "reset" then
        self:ResetPosition()
    elseif command == "enable" then
        self:EnableAddon()
    elseif command == "disable" then
        self:DisableAddon()
    elseif command == "togglerep" then
        self.db.profile.repBarEnabled = not self.db.profile.repBarEnabled
        if self.db.profile.repBarEnabled then
            if not repBarFrame then
                self:CreateRepBar()
            else
                repBarFrame:Show()
            end
            self:RegisterEvent("UPDATE_FACTION", "UpdateRepBar")
            self:Print("Reputation bar enabled")
        else
            if repBarFrame then
                repBarFrame:Hide()
            end
            self:UnregisterEvent("UPDATE_FACTION")
            self:Print("Reputation bar disabled")
        end
    elseif command == "config" or command == "options" then
        AceConfigDialog:Open("BetterExpBar")
    elseif command == "minimap" then
        if LDBIcon then
            self.db.profile.minimap.hide = not self.db.profile.minimap.hide
            if self.db.profile.minimap.hide then
                LDBIcon:Hide("BetterExpBar")
                self:Print("Minimap button hidden")
            else
                LDBIcon:Show("BetterExpBar")
                self:Print("Minimap button shown")
            end
        else
            self:Print("LibDBIcon not available")
        end
    else
        self:Print("Usage:")
        self:Print("/beb reset - Reset the position of bars")
        self:Print("/beb enable - Enable the addon")
        self:Print("/beb disable - Disable the addon")
        self:Print("/beb togglerep - Toggle reputation bar")
        self:Print("/beb minimap - Toggle minimap button")
        self:Print("/beb config - Open configuration options")
    end
end

-- Options configuration
function BetterExpBar:RegisterOptions()
    local options = {
        name = "Better Experience Bars",
        desc = "v2.7 | By Pegga",
        type = "group",
        args = {
            enabled = {
                type = "toggle",
                name = "Enable Experience Bar",
                desc = "Enable or disable the experience bar. |cFFFF6633(Reload UI required)|r",
                get = function() return self.db.profile.enabled end,
                set = function(_, value)
                    self.db.profile.enabled = value
                    ReloadUI()
                end,
                order = 1,
            },
            repBarEnabled = {
                type = "toggle",
                name = "Enable Reputation Bar",
                desc = "Enable or disable the reputation bar. |cFFFF6633(Reload UI required)|r",
                get = function() return self.db.profile.repBarEnabled end,
                set = function(_, value)
                    self.db.profile.repBarEnabled = value
                    ReloadUI()
                end,
                order = 2,
            },
            reset = {
                type = "execute",
                name = "Reset Position",
                desc = "Reset all bars to the center of the screen",
                func = function() self:ResetPosition() end,
                order = 3,
            },
            minimapGroup = {
                type = "group",
                name = "Minimap Button",
                inline = true,
                order = 3.5,
                args = {
                    hide = {
                        type = "toggle",
                        name = "Hide Minimap Button",
                        desc = "Hide the minimap button",
                        get = function() return self.db.profile.minimap.hide end,
                        set = function(_, value)
                            self.db.profile.minimap.hide = value
                            if LDBIcon then
                                if value then
                                    LDBIcon:Hide("BetterExpBar")
                                else
                                    LDBIcon:Show("BetterExpBar")
                                end
                            end
                        end,
                        order = 1,
                    },
                    lock = {
                        type = "toggle",
                        name = "Lock Minimap Button",
                        desc = "Prevent the minimap button from being dragged",
                        get = function() return self.db.profile.minimap.lock end,
                        set = function(_, value)
                            self.db.profile.minimap.lock = value
                            if LDBIcon then
                                if value then
                                    LDBIcon:Lock("BetterExpBar")
                                else
                                    LDBIcon:Unlock("BetterExpBar")
                                end
                            end
                        end,
                        order = 2,
                    },
                },
            },
            colors = {
                type = "group",
                name = "Experience Bar Colors",
                inline = true,
                order = 4,
                args = {
                    exp = {
                        type = "color",
                        name = "Experience Bar Color",
                        desc = "Color of the experience bar",
                        hasAlpha = true,
                        get = function()
                            local c = self.db.profile.colors.exp
                            return c.r, c.g, c.b, c.a
                        end,
                        set = function(_, r, g, b, a)
                            self.db.profile.colors.exp = { r = r, g = g, b = b, a = a }
                            if expBarFrame then
                                expBarFrame:SetStatusBarColor(r, g, b)
                                expBarFrame:SetAlpha(a)
                            end
                        end,
                    },
                    rested = {
                        type = "color",
                        name = "Rested Bar Color",
                        desc = "Color of the rested experience bar",
                        hasAlpha = true,
                        get = function()
                            local c = self.db.profile.colors.rested
                            return c.r, c.g, c.b, c.a
                        end,
                        set = function(_, r, g, b, a)
                            self.db.profile.colors.rested = { r = r, g = g, b = b, a = a }
                            if restedBar then
                                restedBar:SetStatusBarColor(r, g, b, a)
                            end
                        end,
                    },
                },
            },
            barStyle = {
                type = "group",
                name = "Bars Style",
                inline = false,
                order = 5,
                args = {
                    synchronizeStyle = {
                        type = "toggle",
                        name = "Synchronize Style",
                        desc = "Apply the same styling to both bars",
                        get = function() return self.db.profile.barStyle.synchronizeStyle end,
                        set = function(_, value)
                            self.db.profile.barStyle.synchronizeStyle = value
                            BetterExpBar:SynchronizeBarStyles()
                        end,
                        order = 1,
                    },
                    scale = {
                        type = "range",
                        name = "Bar Scale",
                        desc = "Scale both bars",
                        min = 0.5, max = 2.0, step = 0.1,
                        get = function() return self.db.profile.barStyle.scale end,
                        set = function(_, value)
                            self.db.profile.barStyle.scale = value
                            if largerFrame then largerFrame:SetScale(value) end
                            if repBarFrame then repBarFrame:SetScale(value) end
                        end,
                        order = 2,
                    },
                    backdropOpacity = {
                        type = "range",
                        name = "Background Opacity",
                        desc = "Opacity of the bar backgrounds",
                        min = 0, max = 1, step = 0.1,
                        get = function() return self.db.profile.barStyle.backdropOpacity end,
                        set = function(_, value)
                            self.db.profile.barStyle.backdropOpacity = value
                            BetterExpBar:SynchronizeBarStyles()
                        end,
                        order = 3,
                    },
                    borderColor = {
                        type = "color",
                        name = "Border Color",
                        desc = "Color of the bar borders",
                        hasAlpha = true,
                        get = function()
                            local c = self.db.profile.barStyle.borderColor
                            return c.r, c.g, c.b, c.a
                        end,
                        set = function(_, r, g, b, a)
                            self.db.profile.barStyle.borderColor = { r = r, g = g, b = b, a = a }
                            BetterExpBar:SynchronizeBarStyles()
                        end,
                        order = 4,
                    },
                },
            },
            expBarSettings = {
                type = "group",
                name = "Experience Bar",
                inline = false,
                order = 6,
                args = {
                    opacity = {
                        type = "range",
                        name = "Opacity",
                        desc = "Experience bar opacity",
                        min = 0.1, max = 1, step = 0.1,
                        get = function() return self.db.profile.expBar.opacity end,
                        set = function(_, value)
                            self.db.profile.expBar.opacity = value
                            if expBarFrame then expBarFrame:SetAlpha(value) end
                        end,
                        order = 1,
                    },
                    textSize = {
                        type = "range",
                        name = "Text Size",
                        desc = "Experience bar text size",
                        min = 8, max = 24, step = 1,
                        get = function() return self.db.profile.expBar.textSize end,
                        set = function(_, value)
                            self.db.profile.expBar.textSize = value
                            BetterExpBar:UpdateBarTextSize(expBarFrame, value)
                        end,
                        order = 2,
                    },
                    textFormat = {
                        type = "select",
                        name = "Text Display",
                        desc = "Choose what text to display on the experience bar",
                        values = {
                            ["percentage"] = "Percentage (%)",
                            ["none"] = "None",
                        },
                        get = function() return self.db.profile.expBar.textFormat or "percentage" end,
                        set = function(_, value)
                            self.db.profile.expBar.textFormat = value
                            BetterExpBar:UpdateExpBar()
                        end,
                        order = 3,
                    },
                },
            },
            repBarSettings = {
                type = "group",
                name = "Reputation Bar",
                inline = false,
                order = 7,
                args = {
                    opacity = {
                        type = "range",
                        name = "Opacity",
                        desc = "Reputation bar opacity",
                        min = 0.1, max = 1, step = 0.1,
                        get = function() return self.db.profile.repBar.opacity end,
                        set = function(_, value)
                            self.db.profile.repBar.opacity = value
                            if repBarInner then repBarInner:SetAlpha(value) end
                        end,
                        order = 1,
                    },
                    textSize = {
                        type = "range",
                        name = "Text Size",
                        desc = "Reputation bar text size",
                        min = 8, max = 24, step = 1,
                        get = function() return self.db.profile.repBar.textSize end,
                        set = function(_, value)
                            self.db.profile.repBar.textSize = value
                            BetterExpBar:UpdateBarTextSize(repBarFrame, value)
                        end,
                        order = 2,
                    },
                    textFormat = {
                        type = "select",
                        name = "Text Display",
                        desc = "Choose what text to display on the reputation bar",
                        values = {
                            ["full"] = "Full (Name, %, Standing)",
                            ["percentage"] = "Percentage (%)",
                            ["name"] = "Faction Name",
                            ["none"] = "None",
                        },
                        get = function() return self.db.profile.repBar.textFormat or "full" end,
                        set = function(_, value)
                            self.db.profile.repBar.textFormat = value
                            BetterExpBar:UpdateRepBar()
                        end,
                        order = 3,
                    },
                },
            },
            tooltipSettings = {
                type = "group",
                name = "Tooltips",
                inline = false,
                order = 8,
                args = {
                    enabled = {
                        type = "toggle",
                        name = "Enable Tooltips",
                        desc = "Show tooltips when hovering over bars",
                        get = function() return self.db.profile.tooltip.enabled end,
                        set = function(_, value)
                            self.db.profile.tooltip.enabled = value
                        end,
                        order = 1,
                    },
                    fontSize = {
                        type = "range",
                        name = "Font Size",
                        desc = "Tooltip text size",
                        min = 8, max = 24, step = 1,
                        get = function() return self.db.profile.tooltip.fontSize end,
                        set = function(_, value)
                            self.db.profile.tooltip.fontSize = value
                            BetterExpBar:UpdateAllTooltips()
                        end,
                        order = 2,
                    },
                    offsetY = {
                        type = "range",
                        name = "Vertical Offset",
                        desc = "Distance from bar to tooltip",
                        min = 0, max = 50, step = 1,
                        get = function() return self.db.profile.tooltip.offsetY end,
                        set = function(_, value)
                            self.db.profile.tooltip.offsetY = value
                        end,
                        order = 3,
                    },
                    backgroundColor = {
                        type = "color",
                        name = "Background Color",
                        desc = "Tooltip background color",
                        hasAlpha = true,
                        get = function()
                            local c = self.db.profile.tooltip.backgroundColor
                            return c.r, c.g, c.b, c.a
                        end,
                        set = function(_, r, g, b, a)
                            self.db.profile.tooltip.backgroundColor = { r = r, g = g, b = b, a = a }
                            BetterExpBar:UpdateAllTooltips()
                        end,
                        order = 4,
                    },
                    borderColor = {
                        type = "color",
                        name = "Border Color",
                        desc = "Tooltip border color",
                        hasAlpha = true,
                        get = function()
                            local c = self.db.profile.tooltip.borderColor
                            return c.r, c.g, c.b, c.a
                        end,
                        set = function(_, r, g, b, a)
                            self.db.profile.tooltip.borderColor = { r = r, g = g, b = b, a = a }
                            BetterExpBar:UpdateAllTooltips()
                        end,
                        order = 5,
                    },
                    expTooltipHeader = {
                        type = "header",
                        name = "Experience Bar Tooltip",
                        order = 6,
                    },
                    expShowLevel = {
                        type = "toggle",
                        name = "Show Level",
                        desc = "Display character level in tooltip",
                        get = function() return self.db.profile.tooltip.expTooltip.showLevel end,
                        set = function(_, value)
                            self.db.profile.tooltip.expTooltip.showLevel = value
                            BetterExpBar:UpdateTooltipText()
                        end,
                        order = 7,
                    },
                    expShowCurrent = {
                        type = "toggle",
                        name = "Show Current XP",
                        desc = "Display current experience points",
                        get = function() return self.db.profile.tooltip.expTooltip.showCurrent end,
                        set = function(_, value)
                            self.db.profile.tooltip.expTooltip.showCurrent = value
                            BetterExpBar:UpdateTooltipText()
                        end,
                        order = 8,
                    },
                    expShowRested = {
                        type = "toggle",
                        name = "Show Rested XP",
                        desc = "Display rested experience points",
                        get = function() return self.db.profile.tooltip.expTooltip.showRested end,
                        set = function(_, value)
                            self.db.profile.tooltip.expTooltip.showRested = value
                            BetterExpBar:UpdateTooltipText()
                        end,
                        order = 9,
                    },
                    expShowRemaining = {
                        type = "toggle",
                        name = "Show Remaining XP",
                        desc = "Display experience needed to next level",
                        get = function() return self.db.profile.tooltip.expTooltip.showRemaining end,
                        set = function(_, value)
                            self.db.profile.tooltip.expTooltip.showRemaining = value
                            BetterExpBar:UpdateTooltipText()
                        end,
                        order = 10,
                    },
                    expShowPercentage = {
                        type = "toggle",
                        name = "Show Percentage",
                        desc = "Display progress percentage",
                        get = function() return self.db.profile.tooltip.expTooltip.showPercentage end,
                        set = function(_, value)
                            self.db.profile.tooltip.expTooltip.showPercentage = value
                            BetterExpBar:UpdateTooltipText()
                        end,
                        order = 11,
                    },
                    repTooltipHeader = {
                        type = "header",
                        name = "Reputation Bar Tooltip",
                        order = 12,
                    },
                    repShowFactionName = {
                        type = "toggle",
                        name = "Show Faction Name",
                        desc = "Display faction name in tooltip",
                        get = function() return self.db.profile.tooltip.repTooltip.showFactionName end,
                        set = function(_, value)
                            self.db.profile.tooltip.repTooltip.showFactionName = value
                            BetterExpBar:UpdateRepTooltip()
                        end,
                        order = 13,
                    },
                    repShowStanding = {
                        type = "toggle",
                        name = "Show Standing",
                        desc = "Display faction standing level",
                        get = function() return self.db.profile.tooltip.repTooltip.showStanding end,
                        set = function(_, value)
                            self.db.profile.tooltip.repTooltip.showStanding = value
                            BetterExpBar:UpdateRepTooltip()
                        end,
                        order = 14,
                    },
                    repShowCurrent = {
                        type = "toggle",
                        name = "Show Current Rep",
                        desc = "Display current reputation points",
                        get = function() return self.db.profile.tooltip.repTooltip.showCurrent end,
                        set = function(_, value)
                            self.db.profile.tooltip.repTooltip.showCurrent = value
                            BetterExpBar:UpdateRepTooltip()
                        end,
                        order = 15,
                    },
                    repShowRemaining = {
                        type = "toggle",
                        name = "Show Remaining Rep",
                        desc = "Display reputation needed to next standing",
                        get = function() return self.db.profile.tooltip.repTooltip.showRemaining end,
                        set = function(_, value)
                            self.db.profile.tooltip.repTooltip.showRemaining = value
                            BetterExpBar:UpdateRepTooltip()
                        end,
                        order = 16,
                    },
                },
            },
        },
    }

    AceConfig:RegisterOptionsTable("BetterExpBar", options)
    AceConfigDialog:AddToBlizOptions("BetterExpBar", "Better Exp & Rep Bars")
end
