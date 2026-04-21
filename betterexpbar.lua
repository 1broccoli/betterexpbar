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
            offsetY = 10, -- Legacy fallback for older profiles
            expOffsetX = 0,
            expOffsetY = 10,
            repOffsetX = 0,
            repOffsetY = 10,
            -- Experience bar tooltip options
            expTooltip = {
                showLevel = true,
                showCurrent = true,
                showRested = true,
                showRemaining = true,
                showPercentage = true,
                -- NovaInstanceTracker optional features
                showXpPerHour = false,
                showXpPerHourPercent = false,
                showXpFromLastInstance = false,
                showXpFromLastInstancePercent = false,
                showXpTodayTotal = false,
                showXpTodayTotalPercent = false,
            },
            -- Reputation bar tooltip options
            repTooltip = {
                showFactionName = true,
                showStanding = true,
                showCurrent = true,
                showRemaining = true,
                showPercentage = true,
                -- NovaInstanceTracker optional features
                showRepPerHour = false,
                showRepPerHourPercent = false,
                showRepFromLastInstance = false,
                showRepFromLastInstancePercent = false,
                showRepTodayTotal = false,
                showRepTodayTotalPercent = false,
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
            -- Pulse/Glow settings
            pulseOnLevel = false,
            pulseOnGain = false,
            pulseStyle = "border", -- Options: border, glow, fill
            pulseColor = { r = 0, g = 1, b = 0, a = 1 }, -- Green by default
            pulseIntensity = 1.0,
            pulseAntiSpamMs = 500,
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
            useCommaFormat = false,
        },
        repDisplay = {
            showBonusRep = true,
            trackWatchedFaction = true,
        },
        tooltipPreview = {
            enabled = false,
            locked = false,
            showExp = true,
            showRep = true,
            expPoint = "CENTER",
            expRelativePoint = "CENTER",
            expXOfs = 0,
            expYOfs = 140,
            repPoint = "CENTER",
            repRelativePoint = "CENTER",
            repXOfs = 0,
            repYOfs = -140,
        },
    },
}

-- Frame references
local expBarContainer, largerFrame, expBarFrame, restedBar, questXPBar, expText, tooltipFrame, tooltipText, resizeHandle
local repBarFrame, repBarInner, bonusRepBar, repText, repTooltipFrame, repTooltipText, repResizeHandle
local expTexturePreview, repTexturePreview
local tooltipPreviewExpAnchor, tooltipPreviewExpBar, tooltipPreviewExpBarText
local tooltipPreviewRepAnchor, tooltipPreviewRepBar, tooltipPreviewRepBarText
local tooltipPreviewExpFrame, tooltipPreviewExpText, tooltipPreviewRepFrame, tooltipPreviewRepText
local nativeBarHooks = {}
local ADDON_MEDIA_PATH = "Interface\\AddOns\\betterexpbar\\Media"
local CUSTOM_FONT_MEDIA = {
    { "Adventure", ADDON_MEDIA_PATH .. "\\Fonts\\adventure.ttf" },
    { "Bazooka", ADDON_MEDIA_PATH .. "\\Fonts\\bazooka.ttf" },
    { "Big Noodle Titling", ADDON_MEDIA_PATH .. "\\Fonts\\BigNoodleTitling.ttf" },
    { "Cooline", ADDON_MEDIA_PATH .. "\\Fonts\\cooline.ttf" },
    { "DieDieDie", ADDON_MEDIA_PATH .. "\\Fonts\\diediedie.ttf" },
    { "Diogenes", ADDON_MEDIA_PATH .. "\\Fonts\\diogenes.ttf" },
    { "Expressway", ADDON_MEDIA_PATH .. "\\Fonts\\Expressway.ttf" },
    { "Fira Mono Medium", ADDON_MEDIA_PATH .. "\\Fonts\\FiraMono-Medium.ttf" },
    { "Fira Sans Condensed Heavy", ADDON_MEDIA_PATH .. "\\Fonts\\FiraSansCondensed-Heavy.ttf" },
    { "Fira Sans Condensed Medium", ADDON_MEDIA_PATH .. "\\Fonts\\FiraSansCondensed-Medium.ttf" },
    { "Fira Sans Heavy", ADDON_MEDIA_PATH .. "\\Fonts\\FiraSans-Heavy.ttf" },
    { "Fira Sans Medium", ADDON_MEDIA_PATH .. "\\Fonts\\FiraSans-Medium.ttf" },
    { "Ginko", ADDON_MEDIA_PATH .. "\\Fonts\\ginko.ttf" },
    { "Heroic", ADDON_MEDIA_PATH .. "\\Fonts\\heroic.ttf" },
    { "Myriad", ADDON_MEDIA_PATH .. "\\Fonts\\Myriad.ttf" },
    { "Porky", ADDON_MEDIA_PATH .. "\\Fonts\\porky.ttf" },
    { "PT Sans Narrow Bold", ADDON_MEDIA_PATH .. "\\Fonts\\PTSansNarrow-Bold.ttf" },
    { "PT Sans Narrow Regular", ADDON_MEDIA_PATH .. "\\Fonts\\PTSansNarrow-Regular.ttf" },
    { "Talisman", ADDON_MEDIA_PATH .. "\\Fonts\\talisman.ttf" },
    { "Transformers", ADDON_MEDIA_PATH .. "\\Fonts\\transformers.ttf" },
    { "Yellowjacket", ADDON_MEDIA_PATH .. "\\Fonts\\yellowjacket.ttf" },
}
local CUSTOM_STATUSBAR_MEDIA = {
    { "BetterExpBar Clean", ADDON_MEDIA_PATH .. "\\Textures\\Statusbar_Clean.blp" },
    { "BetterExpBar Stripes", ADDON_MEDIA_PATH .. "\\Textures\\Statusbar_Stripes.blp" },
    { "BetterExpBar Stripes Thin", ADDON_MEDIA_PATH .. "\\Textures\\Statusbar_Stripes_Thin.blp" },
    { "BetterExpBar Stripes Thick", ADDON_MEDIA_PATH .. "\\Textures\\Statusbar_Stripes_Thick.blp" },
    { "BetterExpBar Stripe Bar", ADDON_MEDIA_PATH .. "\\Textures\\stripe-bar.tga" },
    { "BetterExpBar Rainbow Stripe Bar", ADDON_MEDIA_PATH .. "\\Textures\\stripe-rainbow-bar.tga" },
    { "BetterExpBar Rainbow Bar", ADDON_MEDIA_PATH .. "\\Textures\\rainbowbar.tga" },
    { "BetterExpBar Striped Texture", ADDON_MEDIA_PATH .. "\\Textures\\StripedTexture.tga" },
}

-- Session tracking for XP/Rep per hour calculations
local sessionStartTime = GetServerTime()
local sessionStartXP = 0
local sessionStartRep = 0
local sessionXPGained = 0
local sessionRepGained = 0
local lastRecordedXP = 0
local lastRecordedRep = 0
local lastInstanceXPGain = 0
local lastInstanceRepGain = 0
local dailyStartTime = date("*t", GetServerTime())
local dailyXPGain = 0
local dailyRepGain = 0
local nitAvailable = false  -- Track if NIT is loaded

-- Check if NovaInstanceTracker is available and loaded
function BetterExpBar:IsNITAvailable()
    if not NIT then return false end
    if not NIT.db then return false end
    nitAvailable = true
    return true
end

function BetterExpBar:IsMaxLevel()
    local playerLevel = UnitLevel("player") or 0
    local maxLevel = GetMaxPlayerLevel() or 60
    return playerLevel >= maxLevel
end

function BetterExpBar:RegisterCustomMedia()
    if not LSM then return end

    for _, media in ipairs(CUSTOM_FONT_MEDIA) do
        LSM:Register("font", media[1], media[2])
    end

    for _, media in ipairs(CUSTOM_STATUSBAR_MEDIA) do
        LSM:Register("statusbar", media[1], media[2])
    end
end

function BetterExpBar:GetMediaOptions(mediatype, fallback)
    if not LSM then
        return fallback
    end

    local mediaTable = LSM:HashTable(mediatype)
    local mediaList = LSM:List(mediatype)
    local values = {}

    if mediaTable and mediaList then
        for _, mediaName in ipairs(mediaList) do
            local mediaPath = mediaTable[mediaName]
            if mediaPath and mediaPath ~= "" then
                values[mediaPath] = mediaName
            end
        end
    end

    if next(values) then
        return values
    end

    return fallback
end

function BetterExpBar:GetServerDayStart()
    local now = date("*t", GetServerTime())
    return GetServerTime() - (now.hour * 3600 + now.min * 60 + now.sec)
end

function BetterExpBar:GetLatestNITInstance(includeCurrent)
    if not (self:IsNITAvailable() and NIT.data and NIT.data.instances) then
        return nil
    end
    local playerName = UnitName("player")
    for i = 1, #NIT.data.instances do
        local instance = NIT.data.instances[i]
        if instance and instance.playerName == playerName then
            if includeCurrent then
                return instance
            end
            if instance.leftTime and instance.leftTime > 0 then
                return instance
            end
        end
    end
    return nil
end

