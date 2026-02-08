-- Initialize Ace3 addon
local BetterExpBar = LibStub("AceAddon-3.0"):NewAddon("BetterExpBar", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDB = LibStub("AceDB-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")
local LDB = LibStub("LibDataBroker-1.1", true)
local LDBIcon = LibStub("LibDBIcon-1.0", true)
local LSM = LibStub("LibSharedMedia-3.0", true)
local CandyBar = LibStub:GetLibrary("LibCandyBar-3.0", true)

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
            barsLinked = false,
            lockBarsPosition = false,
            barOrder = "exp", -- "exp" = experience on top, "rep" = reputation on top
            linkedTexture = "Interface\\TargetingFrame\\UI-StatusBar",
            linkedFontFace = "Fonts\\FRIZQT__.TTF",
            linkedTextSize = 12,
        },
        tooltip = {
            enabled = true,
            fontSize = 12,
            fontFace = "Fonts\\FRIZQT__.TTF",
            textColor = { r = 1, g = 1, b = 1, a = 1 },
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
            scale = 1.0,
            opacity = 0.8,
            questXPOpacity = 0.6,
            restedXPOpacity = 0.5,
            textSize = 12,
            textColor = { r = 1, g = 1, b = 1, a = 1 },
            fontFace = "Fonts\\FRIZQT__.TTF",
            texture = "Interface\\TargetingFrame\\UI-StatusBar",
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
            scale = 1.0,
            opacity = 0.8,
            textSize = 12,
            textColor = { r = 1, g = 1, b = 1, a = 1 },
            fontFace = "Fonts\\FRIZQT__.TTF",
            texture = "Interface\\TargetingFrame\\UI-StatusBar",
            showText = true,
            textFormat = "full", -- Options: full, percentage, name, none
        },
        colors = {
            exp = { r = 0.6, g = 0, b = 0.6, a = 1 },      -- Purple (Blizzard exp bar)
            rested = { r = 0, g = 0.4, b = 1, a = 0.6 },   -- Blue (Blizzard rested)
            questXP = { r = 0, g = 0.8, b = 0, a = 0.6 },  -- Green (quest bonus)
            bonusRep = { r = 0, g = 0.8, b = 0, a = 0.6 }, -- Green (rep bonus)
        },
        expDisplay = {
            showQuestXP = true,
            useVerbose = false,
            useCommon = true,
        },
        repDisplay = {
            showBonusRep = true,
            trackWatchedFaction = true,
        },
    },
}

-- Frame references
local expBarContainer, largerFrame, expBarFrame, restedBar, questXPBar, expText, tooltipFrame, tooltipText, resizeHandle
local repBarFrame, repBarInner, bonusRepBar, repText, repTooltipFrame, repTooltipText, repResizeHandle
local expTexturePreview, repTexturePreview

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
    self:CreateFrames()
    self:CreateTexturePreviewBars()
    
    -- XP Events
    if self.db.profile.enabled then
        self:RegisterEvent("PLAYER_XP_UPDATE", "UpdateExpBar")
        self:RegisterEvent("PLAYER_LEVEL_UP", "OnLevelUp")
        self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEnteringWorld")
        self:RegisterEvent("PLAYER_LOGOUT", "OnLogout")
        -- Force initial update to ensure tooltips are initialized on reload
        self:UpdateExpBar()
    end
    
    -- Rep Events
    if self.db.profile.repBarEnabled then
        self:RegisterEvent("UPDATE_FACTION", "UpdateRepBar")
        self:RegisterEvent("QUEST_LOG_UPDATE", "UpdateRepBar")
        self:RegisterEvent("COMBAT_TEXT_UPDATE", "UpdateRepBar")
        -- Set up a periodic check as fallback (every 2 seconds)
        self.repBarTimer = self:ScheduleRepeatingTimer("UpdateRepBar", 2)
        -- Force initial update
        self:UpdateRepBar()
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
    
    -- Unparent from largerFrame if currently parented (when unlinking)
    if frame:GetParent() ~= UIParent then
        frame:SetParent(UIParent)
    end
    
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
    
    -- Apply opacity only to experience bar frames (not reputation frame)
    if configKey ~= "repBar" then
        frame:SetAlpha(barConfig.opacity or 0.8)
    end
    
    -- Apply scale
    frame:SetScale(styleConfig.scale or 1.0)
    
    -- Apply border color and backdrop only if frame has a backdrop
    if frame.SetBackdropBorderColor and frame.SetBackdropColor then
        local bc = styleConfig.borderColor
        frame:SetBackdropBorderColor(bc.r or 1, bc.g or 1, bc.b or 1, bc.a or 1)
        frame:SetBackdropColor(0, 0, 0, styleConfig.backdropOpacity or 0.5)
    end
end

function BetterExpBar:ApplyTooltipStyle(tooltipFrame, tooltipText)
    if not tooltipFrame or not tooltipText or not self.db or not self.db.profile then return end
    
    local tooltipConfig = self.db.profile.tooltip
    local bgColor = tooltipConfig.backgroundColor
    local borderColor = tooltipConfig.borderColor
    local textColor = tooltipConfig.textColor
    local fontFace = self:GetSafeFont(tooltipConfig.fontFace or "Fonts\\FRIZQT__.TTF")
    
    -- Apply colors
    tooltipFrame:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a)
    tooltipFrame:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)
    
    -- Apply font and text color
    tooltipText:SetFont(fontFace, tooltipConfig.fontSize, "OUTLINE")
    tooltipText:SetTextColor(textColor.r, textColor.g, textColor.b, textColor.a)
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

function BetterExpBar:GetSafeFont(fontPath)
    -- Resolve LSM font paths and validate
    local font = fontPath or "Fonts\\FRIZQT__.TTF"
    if LSM and font then
        local resolved = LSM:Fetch("font", font)
        if resolved then
            font = resolved
        end
    end
    -- Fallback if still invalid
    if not font or font == "" then
        font = "Fonts\\FRIZQT__.TTF"
    end
    return font
end

function BetterExpBar:FormatNumber(num)
    -- Safety check and type conversion
    if not num then num = 0 end
    num = tonumber(num) or 0  -- Convert to number if string
    num = math.floor(num + 0.5)  -- Round to nearest integer
    
    -- Attempt to get formatting preferences
    local useCommon = false
    local useVerbose = false
    
    if self.db and self.db.profile and self.db.profile.expDisplay then
        useCommon = self.db.profile.expDisplay.useCommon or false
        useVerbose = self.db.profile.expDisplay.useVerbose or false
    end
    
    -- If both are false, default to common formatting
    if not useCommon and not useVerbose then
        useCommon = true
    end
    
    -- Common abbreviation: 40k, 1M (rounded)
    if useCommon then
        if num >= 1000000 then
            local millions = num / 1000000
            if millions >= 10 then
                return math.floor(millions) .. "M"
            else
                return string.format("%.1f", millions) .. "M"
            end
        elseif num >= 1000 then
            local thousands = num / 1000
            if thousands >= 10 then
                return math.floor(thousands) .. "k"
            else
                return string.format("%.1f", thousands) .. "k"
            end
        else
            return tostring(num)
        end
    end
    
    -- Verbose: 41.8k, 1.5M (with one decimal)
    if useVerbose then
        if num >= 1000000 then
            return string.format("%.1fM", num / 1000000)
        elseif num >= 1000 then
            return string.format("%.1fk", num / 1000)
        else
            return tostring(num)
        end
    end
    
    -- Fallback: plain number
    return tostring(num)
end

function BetterExpBar:GetQuestXPReward()
    if not self.db.profile.expDisplay.showQuestXP then
        return 0
    end
    
    local totalQuestXP = 0
    
    -- Iterate through quest log
    for questLogIndex = 1, GetNumQuestLogEntries() do
        local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID = GetQuestLogTitle(questLogIndex)
        
        if isComplete and questID and not isHeader then
            -- Quest is complete, use GetQuestLogRewardXP if available
            if GetQuestLogRewardXP then
                local questRewardXP = GetQuestLogRewardXP(questLogIndex)
                if questRewardXP and questRewardXP > 0 then
                    totalQuestXP = totalQuestXP + questRewardXP
                end
            end
        end
    end
    
    return totalQuestXP
end

