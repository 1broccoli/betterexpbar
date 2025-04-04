-- Addon namespace
local addonName, addonTable = ...

local expBarContainer = CreateFrame("Frame", "CustomExpBarContainer", UIParent, "BackdropTemplate")
expBarContainer:SetSize(1024, 20)
expBarContainer:SetPoint("TOP", UIParent, "TOP", 0, -50)
expBarContainer:SetBackdropColor(0, 0, 0, 0.8)
expBarContainer:SetBackdropBorderColor(0, 0, 0)
expBarContainer:SetFrameLevel(1)
expBarContainer:Show()

local bexpbarDB = bexpbarDB or {}
bexpbarDB.isDisabled = bexpbarDB.isDisabled or false

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
        -- Fallback to default position
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
end)

-- Add the resize handle here
local resizeHandle = CreateFrame("Frame", nil, largerFrame)
resizeHandle:SetSize(8, 8)
resizeHandle:SetPoint("BOTTOMRIGHT", largerFrame, "BOTTOMRIGHT", 0, 0)
resizeHandle:EnableMouse(true)
resizeHandle.texture = resizeHandle:CreateTexture(nil, "OVERLAY")
resizeHandle.texture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resizeHandle.texture:SetSize(8, 8) -- Set the texture size to 8x8
resizeHandle.texture:SetPoint("CENTER", resizeHandle, "CENTER") -- Center the texture within the frame
resizeHandle:SetScript("OnEnter", function(self)
    self.texture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
end)
resizeHandle:SetScript("OnLeave", function(self)
    self.texture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
end)
resizeHandle:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        largerFrame:StartSizing("BOTTOMRIGHT") -- Start resizing from the bottom-right corner

        -- Add an OnUpdate handler to enforce size limits in real-time
        largerFrame:SetScript("OnUpdate", function(self)
            local currentWidth = self:GetWidth()
            local currentHeight = self:GetHeight()

            -- Enforce minimum and maximum width
            if currentWidth < 40 then
                self:SetWidth(40) -- Minimum width
            elseif currentWidth > 1500 then
                self:SetWidth(1500) -- Maximum width
            end

            -- Enforce minimum and maximum height
            if currentHeight < 20 then
                self:SetHeight(20) -- Minimum height
            elseif currentHeight > 200 then
                self:SetHeight(200) -- Maximum height
            end
        end)
    end
end)
resizeHandle:SetScript("OnMouseUp", function(self)
    self.texture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    largerFrame:StopMovingOrSizing() -- Stop resizing
    largerFrame:SetScript("OnUpdate", nil) -- Remove the OnUpdate handler
    SaveFramePosition(largerFrame) -- Save the new size and position
end)

local expBarFrame = CreateFrame("StatusBar", "CustomExpBar", largerFrame, "TextStatusBar, BackdropTemplate")
expBarFrame:SetSize(1024, 20)
expBarFrame:SetPoint("CENTER", largerFrame, "CENTER", 0, 0)
expBarFrame:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
expBarFrame:SetStatusBarColor(0.58, 0, 0.55) -- Purple color (RGB: 148, 0, 140)
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
    if not largerFrame.isResizing then
        largerFrame.isResizing = true
        largerFrame:SetSize(expBarContainer:GetWidth() + 10, expBarContainer:GetHeight() + 10)
        largerFrame.isResizing = false
    end
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
    
    -- Prevent division by zero
    if maxXP > 0 then
        expText:SetText(string.format("%d%%", (currentXP / maxXP) * 100))
    else
        expText:SetText("0%")
    end
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

local function CreateLevelCapPopup()
    local popupFrame = CreateFrame("Frame", "LevelCapPopup", UIParent, "BackdropTemplate")
    popupFrame:SetSize(300, 100)
    popupFrame:SetPoint("CENTER", UIParent, "CENTER")
    popupFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 16,
    })
    popupFrame:SetBackdropColor(0, 0, 0, 0.8)
    popupFrame:SetBackdropBorderColor(1, 1, 1, 1)
    popupFrame:Hide()

    -- Add a congratulatory message
    local text = popupFrame:CreateFontString(nil, "OVERLAY")
    text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    text:SetPoint("CENTER", popupFrame, "CENTER", 0, 10)
    text:SetText("Congratulations! You are now max level.\nClick below to disable the experience bar.")

    -- Add a single button to disable the addon
    local disableButton = CreateFrame("Button", nil, popupFrame, "UIPanelButtonTemplate")
    disableButton:SetSize(120, 30)
    disableButton:SetPoint("BOTTOM", popupFrame, "BOTTOM", 0, 10)
    disableButton:SetText("Disable")
    disableButton:SetScript("OnClick", function()
        -- Hide the experience bar and disable the addon
        expBarContainer:Hide()
        largerFrame:Hide()
        expBarFrame:UnregisterAllEvents()
        popupFrame:Hide()

        -- Save the disabled state
        bexpbarDB.isDisabled = true
        DisableAddOn(addonName)
        print("Experience bar has been disabled.")
    end)

    return popupFrame
end

local levelCapPopup = CreateLevelCapPopup()

local function CheckLevelCap()
    local playerLevel = UnitLevel("player")
    local maxLevel = MAX_PLAYER_LEVEL_TABLE[GetExpansionLevel()] -- Retrieves the maximum level for the current expansion
    if playerLevel >= maxLevel then
        levelCapPopup:Show()
    else
        levelCapPopup:Hide()
    end
end