-- Get XP statistics from NovaInstanceTracker if available
-- NIT Data Fields Accessed: sessionXpGained, xpDailyTotal, sessionStartTime
-- If NIT doesn't have these fields, they can be customized below
function BetterExpBar:GetNITXPStats()
    local xpPerHour = 0
    local xpFromLastInstance = 0
    local xpTodayTotal = 0
    
    -- Try to use NIT data if available
    if self:IsNITAvailable() and NIT.data and NIT.data.instances then
        -- Use current instance while inside, otherwise last completed instance
        local lastInstance = self:GetLatestNITInstance(NIT.inInstance and true or false)
        if lastInstance and lastInstance.xpFromChat then
            xpFromLastInstance = tonumber(lastInstance.xpFromChat) or 0
        end

        local dayStart = self:GetServerDayStart()
        local totalTimeToday = 0
        local playerName = UnitName("player")
        -- Calculate today's total by iterating through this character's instances
        for i = 1, #NIT.data.instances do
            local instance = NIT.data.instances[i]
            if instance and instance.playerName == playerName and instance.enteredTime then
                local leftTime = instance.leftTime or 0
                local overlapsToday = instance.enteredTime >= dayStart
                    or (leftTime > 0 and leftTime >= dayStart)
                    or (leftTime == 0 and NIT.inInstance)
                if overlapsToday then
                    if instance.xpFromChat then
                        xpTodayTotal = xpTodayTotal + (tonumber(instance.xpFromChat) or 0)
                    end
                    local overlapStart = instance.enteredTime
                    if overlapStart < dayStart then
                        overlapStart = dayStart
                    end
                    local overlapEnd = leftTime
                    if overlapEnd == 0 and NIT.inInstance then
                        overlapEnd = GetServerTime()
                    end
                    if overlapEnd and overlapEnd > overlapStart then
                        totalTimeToday = totalTimeToday + (overlapEnd - overlapStart)
                    end
                end
            end
        end

        -- Calculate per-hour from today's total and total instance time today
        if totalTimeToday >= 60 and xpTodayTotal ~= 0 then
            xpPerHour = math.floor(xpTodayTotal / (totalTimeToday / 3600))
        end
    end
    
    -- Fallback to session tracking if NIT didn't provide data
    if xpPerHour == 0 and xpFromLastInstance == 0 and xpTodayTotal == 0 then
        local sessionTime = GetServerTime() - sessionStartTime
        if sessionTime > 0 and sessionTime >= 3600 then
            xpPerHour = math.floor(sessionXPGained / (sessionTime / 3600))
        end
        xpFromLastInstance = lastInstanceXPGain
        xpTodayTotal = dailyXPGain
    end
    
    return xpPerHour, xpFromLastInstance, xpTodayTotal
end

-- Get Rep statistics from NovaInstanceTracker if available
function BetterExpBar:GetNITRepStats()
    local repPerHour = 0
    local repFromLastInstance = 0
    local repTodayTotal = 0
    
    -- Try to use NIT data if available
    if self:IsNITAvailable() and NIT.data and NIT.data.instances then
        -- Use current instance while inside, otherwise last completed instance
        local lastInstance = self:GetLatestNITInstance(NIT.inInstance and true or false)
        if lastInstance and lastInstance.rep then
            for _, repGain in pairs(lastInstance.rep) do
                if repGain then
                    repFromLastInstance = repFromLastInstance + (tonumber(repGain) or 0)
                end
            end
        end

        local dayStart = self:GetServerDayStart()
        local totalTimeToday = 0
        local playerName = UnitName("player")
        -- Calculate today's total by iterating through this character's instances
        for i = 1, #NIT.data.instances do
            local instance = NIT.data.instances[i]
            if instance and instance.playerName == playerName and instance.enteredTime then
                local leftTime = instance.leftTime or 0
                local overlapsToday = instance.enteredTime >= dayStart
                    or (leftTime > 0 and leftTime >= dayStart)
                    or (leftTime == 0 and NIT.inInstance)
                if overlapsToday then
                    if instance.rep then
                        for _, repGain in pairs(instance.rep) do
                            if repGain then
                                repTodayTotal = repTodayTotal + (tonumber(repGain) or 0)
                            end
                        end
                    end
                    local overlapStart = instance.enteredTime
                    if overlapStart < dayStart then
                        overlapStart = dayStart
                    end
                    local overlapEnd = leftTime
                    if overlapEnd == 0 and NIT.inInstance then
                        overlapEnd = GetServerTime()
                    end
                    if overlapEnd and overlapEnd > overlapStart then
                        totalTimeToday = totalTimeToday + (overlapEnd - overlapStart)
                    end
                end
            end
        end

        -- Calculate per-hour from today's total and total instance time today
        if totalTimeToday >= 60 and repTodayTotal ~= 0 then
            repPerHour = math.floor(repTodayTotal / (totalTimeToday / 3600))
        end
    end
    
    -- Fallback to session tracking if NIT didn't provide data
    if repPerHour == 0 and repFromLastInstance == 0 and repTodayTotal == 0 then
        local sessionTime = GetServerTime() - sessionStartTime
        if sessionTime > 0 and sessionTime >= 3600 then
            repPerHour = math.floor(sessionRepGained / (sessionTime / 3600))
        end
        repFromLastInstance = lastInstanceRepGain
        repTodayTotal = dailyRepGain
    end

    return repPerHour, repFromLastInstance, repTodayTotal
end

-- Update session XP tracking
function BetterExpBar:UpdateSessionXPTracking()
    local currentXP = UnitXP("player") or 0
    if lastRecordedXP == 0 then
        lastRecordedXP = currentXP
        sessionStartXP = currentXP
    else
        local xpGained = currentXP - lastRecordedXP
        if xpGained > 0 then
            sessionXPGained = sessionXPGained + xpGained
            dailyXPGain = dailyXPGain + xpGained
            lastRecordedXP = currentXP
        end
    end
end

-- Update session Rep tracking
function BetterExpBar:UpdateSessionRepTracking()
    -- Check if watching a faction
    local name, standing, minRep, maxRep, currentRep
    if GetWatchedFactionInfo then
        name, standing, minRep, maxRep, currentRep = GetWatchedFactionInfo()
    elseif GetNumFactions then
        local numFactions = GetNumFactions()
        for i = 1, numFactions do
            local factionName, description, standingId, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched = GetFactionInfo(i)
            if isWatched then
                name = factionName
                standing = standingId
                minRep = barMin
                maxRep = barMax
                currentRep = barValue
                break
            end
        end
    end
    
    if currentRep then
        if lastRecordedRep == 0 then
            lastRecordedRep = currentRep
            sessionStartRep = currentRep
        else
            local repGained = currentRep - lastRecordedRep
            if repGained > 0 then
                sessionRepGained = sessionRepGained + repGained
                dailyRepGain = dailyRepGain + repGained
                lastRecordedRep = currentRep
            end
        end
    end
end

function BetterExpBar:OnInitialize()
    -- Initialize database with defaults
    self.db = AceDB:New("BetterExpBarDB", defaults, true)

    self:RegisterCustomMedia()
    
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
    self:CreateTooltipPreviewFrames()
    if self.db and self.db.profile and self.db.profile.tooltipPreview then
        -- Preview visibility is session-only; always start hidden after reload.
        self.db.profile.tooltipPreview.enabled = false
        self.db.profile.tooltipPreview.showExp = false
        self.db.profile.tooltipPreview.showRep = false
    end
    self:ApplyNativeBarVisibility()
    self:UpdateTooltipPreview()
    
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
    self:SetNativeExpBarVisibility(true)
    self:SetNativeRepBarVisibility(true)
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
    self:UpdateTooltipPreview()
end

function BetterExpBar:GetTooltipPreviewText(previewType)
    previewType = previewType or "exp"

    if previewType == "rep" then
        local cfg = self.db.profile.tooltip.repTooltip
        local lines = {}
        if cfg.showFactionName then
            table.insert(lines, "|cffffff00Argent Dawn|r")
        end
        if cfg.showStanding then
            table.insert(lines, "|cff00ff00Friendly|r")
        end
        if cfg.showCurrent then
            table.insert(lines, "Current: |cff3399ff" .. self:FormatNumber(4200) .. "|r / " .. self:FormatNumber(12000))
        end
        if cfg.showRemaining then
            table.insert(lines, "Remaining: |cffa335ee" .. self:FormatNumber(7800) .. "|r")
        end
        if cfg.showRepPerHour then
            local line = "Rep/Hour: |cff00ff00+" .. self:FormatNumber(950) .. "|r"
            if cfg.showRepPerHourPercent then
                line = line .. " |cff00ff00(7.9%)|r"
            end
            table.insert(lines, line)
        end
        if cfg.showRepFromLastInstance then
            local line = "Last Instance: |cff00ffff+" .. self:FormatNumber(320) .. "|r"
            if cfg.showRepFromLastInstancePercent then
                line = line .. " |cff00ffff(2.6%)|r"
            end
            table.insert(lines, line)
        end
        if cfg.showRepTodayTotal then
            local line = "Today Total: |cfff0ad4e+" .. self:FormatNumber(2480) .. "|r"
            if cfg.showRepTodayTotalPercent then
                line = line .. " |cfff0ad4e(20.6%)|r"
            end
            table.insert(lines, line)
        end
        if #lines == 0 then
            lines = { "Tooltip preview is empty with current settings." }
        end
        return table.concat(lines, "\n")
    end

    local cfg = self.db.profile.tooltip.expTooltip
    local lines = {}
    if cfg.showLevel then
        table.insert(lines, "Level: |cff00ff0035|r")
    end
    if cfg.showCurrent then
        table.insert(lines, "Current: |cffffff00" .. self:FormatNumber(14500) .. "|r / |cffffff00" .. self:FormatNumber(22000) .. "|r (65%)")
    end
    table.insert(lines, "Quest Bonus: |cff00ff00+" .. self:FormatNumber(1800) .. "|r |cff00ff00(8%)|r")
    if cfg.showRested then
        table.insert(lines, "Resting Bonus: |cff3399ff+" .. self:FormatNumber(3200) .. "|r |cff3399ff(15%)|r")
    end
    if cfg.showRemaining then
        table.insert(lines, "Remaining: |cffa335ee" .. self:FormatNumber(7500) .. "|r")
    end
    if cfg.showXpPerHour then
        local line = "XP/Hour: |cff00ff00+" .. self:FormatNumber(41000) .. "|r"
        if cfg.showXpPerHourPercent then
            line = line .. " |cff00ff00(186%)|r"
        end
        table.insert(lines, line)
    end
    if cfg.showXpFromLastInstance then
        local line = "Last Instance: |cff00ffff+" .. self:FormatNumber(5200) .. "|r"
        if cfg.showXpFromLastInstancePercent then
            line = line .. " |cff00ffff(23%)|r"
        end
        table.insert(lines, line)
    end
    if cfg.showXpTodayTotal then
        local line = "Today Total: |cfff0ad4e+" .. self:FormatNumber(93800) .. "|r"
        if cfg.showXpTodayTotalPercent then
            line = line .. " |cfff0ad4e(426%)|r"
        end
        table.insert(lines, line)
    end
    if #lines == 0 then
        lines = { "Tooltip preview is empty with current settings." }
    end
    return table.concat(lines, "\n")
end