function BetterExpBar:GetBonusReputation()
    if not self.db.profile.repDisplay.showBonusRep then
        return 0
    end
    
    local totalBonusRep = 0
    
    -- Get watched faction if available
    local watchedFactionName, watchedFactionStanding, watchedFactionbarMin, watchedFactionbarMax, watchedFactionbarValue
    if self.db.profile.repDisplay.trackWatchedFaction then
        if GetWatchedFactionInfo then
            watchedFactionName, watchedFactionStanding, watchedFactionbarMin, watchedFactionbarMax, watchedFactionbarValue = GetWatchedFactionInfo()
        end
    end
    
    if not watchedFactionName then
        return 0
    end
    
    -- Iterate through quest log
    for questLogIndex = 1, GetNumQuestLogEntries() do
        local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID = GetQuestLogTitle(questLogIndex)
        
        if isComplete and questID and not isHeader then
            -- Quest is complete, estimate reputation reward
            -- Standard reputation reward tiers based on quest level relative to character level
            local charLevel = UnitLevel("player") or 60
            local questLevel = level or charLevel
            
            -- Base reputation reward calculation
            local baseRep = 100  -- Default base reputation
            
            -- Adjust based on level difference
            if questLevel >= charLevel then
                baseRep = 250   -- High level quests give more rep
            elseif questLevel >= charLevel - 5 then
                baseRep = 150   -- Moderate level quests
            else
                baseRep = 100   -- Lower level quests
            end
            
            totalBonusRep = totalBonusRep + baseRep
        end
    end
    
    return totalBonusRep
end

function BetterExpBar:UpdateBarTextSize(barFrame, fontSize)
    if barFrame == expBarFrame and expText then
        local fontFace = self.db.profile.expBar.fontFace or "Fonts\\FRIZQT__.TTF"
        local textColor = self.db.profile.expBar.textColor
        fontFace = self:GetSafeFont(fontFace)
        expText:SetFont(fontFace, fontSize, "OUTLINE")
        expText:SetTextColor(textColor.r, textColor.g, textColor.b, textColor.a)
    elseif barFrame == repBarFrame and repText then
        local fontFace = self.db.profile.repBar.fontFace or "Fonts\\FRIZQT__.TTF"
        local textColor = self.db.profile.repBar.textColor
        fontFace = self:GetSafeFont(fontFace)
        repText:SetFont(fontFace, fontSize, "OUTLINE")
        repText:SetTextColor(textColor.r, textColor.g, textColor.b, textColor.a)
    end
end

function BetterExpBar:ApplyLinkedBarSettings()
    if not self.db.profile.barStyle.barsLinked then return end
    
    -- Apply unified texture to all bars
    local linkedTexture = self.db.profile.barStyle.linkedTexture or "Interface\\TargetingFrame\\UI-StatusBar"
    if expBarInner then
        expBarInner:SetStatusBarTexture(linkedTexture)
    end
    if questXPBar then
        questXPBar:SetStatusBarTexture(linkedTexture)
    end
    if restedBar then
        restedBar:SetStatusBarTexture(linkedTexture)
    end
    if repBarInner then
        repBarInner:SetStatusBarTexture(linkedTexture)
    end
    if bonusRepBar then
        bonusRepBar:SetStatusBarTexture(linkedTexture)
    end
    
    -- Apply unified font and size
    local linkedFont = self:GetSafeFont(self.db.profile.barStyle.linkedFontFace)
    local linkedSize = self.db.profile.barStyle.linkedTextSize or 12
    if expText then
        expText:SetFont(linkedFont, linkedSize, "OUTLINE")
    end
    if repText then
        repText:SetFont(linkedFont, linkedSize, "OUTLINE")
    end
    
    -- Reapply colors
    self:UpdateExpBar()
    self:UpdateRepBar()
end

function BetterExpBar:SynchronizeBarDimensions()
    if not self.db.profile.barStyle.barsLinked then return end
    
    if expBarFrame and repBarFrame then
        local expWidth, expHeight = expBarFrame:GetSize()
        -- Force repBarFrame to match expBarFrame exactly
        repBarFrame:SetSize(expWidth, expHeight)
    end
end

function BetterExpBar:UpdateBarColors()
    -- Reapply exp bar color after texture
    if expBarInner then
        local expColor = self.db.profile.colors.exp
        expBarInner:SetStatusBarColor(expColor.r, expColor.g, expColor.b)
    end
    if restedBar then
        local restedColor = self.db.profile.colors.rested
        restedBar:SetStatusBarColor(restedColor.r, restedColor.g, restedColor.b, restedColor.a)
    end
    -- Reapply rep bar color (uses faction color)
    if repBarInner then
        self:UpdateRepBar()
    end
end

function BetterExpBar:UpdateLinkedBars()
    if not self.db.profile.barStyle.barsLinked then return end
    if not expBarFrame or not repBarFrame or not largerFrame then return end
    
    local barOrder = self.db.profile.barStyle.barOrder or "exp"
    local expHeight = expBarFrame:GetHeight()
    
    -- Sync dimensions
    local expWidth = expBarFrame:GetWidth()
    repBarFrame:SetSize(expWidth, expHeight)
    
    -- Always center expBarFrame inside largerFrame
    expBarFrame:ClearAllPoints()
    expBarFrame:SetPoint("CENTER", largerFrame, "CENTER", 0, 0)
    
    -- Parent repBarFrame to largerFrame for synchronized movement
    repBarFrame:SetParent(largerFrame)
    repBarFrame:ClearAllPoints()
    
    if barOrder == "exp" then
        -- Experience bar on top, reputation bar below (offset from largerFrame)
        repBarFrame:SetPoint("TOP", largerFrame, "BOTTOM", 0, -2)
    else
        -- Reputation bar on top, experience bar below (offset from largerFrame)
        repBarFrame:SetPoint("BOTTOM", largerFrame, "TOP", 0, 2)
    end
end

function BetterExpBar:LinkBarPositions(barFrame)
    if not self.db.profile.barStyle.barsLinked then return end
    if not expBarFrame or not repBarFrame then return end
    
    -- Always align from exp bar position
    self:UpdateLinkedBars()
end

function BetterExpBar:ApplyBarLocking()
    if not self.db.profile.barStyle.lockBarsPosition then return end
    
    if expBarFrame then
        expBarFrame:RegisterForDrag()
    end
    if repBarFrame then
        repBarFrame:RegisterForDrag()
    end
end

function BetterExpBar:ReleaseBarLocking()
    if self.db.profile.barStyle.lockBarsPosition then return end
    
    if expBarFrame then
        expBarFrame:RegisterForDrag("LeftButton")
    end
    if repBarFrame then
        repBarFrame:RegisterForDrag("LeftButton")
    end
end