expBarFrame:RegisterEvent("PLAYER_XP_UPDATE")
expBarFrame:RegisterEvent("PLAYER_LEVEL_UP")
expBarFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
expBarFrame:RegisterEvent("PLAYER_LOGOUT") -- Register the logout event
expBarFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        -- Check if the addon is disabled
        if bexpbarDB.isDisabled then
            expBarContainer:Hide()
            largerFrame:Hide()
            expBarFrame:UnregisterAllEvents()
            print("Experience bar is disabled.")
            return -- Skip further initialization
        end

        -- Initialize the addon
        HideDefaultExpBar()
        RestoreFramePosition(largerFrame)
        RestoreFramePosition(expBarContainer)
    end

    if event == "PLAYER_LEVEL_UP" or event == "PLAYER_ENTERING_WORLD" then
        CheckLevelCap()
    end

    if event == "PLAYER_LOGOUT" then
        SaveFramePosition(largerFrame)
        SaveFramePosition(expBarContainer)
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

-- Define a slash command to reset the position of the frames
SLASH_RESETEXPBAR1 = "/resetexpbar"
SlashCmdList["RESETEXPBAR"] = function()
    -- Reset the position of the largerFrame
    largerFrame:ClearAllPoints()
    largerFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    bexpbarDB.point = "CENTER"
    bexpbarDB.relativePoint = "CENTER"
    bexpbarDB.xOfs = 0
    bexpbarDB.yOfs = 0

    -- Reset the position of the expBarContainer
    expBarContainer:ClearAllPoints()
    expBarContainer:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    bexpbarDB.expBarPoint = "CENTER"
    bexpbarDB.expBarRelativePoint = "CENTER"
    bexpbarDB.expBarXOfs = 0
    bexpbarDB.expBarYOfs = 0

    -- Save the reset position
    SaveFramePosition(largerFrame)
    SaveFramePosition(expBarContainer)

    print("Experience bar position has been reset to the center.")
end

SLASH_ENABLEEXPBAR1 = "/enableexpbar"
SlashCmdList["ENABLEEXPBAR"] = function()
    bexpbarDB.isDisabled = false
    ReloadUI() -- Reload the UI to reinitialize the addon
end

-- Blizzard-style dialog box to act as a tooltip
local tooltipFrame = CreateFrame("Frame", "ExpBarTooltipFrame", UIParent, "BackdropTemplate")
tooltipFrame:SetSize(200, 100)
tooltipFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    edgeSize = 10,
})
tooltipFrame:SetBackdropColor(0, 0, 0, 0.8)
tooltipFrame:SetBackdropBorderColor(1, 1, 1, 1)
tooltipFrame:SetPoint("BOTTOM", expBarFrame, "TOP", 0, 10)
tooltipFrame:SetFrameStrata("TOOLTIP") -- Set the frame strata higher
tooltipFrame:Hide()

local tooltipText = tooltipFrame:CreateFontString(nil, "OVERLAY")
tooltipText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
tooltipText:SetPoint("TOPLEFT", tooltipFrame, "TOPLEFT", 10, -10)
tooltipText:SetJustifyH("LEFT")
tooltipText:SetJustifyV("TOP")
tooltipText:SetText("")

local function FormatNumber(number)
    return tostring(number)
end

expBarFrame:SetScript("OnEnter", function(self)
    local currentXP = UnitXP and UnitXP("player") or 0
    local maxXP = UnitXPMax and UnitXPMax("player") or 1 -- Avoid division by zero
    local restedXP = GetXPExhaustion and (GetXPExhaustion() or 0) or 0
    local remainingXP = maxXP - currentXP
    local playerLevel = UnitLevel("player") or 0

    tooltipText:SetText(string.format(
        "Level: |cff00ff00%d|r\nCurrent: %s / %s\nRested: |cff3399ff+%s|r\nRemaining: |cffa335ee%s|r",
        playerLevel,
        "|cffffff00" .. FormatNumber(currentXP) .. "|r",
        FormatNumber(maxXP),
        FormatNumber(restedXP),
        FormatNumber(remainingXP)
    ))

    tooltipFrame:SetSize(tooltipText:GetStringWidth() + 20, tooltipText:GetStringHeight() + 20)
    tooltipFrame:Show()
end)

expBarFrame:SetScript("OnLeave", function(self)
    tooltipFrame:Hide()
end)

-- Define the base slash command
SLASH_BEB1 = "/beb"
SlashCmdList["BEB"] = function(msg)
    local command = string.lower(msg) -- Convert the command to lowercase for case-insensitivity

    if command == "reset" then
        -- Reset the position of the largerFrame
        largerFrame:ClearAllPoints()
        largerFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        bexpbarDB.point = "CENTER"
        bexpbarDB.relativePoint = "CENTER"
        bexpbarDB.xOfs = 0
        bexpbarDB.yOfs = 0

        -- Reset the position of the expBarContainer
        expBarContainer:ClearAllPoints()
        expBarContainer:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        bexpbarDB.expBarPoint = "CENTER"
        bexpbarDB.expBarRelativePoint = "CENTER"
        bexpbarDB.expBarXOfs = 0
        bexpbarDB.expBarYOfs = 0

        -- Save the reset position
        SaveFramePosition(largerFrame)
        SaveFramePosition(expBarContainer)

        print("Experience bar position has been reset to the center.")

    elseif command == "enable" then
        -- Enable the addon
        bexpbarDB.isDisabled = false
        ReloadUI() -- Reload the UI to reinitialize the addon
        print("Experience bar has been enabled. Reloading UI...")

    elseif command == "disable" then
        -- Disable the addon
        bexpbarDB.isDisabled = true
        expBarContainer:Hide()
        largerFrame:Hide()
        expBarFrame:UnregisterAllEvents()
        print("Experience bar has been disabled.")

    else
        -- Print usage instructions
        print("Usage:")
        print("/beb reset - Reset the position of the experience bar to the center.")
        print("/beb enable - Enable the experience bar.")
        print("/beb disable - Disable the experience bar.")
    end
end