function BetterExpBar:CreateTooltipPreviewFrames()
    if tooltipPreviewExpAnchor and tooltipPreviewRepAnchor and tooltipPreviewExpFrame and tooltipPreviewRepFrame then
        return
    end

    tooltipPreviewExpAnchor = CreateFrame("Frame", "BetterExpBar_TooltipPreviewExpAnchor", UIParent, "BackdropTemplate")
    tooltipPreviewExpAnchor:SetSize(280, 24)
    tooltipPreviewExpAnchor:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 10,
    })
    tooltipPreviewExpAnchor:SetMovable(true)
    tooltipPreviewExpAnchor:EnableMouse(true)
    tooltipPreviewExpAnchor:RegisterForDrag("LeftButton")
    tooltipPreviewExpAnchor:SetFrameStrata("HIGH")
    tooltipPreviewExpAnchor:SetScript("OnDragStart", function(frame)
        frame:StartMoving()
    end)
    tooltipPreviewExpAnchor:SetScript("OnDragStop", function(frame)
        frame:StopMovingOrSizing()
        local point, _, relativePoint, xOfs, yOfs = frame:GetPoint()
        BetterExpBar.db.profile.tooltipPreview.expPoint = point
        BetterExpBar.db.profile.tooltipPreview.expRelativePoint = relativePoint
        BetterExpBar.db.profile.tooltipPreview.expXOfs = xOfs
        BetterExpBar.db.profile.tooltipPreview.expYOfs = yOfs
        BetterExpBar:UpdateTooltipPreview()
    end)
    tooltipPreviewExpAnchor:SetScript("OnHide", function()
        if tooltipPreviewExpFrame then tooltipPreviewExpFrame:Hide() end
    end)

    tooltipPreviewRepAnchor = CreateFrame("Frame", "BetterExpBar_TooltipPreviewRepAnchor", UIParent, "BackdropTemplate")
    tooltipPreviewRepAnchor:SetSize(280, 24)
    tooltipPreviewRepAnchor:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 10,
    })
    tooltipPreviewRepAnchor:SetMovable(true)
    tooltipPreviewRepAnchor:EnableMouse(true)
    tooltipPreviewRepAnchor:RegisterForDrag("LeftButton")
    tooltipPreviewRepAnchor:SetFrameStrata("HIGH")
    tooltipPreviewRepAnchor:SetScript("OnDragStart", function(frame)
        frame:StartMoving()
    end)
    tooltipPreviewRepAnchor:SetScript("OnDragStop", function(frame)
        frame:StopMovingOrSizing()
        local point, _, relativePoint, xOfs, yOfs = frame:GetPoint()
        BetterExpBar.db.profile.tooltipPreview.repPoint = point
        BetterExpBar.db.profile.tooltipPreview.repRelativePoint = relativePoint
        BetterExpBar.db.profile.tooltipPreview.repXOfs = xOfs
        BetterExpBar.db.profile.tooltipPreview.repYOfs = yOfs
        BetterExpBar:UpdateTooltipPreview()
    end)
    tooltipPreviewRepAnchor:SetScript("OnHide", function()
        if tooltipPreviewRepFrame then tooltipPreviewRepFrame:Hide() end
    end)

    tooltipPreviewExpBar = CreateFrame("StatusBar", nil, tooltipPreviewExpAnchor)
    tooltipPreviewExpBar:SetPoint("TOPLEFT", tooltipPreviewExpAnchor, "TOPLEFT", 6, -5)
    tooltipPreviewExpBar:SetPoint("BOTTOMRIGHT", tooltipPreviewExpAnchor, "BOTTOMRIGHT", -6, 5)
    tooltipPreviewExpBar:SetMinMaxValues(0, 1)
    tooltipPreviewExpBar:SetValue(0.65)

    tooltipPreviewRepBar = CreateFrame("StatusBar", nil, tooltipPreviewRepAnchor)
    tooltipPreviewRepBar:SetPoint("TOPLEFT", tooltipPreviewRepAnchor, "TOPLEFT", 6, -5)
    tooltipPreviewRepBar:SetPoint("BOTTOMRIGHT", tooltipPreviewRepAnchor, "BOTTOMRIGHT", -6, 5)
    tooltipPreviewRepBar:SetMinMaxValues(0, 1)
    tooltipPreviewRepBar:SetValue(0.65)

    tooltipPreviewExpBarText = tooltipPreviewExpBar:CreateFontString(nil, "OVERLAY")
    tooltipPreviewExpBarText:SetPoint("CENTER", tooltipPreviewExpBar, "CENTER", 0, 0)
    tooltipPreviewExpBarText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    tooltipPreviewExpBarText:SetText("EXP Tooltip Preview Anchor")

    tooltipPreviewRepBarText = tooltipPreviewRepBar:CreateFontString(nil, "OVERLAY")
    tooltipPreviewRepBarText:SetPoint("CENTER", tooltipPreviewRepBar, "CENTER", 0, 0)
    tooltipPreviewRepBarText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    tooltipPreviewRepBarText:SetText("REP Tooltip Preview Anchor")

    tooltipPreviewExpFrame = CreateFrame("Frame", "BetterExpBar_TooltipPreviewExp", UIParent, "BackdropTemplate")
    tooltipPreviewExpFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
    })
    tooltipPreviewExpFrame:SetFrameStrata("TOOLTIP")

    tooltipPreviewExpText = tooltipPreviewExpFrame:CreateFontString(nil, "OVERLAY")
    tooltipPreviewExpText:SetPoint("TOPLEFT", tooltipPreviewExpFrame, "TOPLEFT", 10, -10)
    tooltipPreviewExpText:SetJustifyH("LEFT")
    tooltipPreviewExpText:SetJustifyV("TOP")
    tooltipPreviewExpText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")

    tooltipPreviewRepFrame = CreateFrame("Frame", "BetterExpBar_TooltipPreviewRep", UIParent, "BackdropTemplate")
    tooltipPreviewRepFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
    })
    tooltipPreviewRepFrame:SetFrameStrata("TOOLTIP")

    tooltipPreviewRepText = tooltipPreviewRepFrame:CreateFontString(nil, "OVERLAY")
    tooltipPreviewRepText:SetPoint("TOPLEFT", tooltipPreviewRepFrame, "TOPLEFT", 10, -10)
    tooltipPreviewRepText:SetJustifyH("LEFT")
    tooltipPreviewRepText:SetJustifyV("TOP")
    tooltipPreviewRepText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")

    local cfg = self.db.profile.tooltipPreview
    if cfg.expPoint and cfg.expRelativePoint then
        tooltipPreviewExpAnchor:ClearAllPoints()
        tooltipPreviewExpAnchor:SetPoint(cfg.expPoint, UIParent, cfg.expRelativePoint, cfg.expXOfs or 0, cfg.expYOfs or 140)
    else
        tooltipPreviewExpAnchor:SetPoint("CENTER", UIParent, "CENTER", 0, 140)
    end

    if cfg.repPoint and cfg.repRelativePoint then
        tooltipPreviewRepAnchor:ClearAllPoints()
        tooltipPreviewRepAnchor:SetPoint(cfg.repPoint, UIParent, cfg.repRelativePoint, cfg.repXOfs or 0, cfg.repYOfs or -140)
    else
        tooltipPreviewRepAnchor:SetPoint("CENTER", UIParent, "CENTER", 0, -140)
    end
end

function BetterExpBar:ApplyTooltipPreviewLockState()
    if not tooltipPreviewExpAnchor or not tooltipPreviewRepAnchor then return end
    tooltipPreviewExpAnchor:EnableMouse(true)
    tooltipPreviewRepAnchor:EnableMouse(true)
    if tooltipPreviewExpBarText then
        tooltipPreviewExpBarText:SetText("EXP Tooltip Preview Anchor (Drag)")
    end
    if tooltipPreviewRepBarText then
        tooltipPreviewRepBarText:SetText("REP Tooltip Preview Anchor (Drag)")
    end
end

function BetterExpBar:GetTooltipOffsets(tooltipType)
    local cfg = self.db and self.db.profile and self.db.profile.tooltip
    if not cfg then
        return 0, 10
    end

    local legacyY = cfg.offsetY or 10
    if tooltipType == "rep" then
        return cfg.repOffsetX or 0, cfg.repOffsetY or legacyY
    end
    return cfg.expOffsetX or 0, cfg.expOffsetY or legacyY
end

function BetterExpBar:RefreshFontPreviews()
    if not self.db or not self.db.profile then return end

    local barFontChoice = self.db.profile.barStyle.linkedFontFace
    if not self.db.profile.barStyle.barsLinked then
        barFontChoice = self.db.profile.expBar.fontFace or barFontChoice
    end

    local barFont = self:GetSafeFont(barFontChoice or "Fonts\\FRIZQT__.TTF")
    local tooltipFont = self:GetSafeFont(self.db.profile.tooltip.fontFace or "Fonts\\FRIZQT__.TTF")
    local tooltipSize = self.db.profile.tooltip.fontSize or 12

    if tooltipPreviewExpBarText then
        tooltipPreviewExpBarText:SetFont(barFont, 11, "OUTLINE")
        tooltipPreviewExpBarText:SetText("EXP Tooltip Preview Anchor (Drag)")
    end

    if tooltipPreviewRepBarText then
        tooltipPreviewRepBarText:SetFont(barFont, 11, "OUTLINE")
        tooltipPreviewRepBarText:SetText("REP Tooltip Preview Anchor (Drag)")
    end

    if tooltipPreviewExpText then
        tooltipPreviewExpText:SetFont(tooltipFont, tooltipSize, "OUTLINE")
    end

    if tooltipPreviewRepText then
        tooltipPreviewRepText:SetFont(tooltipFont, tooltipSize, "OUTLINE")
    end
end