function BetterExpBar:CreateFrames()
    if self.db.profile.enabled then
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

        -- Create experience bar (container without border - largerFrame provides the border)
        expBarFrame = CreateFrame("Frame", "CustomExpBar", largerFrame)
        expBarFrame:SetSize(self.db.profile.expBar.width, self.db.profile.expBar.height)
        expBarFrame:SetPoint("CENTER", largerFrame, "CENTER", 0, 0)
        expBarFrame:EnableMouse(true)
        expBarFrame:SetMovable(true)
        expBarFrame:RegisterForDrag("LeftButton")
        expBarFrame:SetScript("OnDragStart", function(self)
            BetterExpBar._isDragging = true
            if BetterExpBar.db.profile.barStyle.barsLinked then
                largerFrame:StartMoving()
            else
                largerFrame:StartMoving()
            end
        end)
        expBarFrame:SetScript("OnDragStop", function(self)
            largerFrame:StopMovingOrSizing()
            BetterExpBar._isDragging = false
            BetterExpBar:SaveFramePosition(largerFrame, "largerFrame")
            -- repBarFrame is automatically positioned via parenting when linked
        end)
        expBarFrame:SetFrameLevel(2)
        expBarFrame:Show()

        -- Create inner experience status bar
        expBarInner = CreateFrame("StatusBar", nil, expBarFrame)
        expBarInner:SetStatusBarTexture(self.db.profile.expBar.texture or "Interface\\TargetingFrame\\UI-StatusBar")
        local expColor = self.db.profile.colors.exp
        expBarInner:SetStatusBarColor(expColor.r, expColor.g, expColor.b)
        expBarInner:SetAlpha(self.db.profile.expBar.opacity)
        expBarInner:SetFrameLevel(expBarFrame:GetFrameLevel() + 1)
        -- Fill entire frame with inner bar
        expBarInner:SetAllPoints(expBarFrame)
        expBarInner:SetMinMaxValues(0, 1)
        expBarInner:SetValue(0)
        expBarInner:Show()

        -- Create quest XP bar (beneath current bar so current remains visible)
        questXPBar = CreateFrame("StatusBar", nil, expBarInner)
        questXPBar:SetAllPoints(expBarInner)
        questXPBar:SetStatusBarTexture(self.db.profile.expBar.texture or "Interface\\TargetingFrame\\UI-StatusBar")
        local questColor = self.db.profile.colors.questXP
        questXPBar:SetStatusBarColor(questColor.r, questColor.g, questColor.b, questColor.a)
        questXPBar:SetAlpha(self.db.profile.expBar.questXPOpacity or 0.6)
        questXPBar:SetFrameLevel(expBarInner:GetFrameLevel() - 2)
        questXPBar:SetMinMaxValues(0, 1)
        questXPBar:SetValue(0)
        questXPBar:Show()

        -- Create rested bar (beneath quest/current to show full progression behind purple)
        restedBar = CreateFrame("StatusBar", nil, expBarInner)
        restedBar:SetAllPoints(expBarInner)
        restedBar:SetStatusBarTexture(self.db.profile.expBar.texture or "Interface\\TargetingFrame\\UI-StatusBar")
        local restedColor = self.db.profile.colors.rested
        restedBar:SetStatusBarColor(restedColor.r, restedColor.g, restedColor.b, restedColor.a)
        restedBar:SetAlpha(self.db.profile.expBar.restedXPOpacity or 0.5)
        restedBar:SetFrameLevel(expBarInner:GetFrameLevel() - 3)
        restedBar:Show()

        -- Create experience text
        expText = expBarInner:CreateFontString(nil, "OVERLAY")
        local expFontFace = self.db.profile.expBar.fontFace or "Fonts\\FRIZQT__.TTF"
        local expTextColor = self.db.profile.expBar.textColor
        expFontFace = self:GetSafeFont(expFontFace)
        expText:SetFont(expFontFace, self.db.profile.expBar.textSize, "OUTLINE")
        expText:SetTextColor(expTextColor.r, expTextColor.g, expTextColor.b, expTextColor.a)
        expText:SetPoint("CENTER", expBarInner, "CENTER", 0, 0)

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
        local tooltipFont = self:GetSafeFont(self.db.profile.tooltip.fontFace or "Fonts\\FRIZQT__.TTF")
        tooltipText:SetFont(tooltipFont, self.db.profile.tooltip.fontSize, "OUTLINE")
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
            -- Skip updates during drag
            if BetterExpBar._isDragging then return end
            
            local newWidth = math.max(self:GetWidth() - 10, 10)
            local newHeight = math.max(self:GetHeight() - 10, 5)
            expBarContainer:SetSize(newWidth, newHeight)
            expBarFrame:SetSize(newWidth, newHeight)
            -- If bars are linked, update their positioning after size change
            if BetterExpBar.db.profile.barStyle.barsLinked then
                BetterExpBar:SynchronizeBarDimensions()
                BetterExpBar:UpdateLinkedBars()
            end
            BetterExpBar:UpdateExpBar()
        end)

        -- Restore saved positions
        self:RestoreFramePosition(largerFrame, "largerFrame")
        self:RestoreFramePosition(expBarContainer, "expBar")
        
        -- Apply initial styles
        self:ApplyBarStyle(largerFrame, "largerFrame")
        self:SynchronizeBarStyles()
    end
    
    -- Hide default bars
    self:HideDefaultExpBar()
    
    -- Create reputation bar if enabled
    if self.db.profile.repBarEnabled then
        self:CreateRepBar()
    end
    
    -- Initialize linked bars if setting is saved
    if self.db.profile.barStyle.barsLinked then
        self:SynchronizeBarDimensions()
        self:UpdateLinkedBars()
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
    repBarFrame:SetScript("OnDragStart", function(self)
        BetterExpBar._isDragging = true
        if BetterExpBar.db.profile.barStyle.barsLinked then
            -- When linked, move largerFrame instead of repBarFrame so they move together
            largerFrame:StartMoving()
        else
            self:StartMoving()
        end
    end)
    repBarFrame:SetScript("OnDragStop", function(self)
        BetterExpBar._isDragging = false
        if BetterExpBar.db.profile.barStyle.barsLinked then
            largerFrame:StopMovingOrSizing()
            -- repBarFrame moves with largerFrame since it's now parented
            BetterExpBar:SaveFramePosition(largerFrame, "largerFrame")
        else
            self:StopMovingOrSizing()
            BetterExpBar:SaveFramePosition(self, "repBar")
        end
    end)
    repBarFrame:Show()

    -- Create inner status bar (with inset to avoid overlapping frame border)
    repBarInner = CreateFrame("StatusBar", nil, repBarFrame)
    repBarInner:SetStatusBarTexture(self.db.profile.repBar.texture or "Interface\\TargetingFrame\\UI-StatusBar")
    -- Set initial faction color (Neutral)
    local initialColor = self:GetFactionColor(4)
    repBarInner:SetStatusBarColor(initialColor.r, initialColor.g, initialColor.b, 1)
    repBarInner:SetAlpha(self.db.profile.repBar.opacity)
    repBarInner:SetFrameLevel(repBarFrame:GetFrameLevel())  -- Text on OVERLAY appears on top
    -- Apply inset to prevent border overlap (5px to clear 16px edge border)
    repBarInner:SetPoint("TOPLEFT", repBarFrame, "TOPLEFT", 5, -5)
    repBarInner:SetPoint("BOTTOMRIGHT", repBarFrame, "BOTTOMRIGHT", -5, 5)
    repBarInner:SetMinMaxValues(0, 1)
    repBarInner:SetValue(0)
    repBarInner:Show()

    -- Create bonus reputation bar (shown behind main rep bar to preview total with bonus)
    bonusRepBar = CreateFrame("StatusBar", nil, repBarInner)
    bonusRepBar:SetAllPoints(repBarInner)
    bonusRepBar:SetStatusBarTexture(self.db.profile.repBar.texture or "Interface\\TargetingFrame\\UI-StatusBar")
    local bonusRepColor = self.db.profile.colors.bonusRep or { r = 0, g = 0.8, b = 0, a = 0.6 }
    bonusRepBar:SetStatusBarColor(bonusRepColor.r, bonusRepColor.g, bonusRepColor.b, bonusRepColor.a)
    bonusRepBar:SetFrameLevel(repBarInner:GetFrameLevel() - 1)  -- Behind rep bar
    bonusRepBar:SetMinMaxValues(0, 1)
    bonusRepBar:SetValue(0)
    bonusRepBar:Show()

    -- Create reputation text on repBarFrame (not repBarInner) so opacity changes don't affect text
    -- and text appears on top of the status bar
    repText = repBarFrame:CreateFontString(nil, "OVERLAY")
    local repFontFace = self.db.profile.repBar.fontFace or "Fonts\\FRIZQT__.TTF"
    local repTextColor = self.db.profile.repBar.textColor
    repFontFace = self:GetSafeFont(repFontFace)
    repText:SetFont(repFontFace, self.db.profile.repBar.textSize, "OUTLINE")
    repText:SetTextColor(repTextColor.r, repTextColor.g, repTextColor.b, repTextColor.a)
    -- Position text centered in the bar, relative to the inner bar area (accounting for frame inset)
    repText:SetPoint("CENTER", repBarInner, "CENTER", 0, 0)
    repText:SetJustifyH("CENTER")

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
    local repTooltipFont = self:GetSafeFont(self.db.profile.tooltip.fontFace or "Fonts\\FRIZQT__.TTF")
    repTooltipText:SetFont(repTooltipFont, self.db.profile.tooltip.fontSize, "OUTLINE")
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
            -- Don't allow resizing repBarFrame independently when linked
            if BetterExpBar.db.profile.barStyle.barsLinked then
                return
            end
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
        -- Force sync if linked after resize completes
        if BetterExpBar.db.profile.barStyle.barsLinked then
            BetterExpBar:SynchronizeBarDimensions()
            BetterExpBar:UpdateLinkedBars()
        end
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
        -- Skip updates during drag
        if BetterExpBar._isDragging then return end
        
        local newWidth = math.max(frame:GetWidth(), 40)
        local newHeight = math.max(frame:GetHeight(), 10)
        if BetterExpBar.db.profile.barStyle.barsLinked then
            BetterExpBar:SynchronizeBarDimensions()
            BetterExpBar:UpdateLinkedBars()
        end
        BetterExpBar:UpdateRepBar()
    end)

    -- Restore saved position
    self:RestoreFramePosition(repBarFrame, "repBar")
    
    -- Apply styles
    self:ApplyBarStyle(repBarFrame, "repBar")
    
    -- Initial update
    self:UpdateRepBar()
end

