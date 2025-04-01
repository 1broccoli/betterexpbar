-- Create the main frame for the experience bar
local expBarContainer = CreateFrame("Frame", "CustomExpBarContainer", UIParent, "BackdropTemplate")
expBarContainer:SetSize(1024, 20)
expBarContainer:SetPoint("TOP", UIParent, "TOP", 0, -50)

expBarContainer:SetBackdropColor(0, 0, 0, 0.8)
expBarContainer:SetBackdropBorderColor(0, 0, 0)
expBarContainer:SetFrameLevel(1) -- Ensure the container is behind the bars

-- Ensure the container and bars are visible
expBarContainer:Show()

-- Table to store the frame's position in a saved variable
local bexpbarDB = bexpbarDB or {}

-- Function to save the frame's position to the saved variable
local function SaveFramePosition(frame)
    local point, _, relativePoint, xOfs, yOfs = frame:GetPoint()
    bexpbarDB.point = point
    bexpbarDB.relativePoint = relativePoint
    bexpbarDB.xOfs = xOfs
    bexpbarDB.yOfs = yOfs

    -- Save the size of the frame
    bexpbarDB.width = frame:GetWidth()
    bexpbarDB.height = frame:GetHeight()
end

-- Function to restore the frame's position from the saved variable
local function RestoreFramePosition(frame)
    if bexpbarDB.point and bexpbarDB.relativePoint and bexpbarDB.xOfs and bexpbarDB.yOfs then
        frame:ClearAllPoints()
        frame:SetPoint(bexpbarDB.point, UIParent, bexpbarDB.relativePoint, bexpbarDB.xOfs, bexpbarDB.yOfs)
    else
        -- Fallback to default position if saved position is invalid
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end

    -- Restore the size of the frame
    if bexpbarDB.width and bexpbarDB.height then
        frame:SetSize(bexpbarDB.width, bexpbarDB.height)
    end
end

-- Enable mouse interaction for moving the bar
expBarContainer:EnableMouse(true)
expBarContainer:SetMovable(true)
expBarContainer:RegisterForDrag("LeftButton")
expBarContainer:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)
expBarContainer:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    SaveFramePosition(self) -- Save the frame's position after moving
    largerFrame:ClearAllPoints()
    largerFrame:SetPoint("CENTER", self, "CENTER", 0, 0) -- Align largerFrame to expBarContainer
end)

-- Restore the frame's position on load
RestoreFramePosition(expBarContainer)

-- Create the larger frame that will now contain the experience bar
local largerFrame = CreateFrame("Frame", "LargerExpBarFrame", UIParent, "BackdropTemplate")
largerFrame:SetSize(1024 + 10, 20 + 10) -- Adjust size to include padding
largerFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
largerFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    edgeSize = 16,
})
largerFrame:SetBackdropColor(0, 0, 0, 0.5) -- Adjust transparency
largerFrame:SetBackdropBorderColor(1, 1, 1, 1)
largerFrame:SetFrameLevel(1) -- Ensure it is behind the bars
largerFrame:EnableMouse(true)
largerFrame:SetMovable(true)
largerFrame:RegisterForDrag("LeftButton")
largerFrame:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)
largerFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    SaveFramePosition(self) -- Save the frame's position after moving
    expBarContainer:ClearAllPoints()
    expBarContainer:SetPoint("CENTER", self, "CENTER", 0, 0) -- Align expBarContainer to largerFrame
end)
RestoreFramePosition(largerFrame)

-- Move the experience bar into the larger frame
local expBarFrame = CreateFrame("StatusBar", "CustomExpBar", largerFrame, "TextStatusBar, BackdropTemplate")
expBarFrame:SetSize(largerFrame:GetWidth() - 10, largerFrame:GetHeight() - 10) -- Adjust size to fit within the larger frame
expBarFrame:SetPoint("CENTER", largerFrame, "CENTER", 0, 0)
expBarFrame:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
expBarFrame:GetStatusBarTexture():SetHorizTile(false)
expBarFrame:GetStatusBarTexture():SetVertTile(false)
expBarFrame:SetStatusBarColor(0, 1, 0) -- Green for experience
expBarFrame:SetAlpha(0.8)
expBarFrame:SetFrameLevel(2) -- Ensure it is above the larger frame
expBarFrame:Show()

-- Move the rested experience bar into the larger frame
local restedBar = CreateFrame("StatusBar", nil, expBarFrame)
restedBar:SetAllPoints(expBarFrame)
restedBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
restedBar:GetStatusBarTexture():SetHorizTile(false)
restedBar:GetStatusBarTexture():SetVertTile(false)
restedBar:SetStatusBarColor(0, 0.39, 0.88, 0.5) -- Blue for rested experience
restedBar:SetFrameLevel(1) -- Ensure it is below the experience bar
restedBar:Show()

-- Move the experience percentage text into the larger frame
local expText = expBarFrame:CreateFontString(nil, "OVERLAY")
expText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
expText:SetPoint("CENTER", expBarFrame, "CENTER", 0, 0)