function BetterExpBar:UpdateTooltipPreview()
    if not self.db or not self.db.profile or not self.db.profile.tooltipPreview then return end
    local previewConfig = self.db.profile.tooltipPreview

    if previewConfig.showExp == nil then previewConfig.showExp = true end
    if previewConfig.showRep == nil then previewConfig.showRep = true end
    previewConfig.locked = false
    if not previewConfig.expPoint and previewConfig.point then
        previewConfig.expPoint = previewConfig.point
        previewConfig.expRelativePoint = previewConfig.relativePoint
        previewConfig.expXOfs = previewConfig.xOfs
        previewConfig.expYOfs = previewConfig.yOfs
    end
    if not previewConfig.repPoint and previewConfig.point then
        previewConfig.repPoint = previewConfig.point
        previewConfig.repRelativePoint = previewConfig.relativePoint
        previewConfig.repXOfs = previewConfig.xOfs
        previewConfig.repYOfs = previewConfig.yOfs
    end

    if not previewConfig.enabled then
        if tooltipPreviewExpFrame then tooltipPreviewExpFrame:Hide() end
        if tooltipPreviewRepFrame then tooltipPreviewRepFrame:Hide() end
        if tooltipPreviewExpAnchor then tooltipPreviewExpAnchor:Hide() end
        if tooltipPreviewRepAnchor then tooltipPreviewRepAnchor:Hide() end
        return
    end

    self:CreateTooltipPreviewFrames()

    local expColor = self.db.profile.colors.exp
    tooltipPreviewExpBar:SetStatusBarTexture(self.db.profile.expBar.texture or "Interface\\TargetingFrame\\UI-StatusBar")
    tooltipPreviewExpBar:SetStatusBarColor(expColor.r, expColor.g, expColor.b, expColor.a or 1)

    local repColor = self:GetFactionColor(5)
    tooltipPreviewRepBar:SetStatusBarTexture(self.db.profile.repBar.texture or "Interface\\TargetingFrame\\UI-StatusBar")
    tooltipPreviewRepBar:SetStatusBarColor(repColor.r, repColor.g, repColor.b, repColor.a or 1)

    local textColor = self.db.profile.tooltip.textColor
    tooltipPreviewExpBarText:SetTextColor(textColor.r, textColor.g, textColor.b, textColor.a)
    tooltipPreviewRepBarText:SetTextColor(textColor.r, textColor.g, textColor.b, textColor.a)

    local expOffsetX, expOffsetY = self:GetTooltipOffsets("exp")
    local repOffsetX, repOffsetY = self:GetTooltipOffsets("rep")

    self:ApplyTooltipStyle(tooltipPreviewExpFrame, tooltipPreviewExpText)
    tooltipPreviewExpText:SetText(self:GetTooltipPreviewText("exp"))
    tooltipPreviewExpFrame:SetSize(tooltipPreviewExpText:GetStringWidth() + 20, tooltipPreviewExpText:GetStringHeight() + 20)
    tooltipPreviewExpFrame:ClearAllPoints()
    tooltipPreviewExpFrame:SetPoint("BOTTOM", tooltipPreviewExpAnchor, "TOP", expOffsetX, expOffsetY)

    self:ApplyTooltipStyle(tooltipPreviewRepFrame, tooltipPreviewRepText)
    tooltipPreviewRepText:SetText(self:GetTooltipPreviewText("rep"))
    tooltipPreviewRepFrame:SetSize(tooltipPreviewRepText:GetStringWidth() + 20, tooltipPreviewRepText:GetStringHeight() + 20)
    tooltipPreviewRepFrame:ClearAllPoints()
    tooltipPreviewRepFrame:SetPoint("BOTTOM", tooltipPreviewRepAnchor, "TOP", repOffsetX, repOffsetY)

    self:ApplyTooltipPreviewLockState()
    self:RefreshFontPreviews()
    if previewConfig.showExp then
        tooltipPreviewExpAnchor:Show()
        tooltipPreviewExpFrame:Show()
    else
        tooltipPreviewExpAnchor:Hide()
        tooltipPreviewExpFrame:Hide()
    end
    if previewConfig.showRep then
        tooltipPreviewRepAnchor:Show()
        tooltipPreviewRepFrame:Show()
    else
        tooltipPreviewRepAnchor:Hide()
        tooltipPreviewRepFrame:Hide()
    end
end

function BetterExpBar:AnchorTooltipFrame(frame, fallbackBarFrame, tooltipType)
    if not frame then return end
    frame:ClearAllPoints()
    local xOff, yOff = self:GetTooltipOffsets(tooltipType)

    -- Use type-specific preview anchor if it exists.
    if tooltipType == "rep" and tooltipPreviewRepAnchor then
        frame:SetPoint("BOTTOM", tooltipPreviewRepAnchor, "TOP", xOff, yOff)
    elseif tooltipType == "exp" and tooltipPreviewExpAnchor then
        frame:SetPoint("BOTTOM", tooltipPreviewExpAnchor, "TOP", xOff, yOff)
    elseif fallbackBarFrame then
        frame:SetPoint("BOTTOM", fallbackBarFrame, "TOP", xOff, yOff)
    end
end

function BetterExpBar:SynchronizeBarStyles()
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
        -- Use noDefault=true so file-path values don't get replaced by LSM's default font.
        local resolved = LSM:Fetch("font", font, true)
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
    local useCommaFormat = false
    
    if self.db and self.db.profile and self.db.profile.expDisplay then
        useCommon = self.db.profile.expDisplay.useCommon or false
        useVerbose = self.db.profile.expDisplay.useVerbose or false
        useCommaFormat = self.db.profile.expDisplay.useCommaFormat or false
    end
    
    -- If any format is enabled, use it; otherwise default to common
    if not useCommon and not useVerbose and not useCommaFormat then
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
    
    -- Comma-separated format: 40,393
    if useCommaFormat then
        local intNum = math.floor(num)
        local str = tostring(intNum)
        local result = ""
        local count = 0
        for i = #str, 1, -1 do
            if count == 3 then
                result = "," .. result
                count = 0
            end
            result = string.sub(str, i, i) .. result
            count = count + 1
        end
        return result
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

function BetterExpBar:GetWatchedFactionData()
    local name, standing, minRep, maxRep, currentRep, factionID

    -- Prefer manual scan for the watched faction for accuracy across clients.
    if GetNumFactions and GetFactionInfo then
        local numFactions = GetNumFactions()
        for i = 1, numFactions do
            local factionName, _, standingId, barMin, barMax, barValue, _, _, _, _, _, isWatched = GetFactionInfo(i)
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

    if not name and GetWatchedFactionInfo then
        name, standing, minRep, maxRep, currentRep, factionID = GetWatchedFactionInfo()
    end

    return name, standing, minRep, maxRep, currentRep, factionID
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
        local referenceFrame = expBarFrame
        if (self.db.profile.barStyle.barOrder or "exp") == "rep" then
            referenceFrame = repBarFrame
        end

        local refWidth, refHeight = referenceFrame:GetSize()
        refWidth = math.max(refWidth or 40, 40)
        refHeight = math.max(refHeight or 10, 10)

        expBarFrame:SetSize(refWidth, refHeight)
        repBarFrame:SetSize(refWidth, refHeight)

        if largerFrame then
            largerFrame:SetSize(refWidth + 10, refHeight + 10)
        end
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
    self:SynchronizeBarDimensions()
    
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
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 12,
        })
        local expOffsetX, expOffsetY = self:GetTooltipOffsets("exp")
        tooltipFrame:SetPoint("BOTTOM", expBarFrame, "TOP", expOffsetX, expOffsetY)
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

        tooltipFrame.updateElapsed = 0
        tooltipFrame:SetScript("OnUpdate", function(self, elapsed)
            if not self:IsShown() then return end
            self.updateElapsed = (self.updateElapsed or 0) + elapsed
            if self.updateElapsed >= 1 then
                self.updateElapsed = 0
                BetterExpBar:UpdateTooltipText()
            end
        end)

        -- Setup frame interactions
        expBarFrame:SetScript("OnEnter", function(self)
            if BetterExpBar.db.profile.tooltip.enabled and not BetterExpBar.db.profile.tooltipPreview.enabled then
                BetterExpBar:UpdateTooltipText()
                BetterExpBar:AnchorTooltipFrame(tooltipFrame, expBarFrame, "exp")
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
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
    })
    local repOffsetX, repOffsetY = self:GetTooltipOffsets("rep")
    repTooltipFrame:SetPoint("BOTTOM", repBarFrame, "TOP", repOffsetX, repOffsetY)
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

    repTooltipFrame.updateElapsed = 0
    repTooltipFrame:SetScript("OnUpdate", function(self, elapsed)
        if not self:IsShown() then return end
        self.updateElapsed = (self.updateElapsed or 0) + elapsed
        if self.updateElapsed >= 1 then
            self.updateElapsed = 0
            BetterExpBar:UpdateRepTooltip()
        end
    end)

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
        if BetterExpBar.db.profile.tooltip.enabled and not BetterExpBar.db.profile.tooltipPreview.enabled then
            BetterExpBar:UpdateRepTooltip()
            BetterExpBar:AnchorTooltipFrame(repTooltipFrame, repBarFrame, "rep")
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
    if not tooltipText or not tooltipFrame then return end
    
    -- Update session tracking
    self:UpdateSessionXPTracking()
    
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
    
    -- Add NovaInstanceTracker stats if any are enabled
    if tooltipConfig.showXpPerHour or tooltipConfig.showXpFromLastInstance or tooltipConfig.showXpTodayTotal then
        table.insert(tooltipLines, "")  -- Separator line
        
        local xpPerHour, xpFromLastInstance, xpTodayTotal = self:GetNITXPStats()
        
        if tooltipConfig.showXpPerHour then
            local line = string.format("XP/Hour: |cffa335ee%s|r", self:FormatNumber(xpPerHour))
            if tooltipConfig.showXpPerHourPercent and maxXP > 0 then
                local percent = math.floor((xpPerHour / maxXP) * 100 + 0.5)
                line = line .. string.format(" |cffa335ee(%d%%)|r", percent)
            end
            table.insert(tooltipLines, line)
        end
        
        if tooltipConfig.showXpFromLastInstance then
            local line = string.format("Instance XP: |cff00ff00+%s|r", self:FormatNumber(xpFromLastInstance))
            if tooltipConfig.showXpFromLastInstancePercent and maxXP > 0 then
                local percent = math.floor((xpFromLastInstance / maxXP) * 100 + 0.5)
                line = line .. string.format(" |cff00ff00(%d%%)|r", percent)
            end
            table.insert(tooltipLines, line)
        end
        
        if tooltipConfig.showXpTodayTotal then
            table.insert(tooltipLines, string.format("Today Total: |cfff0ad4e+%s|r", 
                self:FormatNumber(xpTodayTotal)))
        end
    end

    tooltipText:SetText(table.concat(tooltipLines, "\n"))
    tooltipFrame:SetSize(tooltipText:GetStringWidth() + 20, tooltipText:GetStringHeight() + 20)

    if self.db.profile.tooltipPreview.enabled then
        self:UpdateTooltipPreview()
    end
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
    
    local name, standing, minRep, maxRep, currentRep, factionID = self:GetWatchedFactionData()
    
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
    
    -- Update session tracking
    self:UpdateSessionRepTracking()
    
    local name, standing, minRep, maxRep, currentRep, factionID = self:GetWatchedFactionData()
    
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
        
        -- Add NovaInstanceTracker stats if any are enabled
        if tooltipConfig.showRepPerHour or tooltipConfig.showRepFromLastInstance or tooltipConfig.showRepTodayTotal then
            table.insert(tooltipLines, "")  -- Separator line
            
            local repPerHour, repFromLastInstance, repTodayTotal = self:GetNITRepStats()
            
            if tooltipConfig.showRepPerHour then
                local line = string.format("Rep/Hour: |cffa335ee%s|r", self:FormatNumber(repPerHour))
                if tooltipConfig.showRepPerHourPercent and maxValue > 0 then
                    local percent = math.floor((repPerHour / maxValue) * 100 + 0.5)
                    line = line .. string.format(" |cffa335ee(%d%%)|r", percent)
                end
                table.insert(tooltipLines, line)
            end
            
            if tooltipConfig.showRepFromLastInstance then
                local line = string.format("Instance Rep: |cff00ff00+%s|r", self:FormatNumber(repFromLastInstance))
                if tooltipConfig.showRepFromLastInstancePercent and maxValue > 0 then
                    local percent = math.floor((repFromLastInstance / maxValue) * 100 + 0.5)
                    line = line .. string.format(" |cff00ff00(%d%%)|r", percent)
                end
                table.insert(tooltipLines, line)
            end
            
            if tooltipConfig.showRepTodayTotal then
                table.insert(tooltipLines, string.format("Today Total: |cfff0ad4e+%s|r", 
                    self:FormatNumber(repTodayTotal)))
            end
        end
        
        repTooltipText:SetText(table.concat(tooltipLines, "\n"))
        
        repTooltipFrame:SetSize(repTooltipText:GetStringWidth() + 20, repTooltipText:GetStringHeight() + 20)
    else
        repTooltipText:SetText("No faction is currently being tracked.")
        repTooltipFrame:SetSize(repTooltipText:GetStringWidth() + 20, repTooltipText:GetStringHeight() + 20)
    end

    if self.db.profile.tooltipPreview.enabled then
        self:UpdateTooltipPreview()
    end