function BetterExpBar:UpdateTooltipText()
    local currentXP = UnitXP and UnitXP("player") or 0
    local maxXP = UnitXPMax and UnitXPMax("player") or 1
    local restedXP = GetXPExhaustion and (GetXPExhaustion() or 0) or 0
    local questXP = 0
    if self.db.profile.expDisplay.showQuestXP then
        questXP = self:GetQuestXPReward()
    end
    local remainingXP = maxXP - currentXP
    local playerLevel = UnitLevel("player") or 0

    -- Calculate rested percent of level
    local restedPercent = 0
    if maxXP > 0 then
        restedPercent = math.floor((restedXP / maxXP) * 100 + 0.5)
    end
    
    -- Calculate quest XP percent
    local questPercent = 0
    if maxXP > 0 then
        questPercent = math.floor((questXP / maxXP) * 100 + 0.5)
    end

    local tooltipConfig = self.db.profile.tooltip.expTooltip
    local tooltipLines = {}

    -- Build tooltip based on settings
    if tooltipConfig.showLevel then
        table.insert(tooltipLines, string.format("Level: |cff00ff00%d|r", playerLevel))
    end
    
    if tooltipConfig.showCurrent then
        table.insert(tooltipLines, string.format("Current: |cffffff00%s|r / |cffffff00%s|r (%d%%)", 
            self:FormatNumber(currentXP),
            self:FormatNumber(maxXP),
            (maxXP > 0) and math.floor((currentXP / maxXP) * 100) or 0))
    end
    
    -- Add quest XP info if enabled (always show, even if 0)
    if self.db.profile.expDisplay.showQuestXP then
        table.insert(tooltipLines, string.format("Quest Bonus: |cff00ff00+%s|r |cff00ff00(%d%%)|r", 
            self:FormatNumber(questXP),
            math.floor(questPercent)))
    end
    
    if tooltipConfig.showRested then
        table.insert(tooltipLines, string.format("Resting Bonus: |cff3399ff+%s|r |cff3399ff(%d%%)|r", 
            self:FormatNumber(restedXP),
            math.floor(restedPercent)))
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

function BetterExpBar:UpdateTexturePreview(previewBar, previewType)
    if not previewBar then return end
    
    if previewType == "exp" then
        previewBar:SetStatusBarTexture(BetterExpBar.db.profile.expBar.texture or "Interface\\TargetingFrame\\UI-StatusBar")
        local expColor = BetterExpBar.db.profile.colors.exp
        previewBar:SetStatusBarColor(expColor.r, expColor.g, expColor.b, expColor.a)
    elseif previewType == "rep" then
        previewBar:SetStatusBarTexture(BetterExpBar.db.profile.repBar.texture or "Interface\\TargetingFrame\\UI-StatusBar")
        previewBar:SetStatusBarColor(0, 0.39, 0.88, 1)
    end
    previewBar:SetValue(0.6) -- Show at 60% for visual preview
end

function BetterExpBar:CreateTexturePreviewBars()
    -- Create experience bar texture preview
    if not expTexturePreview then
        expTexturePreview = CreateFrame("StatusBar", nil, UIParent)
        expTexturePreview:SetSize(200, 18)
        expTexturePreview:SetMinMaxValues(0, 1)
        expTexturePreview:SetValue(0.6)
        expTexturePreview:Hide()
    end
    
    -- Create reputation bar texture preview  
    if not repTexturePreview then
        repTexturePreview = CreateFrame("StatusBar", nil, UIParent)
        repTexturePreview:SetSize(200, 18)
        repTexturePreview:SetMinMaxValues(0, 1)
        repTexturePreview:SetValue(0.6)
        repTexturePreview:Hide()
    end
    
    -- Initial updates
    self:UpdateTexturePreview(expTexturePreview, "exp")
    self:UpdateTexturePreview(repTexturePreview, "rep")
end

function BetterExpBar:UpdateExpBar()
    if not expBarInner or not expText then return end
    
    local currentXP = UnitXP("player")
    local maxXP = UnitXPMax("player")
    local restedXP = GetXPExhaustion() or 0
    local questXP = 0
    
    -- Calculate quest XP if enabled
    if self.db.profile.expDisplay.showQuestXP then
        questXP = self:GetQuestXPReward()
    end

    expBarInner:SetMinMaxValues(0, maxXP)
    expBarInner:SetValue(currentXP)
    
    -- Update quest XP bar - show from current to current+quest
    if questXPBar then
        questXPBar:SetMinMaxValues(0, maxXP)
        if self.db.profile.expDisplay.showQuestXP and questXP > 0 then
            questXPBar:SetValue(math.min(currentXP + questXP, maxXP))
            questXPBar:Show()
        else
            questXPBar:Hide()
        end
    end
    
    -- Update rested bar - show total with resting bonus
    restedBar:SetMinMaxValues(0, maxXP)
    restedBar:SetValue(math.min(currentXP + questXP + restedXP, maxXP))
    
    -- Always reapply colors and opacity to fix texture changes
    local expColor = self.db.profile.colors.exp
    expBarInner:SetStatusBarColor(expColor.r, expColor.g, expColor.b)
    expBarInner:SetAlpha(self.db.profile.expBar.opacity)
    
    if questXPBar then
        local questColor = self.db.profile.colors.questXP
        questXPBar:SetStatusBarColor(questColor.r, questColor.g, questColor.b, questColor.a)
        questXPBar:SetAlpha(self.db.profile.expBar.questXPOpacity or 0.6)
    end
    
    local restedColor = self.db.profile.colors.rested
    restedBar:SetStatusBarColor(restedColor.r, restedColor.g, restedColor.b, restedColor.a)
    restedBar:SetAlpha(self.db.profile.expBar.restedXPOpacity or 0.5)
    
    -- Get font from either linked or individual settings
    local fontFace, fontSize
    if self.db.profile.barStyle.barsLinked then
        fontFace = self:GetSafeFont(self.db.profile.barStyle.linkedFontFace)
        fontSize = self.db.profile.barStyle.linkedTextSize or 12
    else
        fontFace = self:GetSafeFont(self.db.profile.expBar.fontFace)
        fontSize = self.db.profile.expBar.textSize or 12
    end
    expText:SetFont(fontFace, fontSize, "OUTLINE")
    
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

    -- Update tooltip when it exists
    if tooltipFrame then
        self:UpdateTooltipText()
    end
end

function BetterExpBar:UpdateRepBar()
    if not repBarInner or not repText then return end
    
    -- Get font from either linked or individual settings
    local fontFace, fontSize
    if self.db.profile.barStyle.barsLinked then
        fontFace = self:GetSafeFont(self.db.profile.barStyle.linkedFontFace)
        fontSize = self.db.profile.barStyle.linkedTextSize or 12
    else
        fontFace = self:GetSafeFont(self.db.profile.repBar.fontFace)
        fontSize = self.db.profile.repBar.textSize or 12
    end
    repText:SetFont(fontFace, fontSize, "OUTLINE")
    
    local name, standing, minRep, maxRep, currentRep, factionID
    
    -- Try GetWatchedFactionInfo first (Retail/Modern WoW)
    if GetWatchedFactionInfo then
        name, standing, minRep, maxRep, currentRep, factionID = GetWatchedFactionInfo()
    end
    
    -- If that didn't work, manually search for the watched faction (Classic/Anniversary)
    if not name and GetNumFactions then
        local numFactions = GetNumFactions()
        for i = 1, numFactions do
            local factionName, description, standingId, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild, factionId, hasBonusRepGain, canBeLFGBonus = GetFactionInfo(i)
            
            -- Check if this faction is being watched
            if factionName and isWatched then
                name = factionName
                standing = standingId
                minRep = barMin
                maxRep = barMax
                currentRep = barValue
                factionID = i
                break
            end
        end
    end
    
    -- Ensure we have valid data before proceeding
    if not name or not currentRep or not minRep or not maxRep then
        repText:SetText("No Faction Tracked")
        repBarInner:SetStatusBarColor(0, 0, 0, 0)
        repBarInner:SetMinMaxValues(0, 1)
        repBarInner:SetValue(0)
        if bonusRepBar then
            bonusRepBar:SetValue(0)
        end
        return
    end
    
    local maxValue = maxRep - minRep
    local currentValue = currentRep - minRep
    if maxValue <= 0 then maxValue = 1 end
    
    -- Calculate bonus reputation
    local bonusRepValue = 0
    if self.db.profile.repDisplay.showBonusRep then
        bonusRepValue = self:GetBonusReputation()
    end
    
    repBarInner:SetMinMaxValues(0, maxValue)
    repBarInner:SetValue(currentValue)
    
    -- Update bonus rep bar to show only the bonus portion on top
    if bonusRepBar then
        bonusRepBar:SetMinMaxValues(0, maxValue)
        bonusRepBar:SetValue(math.min(currentValue + bonusRepValue, maxValue))
        local bonusRepColor = self.db.profile.colors.bonusRep
        bonusRepBar:SetStatusBarColor(bonusRepColor.r, bonusRepColor.g, bonusRepColor.b, bonusRepColor.a)
    end
    
    -- Set color based on standing
    local factionColor = self:GetFactionColor(standing)
    repBarInner:SetStatusBarColor(factionColor.r, factionColor.g, factionColor.b, 1)
    
    -- Update text based on user preference
    local percent = (maxValue > 0) and (currentValue / maxValue) * 100 or 0
    local standingText = self:GetStandingText(standing)
    
    local color = "|cffffffff"
    local factionColorData = self:GetFactionColor(standing)
    color = string.format("|cFF%02X%02X%02X", factionColorData.r*255, factionColorData.g*255, factionColorData.b*255)
    
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