-- Update the size and position of the larger frame
local function UpdateLargerFrame()
    largerFrame:SetSize(expBarContainer:GetWidth() + 10, expBarContainer:GetHeight() + 10)
    largerFrame:ClearAllPoints()
    largerFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0) -- Anchor to UIParent to avoid circular dependency
end

-- Hook the experience bar container's size changes to update the larger frame
expBarContainer:HookScript("OnSizeChanged", UpdateLargerFrame)

-- Update the experience bar and rested bar values
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

-- Function to hide the default Blizzard experience bar
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

-- Register events to update the experience bar and hide the default Blizzard experience bar
expBarFrame:RegisterEvent("PLAYER_XP_UPDATE")
expBarFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
expBarFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        HideDefaultExpBar()
        RestoreFramePosition(expBarContainer) -- Ensure position is restored on entering the world
    end
    UpdateExpBar()
end)

-- Initial update
UpdateExpBar()

-- Tooltip handling
expBarFrame:EnableMouse(true)
expBarFrame:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(string.format("Experience:\n%d / %d (%d%%)", UnitXP("player"), UnitXPMax("player"), (UnitXP("player") / UnitXPMax("player")) * 100), nil, nil, nil, nil, true)
    GameTooltip:Show()
end)
expBarFrame:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)

-- Debugging: Print frame size and position to verify
print("ExpBarContainer Size:", expBarContainer:GetWidth(), expBarContainer:GetHeight())
print("ExpBarContainer Position:", expBarContainer:GetPoint())

-- Remove the undefined function call
-- Initial update for the text
-- UpdateLargerFrameText()

-- Update the CustomExpBarContainer to always follow the LargerExpBarFrame
expBarContainer:ClearAllPoints()
expBarContainer:SetPoint("CENTER", largerFrame, "CENTER", 0, 0)

-- Remove circular dependency when dragging largerFrame
largerFrame:HookScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    SaveFramePosition(self) -- Save the frame's position after moving
    expBarContainer:ClearAllPoints()
    expBarContainer:SetPoint("CENTER", self, "CENTER", 0, 0)
end)

-- Ensure the larger frame is movable and updates its position
largerFrame:EnableMouse(true)
largerFrame:SetMovable(true)
largerFrame:RegisterForDrag("LeftButton")
largerFrame:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)
largerFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    SaveFramePosition(self) -- Save the frame's position after moving
end)

-- Restore the larger frame's position on load
RestoreFramePosition(largerFrame)

-- Ensure the larger frame is visible
largerFrame:Show()

-- Function to set the scale of both frames and align them
local function SetFrameScale(scale)
    if scale < 1 or scale > 100 then
        print("Scale must be between 1 and 100.")
        return
    end

    local normalizedScale = scale / 100
    expBarContainer:SetScale(normalizedScale)
    largerFrame:SetScale(normalizedScale)

    -- Re-align the frames to ensure they stay together
    expBarContainer:ClearAllPoints()
    expBarContainer:SetPoint("CENTER", largerFrame, "CENTER", 0, 0)
end

-- Function to set the height of both frames
local function SetFrameHeight(height)
    if height < 1 or height > 1000 then
        print("Height must be between 1 and 1000.")
        return
    end

    expBarContainer:SetHeight(height)
    largerFrame:SetHeight(height + 10) -- Include padding for the larger frame
    expBarFrame:SetHeight(height)
end

-- Function to set the width of both frames
local function SetFrameWidth(width)
    if width < 1 or width > 1000 then
        print("Width must be between 1 and 1000.")
        return
    end

    expBarContainer:SetWidth(width)
    largerFrame:SetWidth(width + 10) -- Include padding for the larger frame
    expBarFrame:SetWidth(width)
end

-- Function to set the font size of the text
local function SetTextSize(size)
    if size < 1 or size > 100 then
        print("Text size must be between 1 and 100.")
        return
    end

    expText:SetFont("Fonts\\FRIZQT__.TTF", size, "OUTLINE")
end
-- Enable mouse interaction for the experience bar (expBarFrame)
expBarFrame:EnableMouse(true)
expBarFrame:RegisterForDrag("LeftButton")
expBarFrame:SetScript("OnDragStart", function(self)
    -- Start moving the parent frame (largerFrame)
    largerFrame:StartMoving()
end)
expBarFrame:SetScript("OnDragStop", function(self)
    -- Stop moving the parent frame (largerFrame)
    largerFrame:StopMovingOrSizing()
    SaveFramePosition(largerFrame) -- Save the position of the larger frame
    expBarContainer:ClearAllPoints()
    expBarContainer:SetPoint("CENTER", largerFrame, "CENTER", 0, 0) -- Align expBarContainer to largerFrame
end)