end

function BetterExpBar:ShouldHideNativeExpBar()
    return self.db and self.db.profile and self.db.profile.enabled
end

function BetterExpBar:ShouldHideNativeRepBar()
    return self.db and self.db.profile and self.db.profile.repBarEnabled
end

function BetterExpBar:SetNativeBarVisible(frame, showNative, hideCheckFn)
    if not frame then return end

    if showNative then
        frame:Show()
        return
    end

    frame:Hide()
    if frame.HookScript and not nativeBarHooks[frame] then
        frame:HookScript("OnShow", function(shownFrame)
            if hideCheckFn and hideCheckFn(self) then
                shownFrame:Hide()
            end
        end)
        nativeBarHooks[frame] = true
    end
end

function BetterExpBar:SetNativeExpBarVisibility(showNative)
    self:SetNativeBarVisible(MainMenuExpBar, showNative, self.ShouldHideNativeExpBar)
    self:SetNativeBarVisible(MainMenuBarExpBar, showNative, self.ShouldHideNativeExpBar)
    self:SetNativeBarVisible(MainStatusTrackingBarContainer, showNative, self.ShouldHideNativeExpBar)
    if MainMenuBar and MainMenuBar.ExpBar then
        self:SetNativeBarVisible(MainMenuBar.ExpBar, showNative, self.ShouldHideNativeExpBar)
    end
end

function BetterExpBar:SetNativeRepBarVisibility(showNative)
    self:SetNativeBarVisible(ReputationWatchBar, showNative, self.ShouldHideNativeRepBar)
    self:SetNativeBarVisible(MainMenuBarMaxLevelBar, showNative, self.ShouldHideNativeRepBar)
    self:SetNativeBarVisible(SecondaryStatusTrackingBarContainer, showNative, self.ShouldHideNativeRepBar)
    if MainMenuBar and MainMenuBar.MaxLevelBar then
        self:SetNativeBarVisible(MainMenuBar.MaxLevelBar, showNative, self.ShouldHideNativeRepBar)
    end
end

function BetterExpBar:ApplyNativeBarVisibility()
    self:SetNativeExpBarVisibility(not self:ShouldHideNativeExpBar())
    self:SetNativeRepBarVisibility(not self:ShouldHideNativeRepBar())
end

function BetterExpBar:HideDefaultExpBar()
    self:ApplyNativeBarVisibility()
end

function BetterExpBar:OnEnteringWorld()
    self:ApplyNativeBarVisibility()
    self:UpdateExpBar()
    if self.db.profile.repBarEnabled and repBarInner then
        self:UpdateRepBar()
    end
    
    -- Check if NIT is available (in case it loaded after us)
    self:IsNITAvailable()
    
    -- Initialize session tracking on login
    sessionStartTime = GetServerTime()
    sessionStartXP = UnitXP("player") or 0
    lastRecordedXP = sessionStartXP
    
    -- Check if it's a new day and reset daily counters if needed
    local currentTime = date("*t", GetServerTime())
    if dailyStartTime.year ~= currentTime.year or dailyStartTime.month ~= currentTime.month or dailyStartTime.day ~= currentTime.day then
        dailyXPGain = 0
        dailyRepGain = 0
        dailyStartTime = currentTime
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

function BetterExpBar:ResetTooltipPositions()
    local tooltipDefaults = defaults.profile.tooltip
    local previewDefaults = defaults.profile.tooltipPreview
    local tooltipConfig = self.db.profile.tooltip
    local previewConfig = self.db.profile.tooltipPreview
    local expPreviewX, expPreviewY = previewDefaults.expXOfs, previewDefaults.expYOfs
    local repPreviewX, repPreviewY = previewDefaults.repXOfs, previewDefaults.repYOfs

    tooltipConfig.expOffsetX = tooltipDefaults.expOffsetX
    tooltipConfig.expOffsetY = tooltipDefaults.expOffsetY
    tooltipConfig.repOffsetX = tooltipDefaults.repOffsetX
    tooltipConfig.repOffsetY = tooltipDefaults.repOffsetY

    -- Reset preview anchors to the visual default: centered slightly above each bar.
    if expBarFrame and expBarFrame.GetCenter then
        local expCenterX, expCenterY = expBarFrame:GetCenter()
        if expCenterX and expCenterY then
            expPreviewX = expCenterX - (UIParent:GetWidth() / 2)
            expPreviewY = expCenterY - (UIParent:GetHeight() / 2) + (expBarFrame:GetHeight() / 2) + 10
        end
    end

    if repBarFrame and repBarFrame.GetCenter then
        local repCenterX, repCenterY = repBarFrame:GetCenter()
        if repCenterX and repCenterY then
            repPreviewX = repCenterX - (UIParent:GetWidth() / 2)
            repPreviewY = repCenterY - (UIParent:GetHeight() / 2) + (repBarFrame:GetHeight() / 2) + 10
        end
    end

    previewConfig.expPoint = previewDefaults.expPoint
    previewConfig.expRelativePoint = previewDefaults.expRelativePoint
    previewConfig.expXOfs = expPreviewX
    previewConfig.expYOfs = expPreviewY
    previewConfig.repPoint = previewDefaults.repPoint
    previewConfig.repRelativePoint = previewDefaults.repRelativePoint
    previewConfig.repXOfs = repPreviewX
    previewConfig.repYOfs = repPreviewY

    if tooltipPreviewExpAnchor then
        tooltipPreviewExpAnchor:ClearAllPoints()
        tooltipPreviewExpAnchor:SetPoint(previewConfig.expPoint, UIParent, previewConfig.expRelativePoint, previewConfig.expXOfs, previewConfig.expYOfs)
    end

    if tooltipPreviewRepAnchor then
        tooltipPreviewRepAnchor:ClearAllPoints()
        tooltipPreviewRepAnchor:SetPoint(previewConfig.repPoint, UIParent, previewConfig.repRelativePoint, previewConfig.repXOfs, previewConfig.repYOfs)
    end

    if tooltipFrame and expBarFrame then
        self:AnchorTooltipFrame(tooltipFrame, expBarFrame, "exp")
    end

    if repTooltipFrame and repBarFrame then
        self:AnchorTooltipFrame(repTooltipFrame, repBarFrame, "rep")
    end

    self:UpdateTooltipPreview()
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

    self:ResetTooltipPositions()

    self:Print("Bar and tooltip positions have been reset to their defaults.")
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
    self:ApplyNativeBarVisibility()
    ReloadUI()
end

function BetterExpBar:DisableAddon()
    self.db.profile.enabled = false
    if expBarContainer then expBarContainer:Hide() end
    if largerFrame then largerFrame:Hide() end
    self:ApplyNativeBarVisibility()
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
        self:ApplyNativeBarVisibility()
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
    elseif command == "test" then
        if expBarContainer then
            -- Pulse effect on EXP bar
            local expBackdrop = expBarContainer:GetBackdrop()
            if expBackdrop then
                expBarContainer:SetBackdropBorderColor(0.3, 1, 0.3, 1)
                C_Timer.After(0.5, function()
                    expBarContainer:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
                end)
            end
            self:Print("Test pulse activated on Experience bar")
        end
        if repBarFrame then
            -- Pulse effect on REP bar
            local repBackdrop = repBarFrame:GetBackdrop()
            if repBackdrop then
                repBarFrame:SetBackdropBorderColor(0.3, 1, 0.3, 1)
                C_Timer.After(0.5, function()
                    repBarFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
                end)
            end
            self:Print("Test pulse activated on Reputation bar")
        end
    else
        self:Print("Usage:")
        self:Print("/beb reset - Reset the position of bars")
        self:Print("/beb enable - Enable the addon")
        self:Print("/beb disable - Disable the addon")
        self:Print("/beb togglerep - Toggle reputation bar")
        self:Print("/beb minimap - Toggle minimap button")
        self:Print("/beb config - Open configuration options")
        self:Print("/beb test - Test glow effect on bars")
    end
