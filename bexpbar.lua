local expBarContainer = CreateFrame("Frame", "CustomExpBarContainer", UIParent, "BackdropTemplate")
expBarContainer:SetSize(1024, 20)
expBarContainer:SetPoint("TOP", UIParent, "TOP", 0, -50)
expBarContainer:SetBackdropColor(0, 0, 0, 0.8)
expBarContainer:SetBackdropBorderColor(0, 0, 0)
expBarContainer:SetFrameLevel(1)
expBarContainer:Show()

local bexpbarDB = bexpbarDB or {}

local function SaveFramePosition(frame)
    local point, _, relativePoint, xOfs, yOfs = frame:GetPoint()
    bexpbarDB.point = point
    bexpbarDB.relativePoint = relativePoint
    bexpbarDB.xOfs = xOfs
    bexpbarDB.yOfs = yOfs
    bexpbarDB.width = frame:GetWidth()
    bexpbarDB.height = frame:GetHeight()
end

local function RestoreFramePosition(frame)
    if bexpbarDB.point and bexpbarDB.relativePoint and bexpbarDB.xOfs and bexpbarDB.yOfs then
        frame:ClearAllPoints()
        frame:SetPoint(bexpbarDB.point, UIParent, bexpbarDB.relativePoint, bexpbarDB.xOfs, bexpbarDB.yOfs)
    else
        frame:ClearAllPoints()
    end
    if bexpbarDB.width and bexpbarDB.height then
        frame:SetSize(bexpbarDB.width, bexpbarDB.height)
    end
end

expBarContainer:EnableMouse(true)
expBarContainer:SetMovable(true)
expBarContainer:RegisterForDrag("LeftButton")
expBarContainer:SetScript("OnDragStart", function(self) self:StartMoving() end)
expBarContainer:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    SaveFramePosition(self)
end)

local largerFrame = CreateFrame("Frame", "LargerExpBarFrame", UIParent, "BackdropTemplate")
largerFrame:SetSize(1034, 30)
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
    SaveFramePosition(self)
    expBarContainer:ClearAllPoints()
    expBarContainer:SetPoint("CENTER", self, "CENTER", 0, 0)
end)

local expBarFrame = CreateFrame("StatusBar", "CustomExpBar", largerFrame, "TextStatusBar, BackdropTemplate")
expBarFrame:SetSize(1024, 20)
expBarFrame:SetPoint("CENTER", largerFrame, "CENTER", 0, 0)
expBarFrame:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
expBarFrame:SetStatusBarColor(0, 1, 0)
expBarFrame:SetAlpha(0.8)
expBarFrame:SetFrameLevel(2)
expBarFrame:Show()

local restedBar = CreateFrame("StatusBar", nil, expBarFrame)
restedBar:SetAllPoints(expBarFrame)
restedBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
restedBar:SetStatusBarColor(0, 0.39, 0.88, 0.5)
restedBar:SetFrameLevel(1)
restedBar:Show()

local expText = expBarFrame:CreateFontString(nil, "OVERLAY")
expText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
expText:SetPoint("CENTER", expBarFrame, "CENTER", 0, 0)

local function UpdateLargerFrame()
    largerFrame:SetSize(expBarContainer:GetWidth() + 10, expBarContainer:GetHeight() + 10)
end

expBarContainer:HookScript("OnSizeChanged", UpdateLargerFrame)

local function UpdateExpBar()
    local currentXP = UnitXP("player")
    local maxXP = UnitXPMax("player")
    local restedXP = GetXPExhaustion() or 0

    expBarFrame:SetMinMaxValues(0, maxXP)
    expBarFrame:SetValue(currentXP)
    restedBar:SetMinMaxValues(0, maxXP)
    restedBar:SetValue(math.min(currentXP + restedXP, maxXP))
    expText:SetText(string.format("%d%%", (currentXP / maxXP) * 100))
end

local function HideDefaultExpBar()
    if MainMenuBar and MainMenuBar.ExpBar then
        MainMenuBar.ExpBar:Hide()
        MainMenuBar.ExpBar:UnregisterAllEvents()
    end
    if ReputationWatchBar then
        ReputationWatchBar:Hide()
        ReputationWatchBar:UnregisterAllEvents()
    end
end

expBarFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
expBarFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        HideDefaultExpBar()
        RestoreFramePosition(largerFrame)
        RestoreFramePosition(expBarContainer)
    end
    UpdateExpBar()
end)

UpdateExpBar()

largerFrame:HookScript("OnSizeChanged", function(self)
    local newWidth = math.max(self:GetWidth() - 10, 10)
    local newHeight = math.max(self:GetHeight() - 10, 5)
    expBarContainer:SetSize(newWidth, newHeight)
    expBarFrame:SetSize(newWidth, newHeight)
    UpdateExpBar()
end)

largerFrame:SetResizable(true)