-- Enable mouse interaction for the rested bar (restedBar)
restedBar:EnableMouse(true)
restedBar:RegisterForDrag("LeftButton")
restedBar:SetScript("OnDragStart", function(self)
    -- Start moving the parent frame (largerFrame)
    largerFrame:StartMoving()
end)
restedBar:SetScript("OnDragStop", function(self)
    -- Stop moving the parent frame (largerFrame)
    largerFrame:StopMovingOrSizing()
    SaveFramePosition(largerFrame) -- Save the position of the larger frame
    expBarContainer:ClearAllPoints()
    expBarContainer:SetPoint("CENTER", largerFrame, "CENTER", 0, 0) -- Align expBarContainer to largerFrame
end)

-- Enable mouse interaction for the tooltip
expBarFrame:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(string.format("Experience:\n%d / %d (%d%%)", UnitXP("player"), UnitXPMax("player"), (UnitXP("player") / UnitXPMax("player")) * 100), nil, nil, nil, nil, true)
    GameTooltip:Show()
end)
expBarFrame:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)

-- Allow dragging the frame while the tooltip is visible
expBarFrame:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        largerFrame:StartMoving()
    end
end)
expBarFrame:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" then
        largerFrame:StopMovingOrSizing()
        SaveFramePosition(largerFrame) -- Save the position of the larger frame
        expBarContainer:ClearAllPoints()
        expBarContainer:SetPoint("CENTER", largerFrame, "CENTER", 0, 0) -- Align expBarContainer to largerFrame
    end
end)

-- Create a resize handle for the larger frame
local resizeHandle = CreateFrame("Frame", nil, largerFrame)
resizeHandle:SetSize(16, 16) -- Size of the resize handle
resizeHandle:SetPoint("BOTTOMRIGHT", largerFrame, "BOTTOMRIGHT", 0, 0) -- Position at the bottom-right corner
resizeHandle:EnableMouse(true)

-- Add a Blizzard-style texture to the resize handle
resizeHandle.texture = resizeHandle:CreateTexture(nil, "OVERLAY")
resizeHandle.texture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resizeHandle.texture:SetAllPoints(resizeHandle)

-- Change the texture on mouse interaction
resizeHandle:SetScript("OnEnter", function(self)
    self.texture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
end)
resizeHandle:SetScript("OnLeave", function(self)
    self.texture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
end)
resizeHandle:SetScript("OnMouseDown", function(self)
    self.texture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
end)
resizeHandle:SetScript("OnMouseUp", function(self)
    self.texture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
end)

-- Enable resizing functionality
resizeHandle:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        largerFrame:StartSizing("BOTTOMRIGHT") -- Start resizing from the bottom-right corner

        -- Add an OnUpdate handler to enforce limits in real-time
        largerFrame:SetScript("OnUpdate", function(self)
            local currentWidth = self:GetWidth()
            local currentHeight = self:GetHeight()

            -- Enforce minimum and maximum width
            if currentWidth < 40 then
                self:SetWidth(40) -- Minimum width + padding
            elseif currentWidth > 1000 then
                self:SetWidth(1000) -- Maximum width
            end

            -- Enforce minimum and maximum height
            if currentHeight < 20 then
                self:SetHeight(20) -- Minimum height + padding
            elseif currentHeight > 200 then
                self:SetHeight(200) -- Maximum height
            end

            -- Constrain the frame within the screen boundaries
            local screenWidth = UIParent:GetWidth()
            local screenHeight = UIParent:GetHeight()
            local frameLeft = self:GetLeft()
            local frameRight = self:GetRight()
            local frameTop = self:GetTop()
            local frameBottom = self:GetBottom()

            if frameLeft < 0 then
                self:SetPoint("LEFT", UIParent, "LEFT", 0, 0)
            elseif frameRight > screenWidth then
                self:SetPoint("RIGHT", UIParent, "RIGHT", 0, 0)
            end

            if frameBottom < 0 then
                self:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 0)
            elseif frameTop > screenHeight then
                self:SetPoint("TOP", UIParent, "TOP", 0, 0)
            end
        end)
    end
end)

resizeHandle:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" then
        largerFrame:StopMovingOrSizing() -- Stop resizing

        -- Remove the OnUpdate handler after resizing is complete
        largerFrame:SetScript("OnUpdate", nil)

        -- Save the new size and position
        SaveFramePosition(largerFrame)
    end
end)

-- Hook the OnSizeChanged event to update the other frames immediately
largerFrame:HookScript("OnSizeChanged", function(self)
    local newWidth = math.max(self:GetWidth() - 10, 10) -- Subtract padding, enforce minimum width of 10
    local newHeight = math.max(self:GetHeight() - 10, 5) -- Subtract padding, enforce minimum height of 5

    -- Update the sizes of the other frames
    expBarContainer:SetSize(newWidth, newHeight)
    expBarFrame:SetSize(newWidth, newHeight)

    -- Immediately update the experience bar and rested bar values
    UpdateExpBar()
end)

-- Ensure the larger frame is resizable with limits
largerFrame:SetResizable(true)

-- Restore the frame's position and size on load
RestoreFramePosition(expBarContainer)
RestoreFramePosition(largerFrame)