end

-- Options configuration
function BetterExpBar:RegisterOptions()
    local options = {
        name = "Better Experience Bars",
        desc = "v3.0.5 | By Pegga",
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
                        disabled = function() return BetterExpBar:IsMaxLevel() end,
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
                },
            },
            appearance = {
                name = "Appearance",
                type = "group",
                order = 1.5,
                args = {
                    appearanceIntro = {
                        type = "description",
                        name = "Visual customization options for bar colors and fonts.",
                        order = 0.5,
                    },
                    colorHeader = {
                        type = "header",
                        name = "Bar Colors",
                        order = 1,
                    },
                    exp = {
                        type = "color",
                        name = "Experience Bar Color",
                        desc = "Color of the experience bar",
                        hasAlpha = true,
                        disabled = function() return BetterExpBar:IsMaxLevel() end,
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
                        order = 2,
                    },
                    rested = {
                        type = "color",
                        name = "Rested Bar Color",
                        desc = "Color of the rested experience bar",
                        hasAlpha = true,
                        disabled = function() return BetterExpBar:IsMaxLevel() end,
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
                        order = 3,
                    },
                    questXPColor = {
                        type = "color",
                        name = "Quest XP Color",
                        desc = "Color of the predicted quest XP bar",
                        hasAlpha = true,
                        disabled = function() return BetterExpBar:IsMaxLevel() end,
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
                        order = 4,
                    },
                    repColorHeader = {
                        type = "header",
                        name = "Reputation",
                        order = 5,
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
                        order = 6,
                    },
                    fontHeader = {
                        type = "header",
                        name = "Fonts",
                        order = 7,
                    },
                    barFont = {
                        type = "select",
                        name = "Bar Font",
                        desc = "Choose the shared font used by both bars from your custom media and LibSharedMedia libraries. Live preview updates immediately.",
                        values = function()
                            return BetterExpBar:GetMediaOptions("font", { ["Fonts\\FRIZQT__.TTF"] = "Friz Quadrata TT" })
                        end,
                        get = function() return BetterExpBar.db.profile.barStyle.linkedFontFace or "Fonts\\FRIZQT__.TTF" end,
                        set = function(_, value)
                            BetterExpBar.db.profile.barStyle.linkedFontFace = value
                            BetterExpBar.db.profile.expBar.fontFace = value
                            BetterExpBar.db.profile.repBar.fontFace = value

                            BetterExpBar:UpdateExpBar()
                            BetterExpBar:UpdateRepBar()
                            BetterExpBar:UpdateAllTooltips()
                            BetterExpBar:UpdateTooltipPreview()
                        end,
                        order = 8,
                    },
                    tooltipFont = {
                        type = "select",
                        name = "Tooltip Font",
                        desc = "Choose the font used by experience and reputation tooltips. Live preview updates immediately.",
                        values = function()
                            return BetterExpBar:GetMediaOptions("font", { ["Fonts\\FRIZQT__.TTF"] = "Friz Quadrata TT" })
                        end,
                        get = function() return BetterExpBar.db.profile.tooltip.fontFace or "Fonts\\FRIZQT__.TTF" end,
                        set = function(_, value)
                            BetterExpBar.db.profile.tooltip.fontFace = value
                            BetterExpBar:UpdateAllTooltips()
                            BetterExpBar:UpdateTooltipPreview()
                        end,
                        order = 9,
                    },
                },
            },
            barStyle = {
                name = "Bar Style",
                type = "group",
                order = 2,
                args = {
                    dimensionsHeader = {
                        type = "header",
                        name = "Bar Dimensions",
                        order = 1,
                    },
                    expWidth = {
                        type = "range",
                        name = "EXP Width",
                        desc = "Width of the experience bar (click value to type).",
                        min = 100, max = 1500, step = 10,
                        disabled = function() return BetterExpBar:IsMaxLevel() end,
                        get = function() return self.db.profile.expBar.width or 1024 end,
                        set = function(_, value)
                            self.db.profile.expBar.width = value
                            if expBarFrame then expBarFrame:SetWidth(value) end
                            if largerFrame then largerFrame:SetWidth(value + 10) end
                            if self.db.profile.barStyle.barsLinked then
                                BetterExpBar:SynchronizeBarDimensions()
                                BetterExpBar:UpdateLinkedBars()
                            end
                        end,
                        order = 1.1,
                    },
                    expHeight = {
                        type = "range",
                        name = "EXP Height",
                        desc = "Height of the experience bar (click value to type).",
                        min = 10, max = 100, step = 5,
                        disabled = function() return BetterExpBar:IsMaxLevel() end,
                        get = function() return self.db.profile.expBar.height or 20 end,
                        set = function(_, value)
                            self.db.profile.expBar.height = value
                            if expBarFrame then expBarFrame:SetHeight(value) end
                            if largerFrame then largerFrame:SetHeight(value + 10) end
                            if self.db.profile.barStyle.barsLinked then
                                BetterExpBar:SynchronizeBarDimensions()
                                BetterExpBar:UpdateLinkedBars()
                            end
                        end,
                        order = 1.2,
                    },
                    repWidth = {
                        type = "range",
                        name = "REP Width",
                        desc = "Width of the reputation bar (click value to type).",
                        min = 100, max = 1500, step = 10,
                        get = function() return self.db.profile.repBar.width or 1024 end,
                        set = function(_, value)
                            self.db.profile.repBar.width = value
                            if repBarFrame then repBarFrame:SetWidth(value) end
                            if self.db.profile.barStyle.barsLinked then
                                BetterExpBar:SynchronizeBarDimensions()
                                BetterExpBar:UpdateLinkedBars()
                            end
                        end,
                        order = 1.3,
                    },
                    repHeight = {
                        type = "range",
                        name = "REP Height",
                        desc = "Height of the reputation bar (click value to type).",
                        min = 10, max = 100, step = 5,
                        get = function() return self.db.profile.repBar.height or 20 end,
                        set = function(_, value)
                            self.db.profile.repBar.height = value
                            if repBarFrame then repBarFrame:SetHeight(value) end
                            if self.db.profile.barStyle.barsLinked then
                                BetterExpBar:SynchronizeBarDimensions()
                                BetterExpBar:UpdateLinkedBars()
                            end
                        end,
                        order = 1.4,
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
                        name = "Work in Progress",
                        order = 19,
                    },
                    linkingNotice = {
                        type = "description",
                        name = "Linking controls are temporarily disabled while we finalize stability updates.",
                        order = 19.1,
                    },
                    barsLinked = {
                        type = "toggle",
                        name = "Link Bars Together",
                        desc = "Keep EXP and REP bars stacked together with matching dimensions.",
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
                        order = 19.2,
                        disabled = true,
                    },
                    linkedBarHeader = {
                        type = "header",
                        name = "Linked Bar Style",
                        order = 19.3,
                        hidden = function() return not self.db.profile.barStyle.barsLinked end,
                    },
                    linkedTexture = {
                        type = "select",
                        name = "Bar Texture",
                        desc = "Choose texture for both bars when linked",
                        values = function()
                            return BetterExpBar:GetMediaOptions("statusbar", { ["Interface\\TargetingFrame\\UI-StatusBar"] = "Blizzard" })
                        end,
                        get = function() return self.db.profile.barStyle.linkedTexture or "Interface\\TargetingFrame\\UI-StatusBar" end,
                        set = function(_, value)
                            self.db.profile.barStyle.linkedTexture = value
                            BetterExpBar:ApplyLinkedBarSettings()
                        end,
                        order = 8,
                        hidden = function() return not self.db.profile.barStyle.barsLinked end,
                    },
                    expTexture = {
                        type = "select",
                        name = "EXP Bar Texture",
                        desc = "Choose the texture used by the experience bar.",
                        disabled = function() return BetterExpBar:IsMaxLevel() end,
                        values = function()
                            return BetterExpBar:GetMediaOptions("statusbar", { ["Interface\\TargetingFrame\\UI-StatusBar"] = "Blizzard" })
                        end,
                        get = function() return self.db.profile.expBar.texture or "Interface\\TargetingFrame\\UI-StatusBar" end,
                        set = function(_, value)
                            self.db.profile.expBar.texture = value
                            if expBarInner then
                                expBarInner:SetStatusBarTexture(value)
                            end
                            if questXPBar then
                                questXPBar:SetStatusBarTexture(value)
                            end
                            if restedBar then
                                restedBar:SetStatusBarTexture(value)
                            end
                            if expTexturePreview then
                                BetterExpBar:UpdateTexturePreview(expTexturePreview, "exp")
                            end
                            BetterExpBar:UpdateExpBar()
                        end,
                        order = 8.1,
                        hidden = function() return self.db.profile.barStyle.barsLinked end,
                    },
                    repTexture = {
                        type = "select",
                        name = "REP Bar Texture",
                        desc = "Choose the texture used by the reputation bar.",
                        values = function()
                            return BetterExpBar:GetMediaOptions("statusbar", { ["Interface\\TargetingFrame\\UI-StatusBar"] = "Blizzard" })
                        end,
                        get = function() return self.db.profile.repBar.texture or "Interface\\TargetingFrame\\UI-StatusBar" end,
                        set = function(_, value)
                            self.db.profile.repBar.texture = value
                            if repBarInner then
                                repBarInner:SetStatusBarTexture(value)
                            end
                            if bonusRepBar then
                                bonusRepBar:SetStatusBarTexture(value)
                            end
                            if repTexturePreview then
                                BetterExpBar:UpdateTexturePreview(repTexturePreview, "rep")
                            end
                            BetterExpBar:UpdateRepBar()
                        end,
                        order = 8.2,
                        hidden = function() return self.db.profile.barStyle.barsLinked end,
                    },
                    linkedFontFace = {
                        type = "select",
                        name = "Font",
                        desc = "Choose font for both bars when linked",
                        values = function()
                            return BetterExpBar:GetMediaOptions("font", { ["Fonts\\FRIZQT__.TTF"] = "Friz Quadrata TT" })
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
                    barOrder = {
                        type = "select",
                        name = "Bar Order",
                        desc = "Choose which linked bar is shown on top; linked dimensions stay synchronized.",
                        values = {
                            ["exp"] = "Experience on Top",
                            ["rep"] = "Reputation on Top",
                        },
                        get = function() return self.db.profile.barStyle.barOrder or "exp" end,
                        set = function(_, value)
                            self.db.profile.barStyle.barOrder = value
                            if self.db.profile.barStyle.barsLinked then
                                BetterExpBar:SynchronizeBarDimensions()
                                BetterExpBar:UpdateLinkedBars()
                            end
                        end,
                        order = 19.4,
                        disabled = true,
                    },
                    lockingHeader = {
                        type = "header",
                        name = "Position Locking",
                        order = 20,
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
                        order = 21,
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
                        order = 22,
                    },
                    resetHeader = {
                        type = "header",
                        name = "Reset Options",
                        order = 23,
                    },
                    resetAll = {
                        type = "execute",
                        name = "Reset All to Defaults",
                        desc = "Reset all bars to their original appearance and settings",
                        func = function() BetterExpBar:ResetAll() end,
                        order = 24,
                    },
                },
            },
            experience = {
                name = "Experience",
                type = "group",
                order = 3,
                disabled = function() return self.db.profile.barStyle.barsLinked or BetterExpBar:IsMaxLevel() end,
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
                        disabled = function() return self.db.profile.barStyle.barsLinked or BetterExpBar:IsMaxLevel() end,
                    },
                    textFormat = {
                        type = "select",
                        name = "Text Display",
                        desc = "Choose what text to display on the experience bar",
                        values = {
                            ["percentage"] = "Percentage (%)",
                            ["none"] = "None",
                        },
                        disabled = function() return BetterExpBar:IsMaxLevel() end,
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
                        disabled = function() return BetterExpBar:IsMaxLevel() end,
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
                        disabled = function() return BetterExpBar:IsMaxLevel() end,
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
                        disabled = function() return BetterExpBar:IsMaxLevel() end,
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
                    previewHeader = {
                        type = "header",
                        name = "Live Preview",
                        order = 0.1,
                    },
                    previewInfo = {
                        type = "description",
                        name = "Use the buttons below to show EXP and REP preview panes. Drag each anchor directly on screen to set placement.",
                        order = 0.11,
                    },
                    previewStatus = {
                        type = "description",
                        name = function()
                            local cfg = self.db.profile.tooltipPreview
                            local expState = cfg.showExp and "|cFF00FF00ON|r" or "|cFFFF6633OFF|r"
                            local repState = cfg.showRep and "|cFF00FF00ON|r" or "|cFFFF6633OFF|r"
                            return "EXP Preview: " .. expState .. "   |   REP Preview: " .. repState
                        end,
                        order = 0.12,
                    },
                    previewControlsHeader = {
                        type = "header",
                        name = "Preview Visibility",
                        order = 0.15,
                    },
                    previewExp = {
                        type = "execute",
                        name = function()
                            if self.db.profile.tooltipPreview.showExp then
                                return "Hide EXP Preview"
                            end
                            return "Show EXP Preview"
                        end,
                        desc = "Toggle the Experience preview pane",
                        disabled = function() return BetterExpBar:IsMaxLevel() end,
                        func = function()
                            self.db.profile.tooltipPreview.showExp = not self.db.profile.tooltipPreview.showExp
                            self.db.profile.tooltipPreview.enabled = self.db.profile.tooltipPreview.showExp or self.db.profile.tooltipPreview.showRep
                            BetterExpBar:UpdateTooltipPreview()
                        end,
                        order = 0.2,
                    },
                    previewRep = {
                        type = "execute",
                        name = function()
                            if self.db.profile.tooltipPreview.showRep then
                                return "Hide REP Preview"
                            end
                            return "Show REP Preview"
                        end,
                        desc = "Toggle the Reputation preview pane",
                        func = function()
                            self.db.profile.tooltipPreview.showRep = not self.db.profile.tooltipPreview.showRep
                            self.db.profile.tooltipPreview.enabled = self.db.profile.tooltipPreview.showExp or self.db.profile.tooltipPreview.showRep
                            BetterExpBar:UpdateTooltipPreview()
                        end,
                        order = 0.3,
                    },
                    previewLayoutHeader = {
                        type = "header",
                        name = "Preview Placement",
                        order = 0.4,
                    },
                    resetPreviewPosition = {
                        type = "execute",
                        name = "Reset Preview Position",
                        desc = "Reset tooltip preview anchor to default location",
                        func = function()
                            BetterExpBar:ResetTooltipPositions()
                        end,
                        disabled = function() return not self.db.profile.tooltipPreview.enabled end,
                        order = 0.5,
                    },
                    previewColorNotice = {
                        type = "description",
                        name = "|cFF99CCFFLive preview uses the same Tooltip Style colors as the real tooltip.|r",
                        order = 0.6,
                    },
                    tooltipGeneralHeader = {
                        type = "header",
                        name = "Tooltip Behavior",
                        order = 0.9,
                    },
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
                    tooltipPositionHeader = {
                        type = "header",
                        name = "Tooltip Position Offsets",
                        order = 2.5,
                    },
                    expOffsetX = {
                        type = "range",
                        name = "EXP X Offset",
                        desc = "Horizontal offset for experience tooltip",
                        min = -300, max = 300, step = 1,
                        disabled = function() return BetterExpBar:IsMaxLevel() end,
                        get = function() return self.db.profile.tooltip.expOffsetX or 0 end,
                        set = function(_, value)
                            self.db.profile.tooltip.expOffsetX = value
                            BetterExpBar:UpdateTooltipPreview()
                        end,
                        order = 3,
                    },
                    expOffsetY = {
                        type = "range",
                        name = "EXP Y Offset",
                        desc = "Vertical offset for experience tooltip",
                        min = -100, max = 200, step = 1,
                        disabled = function() return BetterExpBar:IsMaxLevel() end,
                        get = function() return self.db.profile.tooltip.expOffsetY or self.db.profile.tooltip.offsetY or 10 end,
                        set = function(_, value)
                            self.db.profile.tooltip.expOffsetY = value
                            BetterExpBar:UpdateTooltipPreview()
                        end,
                        order = 3.1,
                    },
                    repOffsetX = {
                        type = "range",
                        name = "REP X Offset",
                        desc = "Horizontal offset for reputation tooltip",
                        min = -300, max = 300, step = 1,
                        get = function() return self.db.profile.tooltip.repOffsetX or 0 end,
                        set = function(_, value)
                            self.db.profile.tooltip.repOffsetX = value
                            BetterExpBar:UpdateTooltipPreview()
                        end,
                        order = 3.2,
                    },
                    repOffsetY = {
                        type = "range",
                        name = "REP Y Offset",
                        desc = "Vertical offset for reputation tooltip",
                        min = -100, max = 200, step = 1,
                        get = function() return self.db.profile.tooltip.repOffsetY or self.db.profile.tooltip.offsetY or 10 end,
                        set = function(_, value)
                            self.db.profile.tooltip.repOffsetY = value
                            BetterExpBar:UpdateTooltipPreview()
                        end,
                        order = 3.3,
                    },
                    tooltipStyleHeader = {
                        type = "header",
                        name = "Tooltip Style",
                        order = 3.8,
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
                                self.db.profile.expDisplay.useCommaFormat = false
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
                                self.db.profile.expDisplay.useCommaFormat = false
                            end
                            BetterExpBar:UpdateTooltipText()
                            BetterExpBar:UpdateRepTooltip()
                        end,
                        order = 7.7,
                    },
                    useCommaFormat = {
                        type = "toggle",
                        name = "Comma Separated",
                        desc = "Display numbers with comma separators (40,393). Disables other formats.",
                        get = function() return self.db.profile.expDisplay.useCommaFormat end,
                        set = function(_, value)
                            self.db.profile.expDisplay.useCommaFormat = value
                            if value then
                                self.db.profile.expDisplay.useCommon = false
                                self.db.profile.expDisplay.useVerbose = false
                            end
                            BetterExpBar:UpdateTooltipText()
                            BetterExpBar:UpdateRepTooltip()
                        end,
                        order = 7.8,
                    },
                    expTooltipHeader = {
                        type = "header",
                        name = "Experience Bar Tooltip",
                        order = 8.05,
                    },
                    expShowLevel = {
                        type = "toggle",
                        name = "Show Level",
                        desc = "Display character level in tooltip",
                        disabled = function() return BetterExpBar:IsMaxLevel() end,
                        get = function() return self.db.profile.tooltip.expTooltip.showLevel end,
                        set = function(_, value)
                            self.db.profile.tooltip.expTooltip.showLevel = value
                            BetterExpBar:UpdateTooltipText()
                        end,
                        order = 8.15,
                    },
                    expShowCurrent = {
                        type = "toggle",
                        name = "Show Current XP",
                        desc = "Display current experience points",
                        disabled = function() return BetterExpBar:IsMaxLevel() end,
                        get = function() return self.db.profile.tooltip.expTooltip.showCurrent end,
                        set = function(_, value)
                            self.db.profile.tooltip.expTooltip.showCurrent = value
                            BetterExpBar:UpdateTooltipText()
                        end,
                        order = 8.25,
                    },
                    expShowRested = {
                        type = "toggle",
                        name = "Show Rested XP",
                        desc = "Display rested experience points",
                        disabled = function() return BetterExpBar:IsMaxLevel() end,
                        get = function() return self.db.profile.tooltip.expTooltip.showRested end,
                        set = function(_, value)
                            self.db.profile.tooltip.expTooltip.showRested = value
                            BetterExpBar:UpdateTooltipText()
                        end,
                        order = 8.35,
                    },
                    expShowRemaining = {
                        type = "toggle",
                        name = "Show Remaining XP",
                        desc = "Display experience needed to next level",
                        disabled = function() return BetterExpBar:IsMaxLevel() end,
                        get = function() return self.db.profile.tooltip.expTooltip.showRemaining end,
                        set = function(_, value)
                            self.db.profile.tooltip.expTooltip.showRemaining = value
                            BetterExpBar:UpdateTooltipText()
                        end,
                        order = 8.45,
                    },
                    expShowPercentage = {
                        type = "toggle",
                        name = "Show Percentage",
                        desc = "Display progress percentage",
                        disabled = function() return BetterExpBar:IsMaxLevel() end,
                        get = function() return self.db.profile.tooltip.expTooltip.showPercentage end,
                        set = function(_, value)
                            self.db.profile.tooltip.expTooltip.showPercentage = value
                            BetterExpBar:UpdateTooltipText()
                        end,
                        order = 8.55,
                    },
                    nitExpHeader = {
                        type = "header",
                        name = "NovaInstanceTracker XP Stats (Optional)",
                        hidden = function() return not BetterExpBar:IsNITAvailable() end,
                        order = 10,
                    },
                    nitExpNotice = {
                        type = "description",
                        name = "|cffff0000NovaInstanceTracker is not loaded. Features below disabled. Stats will fall back to session tracking.|r",
                        hidden = function() return BetterExpBar:IsNITAvailable() end,
                        order = 10.05,
                    },
                    expShowXpPerHour = {
                        type = "toggle",
                        name = "Show XP Per Hour",
                        desc = "Display XP gained per hour",
                        disabled = function() return BetterExpBar:IsMaxLevel() or not BetterExpBar:IsNITAvailable() end,
                        get = function() return self.db.profile.tooltip.expTooltip.showXpPerHour end,
                        set = function(_, value)
                            self.db.profile.tooltip.expTooltip.showXpPerHour = value
                            BetterExpBar:UpdateTooltipText()
                        end,
                        order = 10.1,
                    },
                    expShowXpPerHourPercent = {
                        type = "toggle",
                        name = "Show XP Per Hour (%)",
                        desc = "Display XP per hour as percentage of level",
                        disabled = function() return BetterExpBar:IsMaxLevel() or not BetterExpBar:IsNITAvailable() or not self.db.profile.tooltip.expTooltip.showXpPerHour end,
                        get = function() return self.db.profile.tooltip.expTooltip.showXpPerHourPercent end,
                        set = function(_, value)
                            self.db.profile.tooltip.expTooltip.showXpPerHourPercent = value
                            BetterExpBar:UpdateTooltipText()
                        end,
                        order = 10.11,
                    },
                    expShowXpFromLastInstance = {
                        type = "toggle",
                        name = "Show XP From Last Instance",
                        desc = "Display XP gained from the last instance",
                        disabled = function() return BetterExpBar:IsMaxLevel() or not BetterExpBar:IsNITAvailable() end,
                        get = function() return self.db.profile.tooltip.expTooltip.showXpFromLastInstance end,
                        set = function(_, value)
                            self.db.profile.tooltip.expTooltip.showXpFromLastInstance = value
                            BetterExpBar:UpdateTooltipText()
                        end,
                        order = 10.2,
                    },
                    expShowXpFromLastInstancePercent = {
                        type = "toggle",
                        name = "Show Instance XP (%)",
                        desc = "Display instance XP as percentage of level",
                        disabled = function() return BetterExpBar:IsMaxLevel() or not BetterExpBar:IsNITAvailable() or not self.db.profile.tooltip.expTooltip.showXpFromLastInstance end,
                        get = function() return self.db.profile.tooltip.expTooltip.showXpFromLastInstancePercent end,
                        set = function(_, value)
                            self.db.profile.tooltip.expTooltip.showXpFromLastInstancePercent = value
                            BetterExpBar:UpdateTooltipText()
                        end,
                        order = 10.21,
                    },
                    expShowXpTodayTotal = {
                        type = "toggle",
                        name = "Show Today's Total XP",
                        desc = "Display total XP gained today",
                        disabled = function() return BetterExpBar:IsMaxLevel() or not BetterExpBar:IsNITAvailable() end,
                        get = function() return self.db.profile.tooltip.expTooltip.showXpTodayTotal end,
                        set = function(_, value)
                            self.db.profile.tooltip.expTooltip.showXpTodayTotal = value
                            BetterExpBar:UpdateTooltipText()
                        end,
                        order = 10.3,
                    },
                    expShowXpTodayTotalPercent = {
                        type = "toggle",
                        name = "Show Today Total XP (%)",
                        desc = "Display today's total XP as percentage of level",
                        disabled = function() return BetterExpBar:IsMaxLevel() or not BetterExpBar:IsNITAvailable() or not self.db.profile.tooltip.expTooltip.showXpTodayTotal end,
                        get = function() return self.db.profile.tooltip.expTooltip.showXpTodayTotalPercent end,
                        set = function(_, value)
                            self.db.profile.tooltip.expTooltip.showXpTodayTotalPercent = value
                            BetterExpBar:UpdateTooltipText()
                        end,
                        order = 10.31,
                    },
                    repTooltipHeader = {
                        type = "header",
                        name = "Reputation Bar Tooltip",
                        order = 9,
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
                        order = 9.1,
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
                        order = 9.2,
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
                        order = 9.3,
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
                        order = 9.4,
                    },
                    nitRepHeader = {
                        type = "header",
                        name = "NovaInstanceTracker Rep Stats (Optional)",
                        hidden = function() return not BetterExpBar:IsNITAvailable() end,
                        order = 11,
                    },
                    nitRepNotice = {
                        type = "description",
                        name = "|cffff0000NovaInstanceTracker is not loaded. Features below disabled. Stats will fall back to session tracking.|r",
                        hidden = function() return BetterExpBar:IsNITAvailable() end,
                        order = 11.05,
                    },
                    repShowRepPerHour = {
                        type = "toggle",
                        name = "Show Rep Per Hour",
                        desc = "Display reputation gained per hour",
                        disabled = function() return not BetterExpBar:IsNITAvailable() end,
                        get = function() return self.db.profile.tooltip.repTooltip.showRepPerHour end,
                        set = function(_, value)
                            self.db.profile.tooltip.repTooltip.showRepPerHour = value
                            BetterExpBar:UpdateRepTooltip()
                        end,
                        order = 11.1,
                    },
                    repShowRepPerHourPercent = {
                        type = "toggle",
                        name = "Show Rep Per Hour (%)",
                        desc = "Display rep per hour as percentage of rep to standing",
                        disabled = function() return not BetterExpBar:IsNITAvailable() or not self.db.profile.tooltip.repTooltip.showRepPerHour end,
                        get = function() return self.db.profile.tooltip.repTooltip.showRepPerHourPercent end,
                        set = function(_, value)
                            self.db.profile.tooltip.repTooltip.showRepPerHourPercent = value
                            BetterExpBar:UpdateRepTooltip()
                        end,
                        order = 11.11,
                    },
                    repShowRepFromLastInstance = {
                        type = "toggle",
                        name = "Show Rep From Last Instance",
                        desc = "Display reputation gained from the last instance",
                        disabled = function() return not BetterExpBar:IsNITAvailable() end,
                        get = function() return self.db.profile.tooltip.repTooltip.showRepFromLastInstance end,
                        set = function(_, value)
                            self.db.profile.tooltip.repTooltip.showRepFromLastInstance = value
                            BetterExpBar:UpdateRepTooltip()
                        end,
                        order = 11.2,
                    },
                    repShowRepFromLastInstancePercent = {
                        type = "toggle",
                        name = "Show Instance Rep (%)",
                        desc = "Display instance rep as percentage of rep to standing",
                        disabled = function() return not BetterExpBar:IsNITAvailable() or not self.db.profile.tooltip.repTooltip.showRepFromLastInstance end,
                        get = function() return self.db.profile.tooltip.repTooltip.showRepFromLastInstancePercent end,
                        set = function(_, value)
                            self.db.profile.tooltip.repTooltip.showRepFromLastInstancePercent = value
                            BetterExpBar:UpdateRepTooltip()
                        end,
                        order = 11.21,
                    },
                    repShowRepTodayTotal = {
                        type = "toggle",
                        name = "Show Today's Total Rep",
                        desc = "Display total reputation gained today",
                        disabled = function() return not BetterExpBar:IsNITAvailable() end,
                        get = function() return self.db.profile.tooltip.repTooltip.showRepTodayTotal end,
                        set = function(_, value)
                            self.db.profile.tooltip.repTooltip.showRepTodayTotal = value
                            BetterExpBar:UpdateRepTooltip()
                        end,
                        order = 11.3,
                    },
                    repShowRepTodayTotalPercent = {
                        type = "toggle",
                        name = "Show Today Total Rep (%)",
                        desc = "Display today's total rep as percentage of rep to standing",
                        disabled = function() return not BetterExpBar:IsNITAvailable() or not self.db.profile.tooltip.repTooltip.showRepTodayTotal end,
                        get = function() return self.db.profile.tooltip.repTooltip.showRepTodayTotalPercent end,
                        set = function(_, value)
                            self.db.profile.tooltip.repTooltip.showRepTodayTotalPercent = value
                            BetterExpBar:UpdateRepTooltip()
                        end,
                        order = 11.31,
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
                        name = "|cFF00FF00Better Experience Bars|r\n\n|cFFFFFFFFVersion:|r 3.0.5\n|cFFFFFFFFAuthor:|r Pegga\n\n|cFFFFFFFFDescription:|r\nMoveable experience and reputation bars for WoW with customizable colors, styles, and detailed tooltip options.\n\n|cFFFFFFFFFeatures:|r\n• Customizable moveable EXP and REP bars\n• Per-character saved settings with AceDB\n• Advanced tooltip configuration\n• Number formatting (abbreviations, verbose, comma-separated)\n• Bar styling (texture, color, opacity, scale)\n• Minimap button support\n• Optional NovaInstanceTracker integration for session stats\n\n|cFFFFFFFFLibraries:|r\n• Ace3 Framework\n• LibDataBroker-1.1\n• LibDBIcon-1.0\n\n|cFFFFFFFFOptional Dependencies:|r\n• NovaInstanceTracker - For advanced instance tracking stats\n• Questie for XP estimate from Quests \n• WeakAuras & Details for textures/fonts \n\n To open options\n• Right-click your bars. \n• Minimap Button \n• Type /beb for a list of commands.",
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