function BetterExpBar:GetFactionColor(standingID)
    -- WoW faction color scheme for all standing levels (1-indexed to match WoW API)
    -- Reduced brightness to make colors less saturated
    local factionColors = {
        [1] = { r = 0.75, g = 0.0, b = 0.0, a = 1 },     -- Hated: Dark Red
        [2] = { r = 0.75, g = 0.3, b = 0.0, a = 1 },     -- Hostile: Dark Red-Orange
        [3] = { r = 0.75, g = 0.45, b = 0.0, a = 1 },    -- Unfriendly: Dark Orange
        [4] = { r = 0.75, g = 0.75, b = 0.0, a = 1 },    -- Neutral: Muted Yellow
        [5] = { r = 0.0, g = 0.75, b = 0.0, a = 1 },     -- Friendly: Dark Green
        [6] = { r = 0.0, g = 0.6, b = 0.0, a = 1 },      -- Honored: Darker Green
        [7] = { r = 0.0, g = 0.3, b = 0.75, a = 1 },     -- Revered: Dark Blue
        [8] = { r = 0.75, g = 0.0, b = 0.75, a = 1 },    -- Exalted: Dark Purple
    }
    return factionColors[standingID] or factionColors[4]  -- Default to Neutral if unknown
end

function BetterExpBar:UpdateRepTooltip()
    if not repTooltipText then return end
    
    local name, standing, minRep, maxRep, currentRep, factionID
    
    -- Try GetWatchedFactionInfo first (Retail/Modern WoW)
    if GetWatchedFactionInfo then
        name, standing, minRep, maxRep, currentRep, factionID = GetWatchedFactionInfo()
    end
    
    -- If that didn't work, manually search for the watched faction (Classic/Anniversary)
    if not name and GetNumFactions then
        local numFactions = GetNumFactions()
        for i = 1, numFactions do
            local factionName, description, standingId, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild, factionId, hasBonusRepGain, canBeLFGBonus = GetFactionInfo(i)
            
            -- Check if this faction is being watched
            if factionName and isWatched then
                name = factionName
                standing = standingId
                minRep = barMin
                maxRep = barMax
                currentRep = barValue
                factionID = i
                break
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
        local standingColorData = self:GetFactionColor(standing)
        local standingColor = string.format("|cFF%02X%02X%02X", 
            standingColorData.r * 255, 
            standingColorData.g * 255, 
            standingColorData.b * 255)
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
            table.insert(tooltipLines, string.format("%sCurrent: %s%s|r%s / %s|r", 
                whiteColor, currentValueColor, self:FormatNumber(currentValue), whiteColor, self:FormatNumber(maxValue)))
        end
        
        if tooltipConfig.showRemaining then
            table.insert(tooltipLines, string.format("%sRemaining: %s%s|r", 
                whiteColor, remainingValueColor, self:FormatNumber(remainingValue)))
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
    if self.db and self.db.profile and self.db.profile.repBarEnabled then
        if ReputationWatchBar then
            ReputationWatchBar:Hide()
            ReputationWatchBar:UnregisterAllEvents()
        end
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

function BetterExpBar:ResetAll()
    if not largerFrame or not expBarContainer then
        self:Print("Frames not initialized yet.")
        return
    end
    
    -- Reset bar style settings
    self.db.profile.barStyle = {
        backdropOpacity = 0.5,
        borderColor = { r = 1, g = 1, b = 1, a = 1 },
        scale = 1.0,
        synchronizeStyle = false,
        gloss = true,
        showBorder = true,
        barsLinked = false,
        lockBarsPosition = false,
        barOrder = "exp",
        linkedTexture = "Interface\\TargetingFrame\\UI-StatusBar",
        linkedFontFace = "Fonts\\FRIZQT__.TTF",
        linkedTextSize = 12,
    }
    
    -- Reset experience bar settings
    self.db.profile.expBar = {
        point = "TOP",
        relativePoint = "TOP",
        xOfs = 0,
        yOfs = -50,
        width = 1024,
        height = 20,
        opacity = 0.8,
        textSize = 12,
        textColor = { r = 1, g = 1, b = 1, a = 1 },
        fontFace = "Fonts\\FRIZQT__.TTF",
        texture = "Interface\\TargetingFrame\\UI-StatusBar",
        showText = true,
        textFormat = "percentage",
    }
    
    -- Reset reputation bar settings
    self.db.profile.repBar = {
        point = "TOP",
        relativePoint = "TOP",
        xOfs = 0,
        yOfs = -80,
        width = 1024,
        height = 20,
        opacity = 0.8,
        textSize = 12,
        textColor = { r = 1, g = 1, b = 1, a = 1 },
        fontFace = "Fonts\\FRIZQT__.TTF",
        texture = "Interface\\TargetingFrame\\UI-StatusBar",
        showText = true,
        textFormat = "full",
    }
    
    -- Reset colors
    self.db.profile.colors = {
        exp = { r = 0.6, g = 0, b = 0.6, a = 1 },     -- Purple (Blizzard exp bar)
        rested = { r = 0, g = 0.4, b = 1, a = 0.6 },  -- Blue (Blizzard rested)
        questXP = { r = 0, g = 0.8, b = 0, a = 0.6 }, -- Green (quest bonus)
        bonusRep = { r = 0, g = 0.8, b = 0, a = 0.6 }, -- Green (rep bonus)
    }
    
    -- Reset display settings
    self.db.profile.expDisplay = {
        showQuestXP = true,
        useVerbose = false,
        useCommon = true,
    }
    
    self.db.profile.repDisplay = {
        showBonusRep = true,
        trackWatchedFaction = true,
    }
    
    -- Apply the reset settings to frames
    largerFrame:SetScale(1.0)
    largerFrame:SetAlpha(1.0)
    largerFrame:SetBackdropColor(0, 0, 0, 0.5)
    largerFrame:SetBackdropBorderColor(1, 1, 1, 1)
    
    if repBarFrame then
        repBarFrame:SetScale(1.0)
        repBarFrame:SetAlpha(1.0)
        repBarFrame:SetBackdropColor(0, 0, 0, 0.5)
        repBarFrame:SetBackdropBorderColor(1, 1, 1, 1)
    end
    
    -- Reapply textures and colors to all bars
    if expBarInner then
        expBarInner:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        local expColor = self.db.profile.colors.exp
        expBarInner:SetStatusBarColor(expColor.r, expColor.g, expColor.b)
        expBarInner:SetAlpha(self.db.profile.expBar.opacity)
    end
    
    if questXPBar then
        questXPBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        local questColor = self.db.profile.colors.questXP
        questXPBar:SetStatusBarColor(questColor.r, questColor.g, questColor.b, questColor.a)
    end
    
    if restedBar then
        restedBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        local restedColor = self.db.profile.colors.rested
        restedBar:SetStatusBarColor(restedColor.r, restedColor.g, restedColor.b, restedColor.a)
    end
    
    if repBarInner then
        repBarInner:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        -- Use faction colors instead of exp color
        local neuralColor = self:GetFactionColor(4)  -- Neutral yellow as default
        repBarInner:SetStatusBarColor(neuralColor.r, neuralColor.g, neuralColor.b)
        repBarInner:SetAlpha(self.db.profile.repBar.opacity)
    end
    
    if bonusRepBar then
        bonusRepBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        local bonusRepColor = self.db.profile.colors.bonusRep
        bonusRepBar:SetStatusBarColor(bonusRepColor.r, bonusRepColor.g, bonusRepColor.b, bonusRepColor.a)
    end
    
    if expBarFrame then
        expBarFrame:SetAlpha(self.db.profile.expBar.opacity)
    end
    
    if expText then
        expText:SetTextColor(1, 1, 1, 1)
    end
    
    if repText then
        repText:SetTextColor(1, 1, 1, 1)
    end
    
    self:SynchronizeBarStyles()
    self:UpdateExpBar()
    self:UpdateRepBar()
    
    self:Print("|cFF00FF00Bar appearance has been reset to default settings.|r")
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
            self:RegisterEvent("QUEST_LOG_UPDATE", "UpdateRepBar")
            self:RegisterEvent("COMBAT_TEXT_UPDATE", "UpdateRepBar")
            if not self.repBarTimer then
                self.repBarTimer = self:ScheduleRepeatingTimer("UpdateRepBar", 2)
            end
            self:UpdateRepBar()
            self:Print("Reputation bar enabled")
        else
            if repBarFrame then
                repBarFrame:Hide()
            end
            self:UnregisterEvent("UPDATE_FACTION")
            self:UnregisterEvent("QUEST_LOG_UPDATE")
            self:UnregisterEvent("COMBAT_TEXT_UPDATE")
            if self.repBarTimer then
                self:CancelTimer(self.repBarTimer)
                self.repBarTimer = nil
            end
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
        desc = "v2.9.7 | By Pegga",
        type = "group",
        childGroups = "tab",
        args = {
            general = {
                name = "General",
                type = "group",
                order = 1,
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
                    lockBarsPosition = {
                        type = "toggle",
                        name = "Lock Bars Position",
                        desc = "Prevent bars from being moved or resized",
                        get = function() return self.db.profile.barStyle.lockBarsPosition end,
                        set = function(_, value)
                            self.db.profile.barStyle.lockBarsPosition = value
                            if value then
                                BetterExpBar:ApplyBarLocking()
                            else
                                BetterExpBar:ReleaseBarLocking()
                            end
                        end,
                        order = 3.5,
                    },
                    minimapHeader = {
                        type = "header",
                        name = "Minimap Button",
                        order = 4,
                    },
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
                        order = 5,
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
                        order = 6,
                    },
                    displayHeader = {
                        type = "header",
                        name = "Display",
                        order = 6.5,
                    },
                    colorHeader = {
                        type = "header",
                        name = "Bar Colors",
                        order = 7,
                    },
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
                            if expBarInner then
                                expBarInner:SetStatusBarColor(r, g, b)
                            end
                            if expBarFrame then
                                expBarFrame:SetAlpha(a)
                            end
                        end,
                        order = 8,
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
                        order = 9,
                    },
                    questXPColor = {
                        type = "color",
                        name = "Quest XP Color",
                        desc = "Color of the predicted quest XP bar",
                        hasAlpha = true,
                        get = function()
                            local c = self.db.profile.colors.questXP
                            return c.r, c.g, c.b, c.a
                        end,
                        set = function(_, r, g, b, a)
                            self.db.profile.colors.questXP = { r = r, g = g, b = b, a = a }
                            if questXPBar then
                                questXPBar:SetStatusBarColor(r, g, b, a)
                            end
                        end,
                        order = 10,
                    },
                    repHeader = {
                        type = "header",
                        name = "Reputation",
                        order = 12,
                    },
                    bonusRepColor = {
                        type = "color",
                        name = "Bonus Rep Color",
                        desc = "Color of the predicted bonus reputation bar",
                        hasAlpha = true,
                        get = function()
                            local c = self.db.profile.colors.bonusRep
                            return c.r, c.g, c.b, c.a
                        end,
                        set = function(_, r, g, b, a)
                            self.db.profile.colors.bonusRep = { r = r, g = g, b = b, a = a }
                            if bonusRepBar then
                                bonusRepBar:SetStatusBarColor(r, g, b, a)
                            end
                        end,
                        order = 15,
                    },
                    appearanceHeader = {
                        type = "header",
                        name = "Appearance (Both Bars)",
                        order = 16,
                    },
                    barFont = {
                        type = "select",
                        name = "Bar Font",
                        desc = "To be implemented in the close future. |cFF00FF00I WAS NOT PREPARED|r",
                        values = function()
                            if LSM then
                                return LSM:List("font")
                            else
                                return { ["Fonts\\FRIZQT__.TTF"] = "FRIZQT__" }
                            end
                        end,
                        get = function() return BetterExpBar.db.profile.barStyle.linkedFontFace or "Fonts\\FRIZQT__.TTF" end,
                        set = function(_, value)
                            BetterExpBar.db.profile.barStyle.linkedFontFace = value
                            BetterExpBar.db.profile.expBar.fontFace = value
                            BetterExpBar.db.profile.repBar.fontFace = value
                            
                            -- Update fonts directly
                            if expText then
                                local fontFace = BetterExpBar:GetSafeFont(value)
                                expText:SetFont(fontFace, BetterExpBar.db.profile.expBar.textSize or 12, "OUTLINE")
                            end
                            if repText then
                                local fontFace = BetterExpBar:GetSafeFont(value)
                                repText:SetFont(fontFace, BetterExpBar.db.profile.repBar.textSize or 12, "OUTLINE")
                            end
                            
                            -- Update tooltips
                            if tooltipFrame and tooltipText then
                                BetterExpBar:ApplyTooltipStyle(tooltipFrame, tooltipText)
                            end
                            if repTooltipFrame and repTooltipText then
                                BetterExpBar:ApplyTooltipStyle(repTooltipFrame, repTooltipText)
                            end
                        end,
                        order = 17,
                        disabled = true,
                    },
                    texturePreview = {
                        type = "description",
                        name = function()
                            local texture = BetterExpBar.db.profile.barStyle.linkedTexture
                            if type(texture) ~= "string" then texture = "Interface\\TargetingFrame\\UI-StatusBar" end
                            local textureName = texture:match("([^\\]+)$") or texture
                            return "Texture Preview: |cFF00FF00" .. textureName .. "|r"
                        end,
                        order = 17.5,
                    },
                    barTexture = {
                        type = "select",
                        name = "Bar Texture",
                        desc = "To be implemented in the close future. |cFF00FF00I WAS NOT PREPARED|r",
                        values = function()
                            if LSM then
                                return LSM:List("statusbar")
                            else
                                return { ["Interface\\TargetingFrame\\UI-StatusBar"] = "UI-StatusBar" }
                            end
                        end,
                        get = function() return BetterExpBar.db.profile.barStyle.linkedTexture or "Interface\\TargetingFrame\\UI-StatusBar" end,
                        set = function(_, value)
                            BetterExpBar.db.profile.barStyle.linkedTexture = value
                            BetterExpBar.db.profile.expBar.texture = value
                            BetterExpBar.db.profile.repBar.texture = value
                            
                            -- Apply texture to all bars
                            if expBarInner then
                                expBarInner:SetStatusBarTexture(value)
                            end
                            if questXPBar then
                                questXPBar:SetStatusBarTexture(value)
                            end
                            if restedBar then
                                restedBar:SetStatusBarTexture(value)
                            end
                            if repBarInner then
                                repBarInner:SetStatusBarTexture(value)
                            end
                            if bonusRepBar then
                                bonusRepBar:SetStatusBarTexture(value)
                            end
                            
                            -- Refresh both bars to reapply colors and styling
                            BetterExpBar:UpdateExpBar()
                            BetterExpBar:UpdateRepBar()
                        end,
                        order = 18,
                        disabled = true,
                    },
                    fontPreview = {
                        type = "description",
                        name = function()
                            local font = BetterExpBar.db.profile.barStyle.linkedFontFace
                            if type(font) ~= "string" then font = "Fonts\\FRIZQT__.TTF" end
                            local fontName = font:match("([^\\]+)$") or font
                            return "Font Preview: |cFF00FF00" .. fontName .. "|r\n" .. "|cFFFFFFFFThe quick brown fox jumps over the lazy dog|r"
                        end,
                        order = 18.5,
                    },
                },
            },
            barStyle = {
                name = "Bar Style",
                type = "group",
                order = 2,
                args = {
                    synchronizeStyle = {
                        type = "toggle",
                        name = "Synchronize Style",
                        desc = "To be implemented in the close future. |cFF00FF00I WAS NOT PREPARED|r",
                        get = function() return self.db.profile.barStyle.synchronizeStyle end,
                        set = function(_, value)
                            self.db.profile.barStyle.synchronizeStyle = value
                            BetterExpBar:SynchronizeBarStyles()
                        end,
                        order = 1,
                        disabled = true,
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
                    linkingHeader = {
                        type = "header",
                        name = "Bar Linking",
                        order = 5,
                    },
                    barsLinked = {
                        type = "toggle",
                        name = "Link Bars Together",
                        desc = "To be implemented in the close future. |cFF00FF00I WAS NOT PREPARED|r",
                        get = function() return self.db.profile.barStyle.barsLinked end,
                        set = function(_, value)
                            self.db.profile.barStyle.barsLinked = value
                            if value then
                                BetterExpBar:SynchronizeBarDimensions()
                                BetterExpBar:UpdateLinkedBars()
                                BetterExpBar:ApplyLinkedBarSettings()
                            else
                                -- When unlinking, restore individual positions
                                BetterExpBar:RestoreFramePosition(repBarFrame, "repBar")
                                BetterExpBar:UpdateExpBar()
                                BetterExpBar:UpdateRepBar()
                            end
                        end,
                        order = 6,
                        disabled = true,
                    },
                    linkedBarHeader = {
                        type = "header",
                        name = "Linked Bar Style",
                        order = 7,
                        hidden = function() return not self.db.profile.barStyle.barsLinked end,
                    },
                    linkedTexture = {
                        type = "select",
                        name = "Bar Texture",
                        desc = "Choose texture for both bars when linked",
                        values = function()
                            if LSM then
                                return LSM:List("statusbar")
                            else
                                return { ["Interface\\TargetingFrame\\UI-StatusBar"] = "UI-StatusBar" }
                            end
                        end,
                        get = function() return self.db.profile.barStyle.linkedTexture or "Interface\\TargetingFrame\\UI-StatusBar" end,
                        set = function(_, value)
                            self.db.profile.barStyle.linkedTexture = value
                            BetterExpBar:ApplyLinkedBarSettings()
                        end,
                        order = 8,
                        hidden = function() return not self.db.profile.barStyle.barsLinked end,
                    },
                    linkedFontFace = {
                        type = "select",
                        name = "Font",
                        desc = "Choose font for both bars when linked",
                        values = function()
                            if LSM then
                                return LSM:List("font")
                            else
                                return { ["Fonts\\FRIZQT__.TTF"] = "FRIZQT__" }
                            end
                        end,
                        get = function() return self.db.profile.barStyle.linkedFontFace or "Fonts\\FRIZQT__.TTF" end,
                        set = function(_, value)
                            self.db.profile.barStyle.linkedFontFace = value
                            BetterExpBar:ApplyLinkedBarSettings()
                        end,
                        order = 9,
                        hidden = function() return not self.db.profile.barStyle.barsLinked end,
                    },
                    linkedTextSize = {
                        type = "range",
                        name = "Text Size",
                        desc = "Font size for both bars when linked",
                        min = 8, max = 24, step = 1,
                        get = function() return self.db.profile.barStyle.linkedTextSize or 12 end,
                        set = function(_, value)
                            self.db.profile.barStyle.linkedTextSize = value
                            BetterExpBar:ApplyLinkedBarSettings()
                        end,
                        order = 10,
                        hidden = function() return not self.db.profile.barStyle.barsLinked end,
                    },
                    linkedSyncStyle = {
                        type = "toggle",
                        name = "Synchronize Style",
                        desc = "Also sync border and background when linked",
                        get = function() return self.db.profile.barStyle.synchronizeStyle end,
                        set = function(_, value)
                            self.db.profile.barStyle.synchronizeStyle = value
                            BetterExpBar:SynchronizeBarStyles()
                        end,
                        order = 11,
                        hidden = function() return not self.db.profile.barStyle.barsLinked end,
                    },
                    barOrder = {
                        type = "select",
                        name = "Bar Order",
                        desc = "To be implemented in the close future. |cFF00FF00I WAS NOT PREPARED|r",
                        values = {
                            ["exp"] = "Experience on Top",
                            ["rep"] = "Reputation on Top",
                        },
                        get = function() return self.db.profile.barStyle.barOrder or "exp" end,
                        set = function(_, value)
                            self.db.profile.barStyle.barOrder = value
                            if self.db.profile.barStyle.barsLinked then
                                BetterExpBar:UpdateLinkedBars()
                            end
                        end,
                        order = 12,
                        disabled = true,
                    },
                    lockingHeader = {
                        type = "header",
                        name = "Position Locking",
                        order = 13,
                    },
                    lockBarsPosition = {
                        type = "toggle",
                        name = "Lock Bar Positions",
                        desc = "Prevent bars from being dragged and repositioned independently",
                        get = function() return self.db.profile.barStyle.lockBarsPosition end,
                        set = function(_, value)
                            self.db.profile.barStyle.lockBarsPosition = value
                            if value then
                                BetterExpBar:ApplyBarLocking()
                            else
                                BetterExpBar:ReleaseBarLocking()
                            end
                        end,
                        order = 14,
                    },
                    syncStatus = {
                        type = "description",
                        name = function()
                            local status = "Bar Status: "
                            if self.db.profile.barStyle.barsLinked then
                                status = status .. "|cFF00FF00Linked|r"
                            else
                                status = status .. "|cFFFF6633Not Linked|r"
                            end
                            status = status .. " | "
                            if self.db.profile.barStyle.lockBarsPosition then
                                status = status .. "|cFF00FF00Locked|r"
                            else
                                status = status .. "|cFFFF6633Unlocked|r"
                            end
                            return status
                        end,
                        order = 15,
                    },
                    resetHeader = {
                        type = "header",
                        name = "Reset Options",
                        order = 16,
                    },
                    resetAll = {
                        type = "execute",
                        name = "Reset All to Defaults",
                        desc = "Reset all bars to their original appearance and settings",
                        func = function() BetterExpBar:ResetAll() end,
                        order = 17,
                    },
                },
            },
            experience = {
                name = "Experience",
                type = "group",
                order = 3,
                disabled = function() return self.db.profile.barStyle.barsLinked end,
                args = {
                    opacity = {
                        type = "range",
                        name = "Opacity",
                        desc = "Current XP bar opacity (purple bar only)",
                        min = 0.1, max = 1, step = 0.1,
                        get = function() return BetterExpBar.db.profile.expBar.opacity or 0.8 end,
                        set = function(_, value)
                            BetterExpBar.db.profile.expBar.opacity = value
                            -- Set alpha ONLY for expBarInner (current XP progression)
                            if expBarInner then
                                expBarInner:SetAlpha(value)
                            end
                        end,
                        order = 1,
                    },
                    questXPOpacity = {
                        type = "range",
                        name = "Quest XP Opacity",
                        desc = "Quest XP bar opacity (green bar only)",
                        min = 0.1, max = 1, step = 0.1,
                        get = function() return BetterExpBar.db.profile.expBar.questXPOpacity or 0.6 end,
                        set = function(_, value)
                            BetterExpBar.db.profile.expBar.questXPOpacity = value
                            -- Set alpha ONLY for questXPBar (quest reward progression)
                            if questXPBar then
                                questXPBar:SetAlpha(value)
                            end
                        end,
                        order = 1.5,
                    },
                    restedXPOpacity = {
                        type = "range",
                        name = "Rested XP Opacity",
                        desc = "Rested XP bar opacity (blue bar only)",
                        min = 0.1, max = 1, step = 0.1,
                        get = function() return BetterExpBar.db.profile.expBar.restedXPOpacity or 0.5 end,
                        set = function(_, value)
                            BetterExpBar.db.profile.expBar.restedXPOpacity = value
                            -- Set alpha ONLY for restedBar (resting bonus progression)
                            if restedBar then
                                restedBar:SetAlpha(value)
                            end
                        end,
                        order = 1.6,
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
                        disabled = function() return self.db.profile.barStyle.barsLinked end,
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
                    textColor = {
                        type = "color",
                        name = "Text Color",
                        desc = "Color of experience bar text",
                        hasAlpha = true,
                        get = function()
                            local c = self.db.profile.expBar.textColor
                            return c.r, c.g, c.b, c.a
                        end,
                        set = function(_, r, g, b, a)
                            self.db.profile.expBar.textColor = { r = r, g = g, b = b, a = a }
                            if expText then
                                expText:SetTextColor(r, g, b, a)
                            end
                        end,
                        order = 4,
                    },
                    showQuestXP = {
                        type = "toggle",
                        name = "Show Quest XP Prediction",
                        desc = "Display predicted experience from completed quests on the bar",
                        get = function() return self.db.profile.expDisplay.showQuestXP end,
                        set = function(_, value)
                            self.db.profile.expDisplay.showQuestXP = value
                            BetterExpBar:UpdateExpBar()
                        end,
                        order = 5,
                    },
                    sizeHeader = {
                        type = "header",
                        name = "Bar Dimensions",
                        order = 6,
                    },
                    width = {
                        type = "range",
                        name = "Width",
                        desc = "Width of the experience bar (click value to manually enter)",
                        min = 100, max = 1500, step = 10,
                        get = function() return self.db.profile.expBar.width or 1024 end,
                        set = function(_, value)
                            self.db.profile.expBar.width = value
                            if expBarFrame then expBarFrame:SetWidth(value) end
                            if largerFrame then largerFrame:SetWidth(value + 10) end
                        end,
                        order = 6.5,
                    },
                    height = {
                        type = "range",
                        name = "Height",
                        desc = "Height of the experience bar (click value to manually enter)",
                        min = 10, max = 100, step = 5,
                        get = function() return self.db.profile.expBar.height or 20 end,
                        set = function(_, value)
                            self.db.profile.expBar.height = value
                            if expBarFrame then expBarFrame:SetHeight(value) end
                            if largerFrame then largerFrame:SetHeight(value + 10) end
                        end,
                        order = 6.7,
                    },
                    scale = {
                        type = "range",
                        name = "Scale",
                        desc = "Scale of the experience bar (click value to manually enter)",
                        min = 0.5, max = 2.0, step = 0.1,
                        get = function() return self.db.profile.expBar.scale or 1.0 end,
                        set = function(_, value)
                            self.db.profile.expBar.scale = value
                            if expBarFrame then expBarFrame:SetScale(value) end
                            if largerFrame then largerFrame:SetScale(value) end
                        end,
                        order = 6.9,
                    },
                },
            },
            reputation = {
                name = "Reputation",
                type = "group",
                order = 4,
                disabled = function() return self.db.profile.barStyle.barsLinked end,
                args = {
                    opacity = {
                        type = "range",
                        name = "Opacity",
                        desc = "Reputation bar opacity (progress bar only)",
                        min = 0.1, max = 1, step = 0.1,
                        get = function() return BetterExpBar.db.profile.repBar.opacity or 0.8 end,
                        set = function(_, value)
                            BetterExpBar.db.profile.repBar.opacity = value
                            -- Ensure frame stays opaque while bar gets the opacity
                            if repBarFrame then repBarFrame:SetAlpha(1.0) end
                            -- Set alpha ONLY for repBarInner (reputation progression)
                            if repBarInner then
                                repBarInner:SetAlpha(value)
                            end
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
                        disabled = function() return self.db.profile.barStyle.barsLinked end,
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
                    textColor = {
                        type = "color",
                        name = "Text Color",
                        desc = "Color of reputation bar text",
                        hasAlpha = true,
                        get = function()
                            local c = self.db.profile.repBar.textColor
                            return c.r, c.g, c.b, c.a
                        end,
                        set = function(_, r, g, b, a)
                            self.db.profile.repBar.textColor = { r = r, g = g, b = b, a = a }
                            if repText then
                                repText:SetTextColor(r, g, b, a)
                            end
                        end,
                        order = 4,
                    },
                    displayHeader = {
                        type = "header",
                        name = "Reputation Options",
                        order = 5,
                    },
                    showBonusRep = {
                        type = "toggle",
                        name = "Show Bonus Reputation",
                        desc = "Display predicted reputation from completed quests on the reputation bar",
                        get = function() return self.db.profile.repDisplay.showBonusRep end,
                        set = function(_, value)
                            self.db.profile.repDisplay.showBonusRep = value
                            BetterExpBar:UpdateRepBar()
                        end,
                        order = 6,
                    },
                    trackWatchedFaction = {
                        type = "toggle",
                        name = "Track Watched Faction",
                        desc = "Only count bonus reputation for the currently watched faction",
                        get = function() return self.db.profile.repDisplay.trackWatchedFaction end,
                        set = function(_, value)
                            self.db.profile.repDisplay.trackWatchedFaction = value
                            BetterExpBar:UpdateRepBar()
                        end,
                        order = 10,
                    },
                    sizeHeader = {
                        type = "header",
                        name = "Bar Dimensions",
                        order = 11,
                    },
                    width = {
                        type = "range",
                        name = "Width",
                        desc = "Width of the reputation bar (click value to manually enter)",
                        min = 100, max = 1500, step = 10,
                        get = function() return self.db.profile.repBar.width or 1024 end,
                        set = function(_, value)
                            self.db.profile.repBar.width = value
                            if repBarFrame then repBarFrame:SetWidth(value) end
                        end,
                        order = 11.5,
                    },
                    height = {
                        type = "range",
                        name = "Height",
                        desc = "Height of the reputation bar (click value to manually enter)",
                        min = 10, max = 100, step = 5,
                        get = function() return self.db.profile.repBar.height or 20 end,
                        set = function(_, value)
                            self.db.profile.repBar.height = value
                            if repBarFrame then repBarFrame:SetHeight(value) end
                        end,
                        order = 11.7,
                    },
                    scale = {
                        type = "range",
                        name = "Scale",
                        desc = "Scale of the reputation bar (click value to manually enter)",
                        min = 0.5, max = 2.0, step = 0.1,
                        get = function() return self.db.profile.repBar.scale or 1.0 end,
                        set = function(_, value)
                            self.db.profile.repBar.scale = value
                            if repBarFrame then repBarFrame:SetScale(value) end
                        end,
                        order = 11.9,
                    },
                },
            },
            tooltips = {
                name = "Tooltips",
                type = "group",
                order = 5,
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
                    tooltipTextColor = {
                        type = "color",
                        name = "Text Color",
                        desc = "Color of tooltip text",
                        hasAlpha = true,
                        get = function()
                            local c = self.db.profile.tooltip.textColor
                            return c.r, c.g, c.b, c.a
                        end,
                        set = function(_, r, g, b, a)
                            self.db.profile.tooltip.textColor = { r = r, g = g, b = b, a = a }
                            BetterExpBar:UpdateAllTooltips()
                        end,
                        order = 6,
                    },
                    formatHeader = {
                        type = "header",
                        name = "Number Format",
                        order = 7.5,
                    },
                    useVerbose = {
                        type = "toggle",
                        name = "Verbose Numbers",
                        desc = "Display numbers with full decimal places (e.g., 40,059 as 40.0k). Disables Common Abbreviation.",
                        get = function() return self.db.profile.expDisplay.useVerbose end,
                        set = function(_, value)
                            self.db.profile.expDisplay.useVerbose = value
                            if value then
                                self.db.profile.expDisplay.useCommon = false
                            end
                            BetterExpBar:UpdateTooltipText()
                            BetterExpBar:UpdateRepTooltip()
                        end,
                        order = 7.6,
                    },
                    useCommon = {
                        type = "toggle",
                        name = "Common Abbreviation",
                        desc = "Use common abbreviations (40k, 1M) instead of verbose decimals. Disables Verbose Numbers.",
                        get = function() return self.db.profile.expDisplay.useCommon end,
                        set = function(_, value)
                            self.db.profile.expDisplay.useCommon = value
                            if value then
                                self.db.profile.expDisplay.useVerbose = false
                            end
                            BetterExpBar:UpdateTooltipText()
                            BetterExpBar:UpdateRepTooltip()
                        end,
                        order = 7.7,
                    },
                    expTooltipHeader = {
                        type = "header",
                        name = "Experience Bar Tooltip",
                        order = 8,
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
            about = {
                name = "About",
                type = "group",
                order = 7,
                args = {
                    description = {
                        type = "description",
                        name = "|cFF00FF00Better Experience Bars|r\n\n|cFFFFFFFFVersion:|r 2.9.7\n|cFFFFFFFFAuthor:|r Pegga\n\n|cFFFFFFFFDescription:|r\nMoveable experience and reputation bars for WoW with customizable colors, opacity, and tooltip options.\n\n|cFFFFFFFFFeatures:|r\n• Customizable experience and reputation bars\n• Per-character profile management\n• Detailed tooltip configuration\n• Bar styling options (scale, opacity, colors)\n• Minimap button with DBIcon support\n• AceConfig-based options interface\n\n|cFFFFFFFFLibraries:|r\n• Ace3 Framework\n• LibDataBroker-1.1\n• LibDBIcon-1.0\n• LibButtonGlow-1.0\n• AceGUI-3.0-SharedMediaWidgets\n\nFor more information, visit the addon's homepage or use /bexpbar command for options.",
                        fontSize = "medium",
                        order = 1,
                    },
                },
            },
            profiles = {
                name = "Profiles",
                type = "group",
                order = 6,
                args = {
                    profilesHeader = {
                        type = "header",
                        name = "Profile Management",
                        order = 1,
                    },
                    profileInfo = {
                        type = "description",
                        name = "To create, copy, delete, or reset profiles, go to:\n    System > Interface Options > Addons > Better Exp & Rep Bars > Profiles \n\nOr use the profile dropdown in the main config window below.",
                        order = 2,
                    },
                },
            },
        },
    }

    AceConfig:RegisterOptionsTable("BetterExpBar", options)
    AceConfigDialog:AddToBlizOptions("BetterExpBar", "Better Exp & Rep Bars")
    
    -- Register profile options as a submenu if available
    if AceDBOptions and self.db then
        local profileOptions = AceDBOptions:GetOptionsTable(self.db)
        if profileOptions and profileOptions.args and profileOptions.handler then
            AceConfig:RegisterOptionsTable("BetterExpBar_Profiles", profileOptions)
            AceConfigDialog:AddToBlizOptions("BetterExpBar_Profiles", "Profiles", "Better Exp & Rep Bars")
        end
    end
end
