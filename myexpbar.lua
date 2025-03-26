-- Initialize the settings variable
if not MyExpBarSettings then
    MyExpBarSettings = {}
end

-- Function to save settings
local function saveSettings()
    MyExpBarSettings.width = MainMenuExpBar:GetWidth()
    MyExpBarSettings.height = MainMenuExpBar:GetHeight()
    MyExpBarSettings.alpha = MainMenuExpBar:GetAlpha()
    local point, relativeTo, relativePoint, xOfs, yOfs = MainMenuExpBar:GetPoint()
    MyExpBarSettings.point = {point, relativeTo and relativeTo:GetName() or "UIParent", relativePoint, xOfs, yOfs}
end

-- Create a frame for our experience text
local myExpTextFrame = CreateFrame("Frame", nil, MainMenuExpBar)
myExpTextFrame:SetFrameStrata("HIGH") -- Set higher frame strata
myExpTextFrame:SetAllPoints(MainMenuExpBar)

-- Create our own experience text
local myExpText = myExpTextFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
myExpText:SetPoint("CENTER", myExpTextFrame, "CENTER", 0, 0)
myExpText:SetTextColor(1, 1, 1, 1) -- White color
myExpText:Show()

-- Update our experience text to match Blizzard's MainMenuBarExpText
local function updateExpText()
    local currentXP = UnitXP("player")
    local maxXP = UnitXPMax("player")
    local percentage = 0
    if maxXP > 0 then
        percentage = (currentXP / maxXP) * 100
    end
    local restedXP = GetXPExhaustion() or 0
    myExpText:SetText(string.format("(%d%%) %d / %d (+%d)", percentage, currentXP, maxXP, restedXP))
end

-- Hide Blizzard's MainMenuXPBarTexture0 to MainMenuXPBarTexture5
for i = 0, 5 do
    local texture = _G["MainMenuXPBarTexture" .. i]
    if texture then
        texture:Hide()
    end
end

-- Hide Blizzard's MainMenuBar textures
for i = 0, 5 do
    local texture = _G["MainMenuBar.MainMenuXPBarTexture" .. i]
    if texture then
        texture:Hide()
    end
end

-- Hide Blizzard's MainMenuBarExpText
if MainMenuBarExpText then
    MainMenuBarExpText:Hide()
    MainMenuBarExpText:HookScript("OnShow", function(self) self:Hide() end)
end

-- Hook to hide MainMenuBarExpText on mouseover
MainMenuExpBar:HookScript("OnEnter", function()
    if MainMenuBarExpText then
        MainMenuBarExpText:Hide()
    end
end)

-- Make the experience bar movable
MainMenuExpBar:SetMovable(true)
MainMenuExpBar:EnableMouse(true)
MainMenuExpBar:RegisterForDrag("LeftButton")
MainMenuExpBar:SetScript("OnDragStart", MainMenuExpBar.StartMoving)
MainMenuExpBar:SetScript("OnDragStop", MainMenuExpBar.StopMovingOrSizing)

-- Create settings frame
local settingsFrame = CreateFrame("Frame", "MyExpBarSettingsFrame", UIParent, "BackdropTemplate")
settingsFrame:SetSize(210, 230) 
settingsFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0) -- Centered initially
settingsFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
settingsFrame:SetBackdropColor(0, 0, 0, 0.8)
settingsFrame:SetBackdropBorderColor(0, 0, 0)
settingsFrame:Hide() -- Hide the frame initially

-- Make the settings frame movable
settingsFrame:EnableMouse(true)
settingsFrame:SetMovable(true)
settingsFrame:RegisterForDrag("LeftButton")
settingsFrame:SetScript("OnDragStart", settingsFrame.StartMoving)
settingsFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
end)
settingsFrame:SetClampedToScreen(true)

-- Title text for the settings frame
local settingsTitle = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
settingsTitle:SetPoint("TOP", settingsFrame, "TOP", 0, -10)
settingsTitle:SetText("|cFFFFFFFFMy |cFF00FF00Settings|r") -- White "My" and ocean green "Settings"

-- Close button for the settings frame
local closeButton = CreateFrame("Button", nil, settingsFrame)
closeButton:SetSize(24, 24)
closeButton:SetPoint("TOPRIGHT", settingsFrame, "TOPRIGHT", -5, -5)
closeButton:SetNormalTexture("Interface\\AddOns\\MySanctified\\close.png")
closeButton:SetScript("OnClick", function()
    settingsFrame:Hide()
end)
closeButton:SetScript("OnEnter", function(self)
    self:GetNormalTexture():SetVertexColor(1, 0, 0) -- Red color on highlight
end)
closeButton:SetScript("OnLeave", function(self)
    self:GetNormalTexture():SetVertexColor(1, 1, 1) -- Reset color
end)

-- Width slider
local widthSlider = CreateFrame("Slider", "WidthSlider", settingsFrame, "OptionsSliderTemplate")
widthSlider:SetMinMaxValues(100, 2820)
widthSlider:SetValue(MainMenuExpBar:GetWidth())
widthSlider:SetValueStep(1)
widthSlider:SetPoint("TOP", settingsFrame, "TOP", 0, -60) -- Adjusted position
widthSlider:SetScript("OnValueChanged", function(self, value)
    MainMenuExpBar:SetWidth(value)
    MyExpBarSettings.width = value
    saveSettings()
end)
WidthSliderText:SetText("Width")
WidthSliderLow:SetText("100")
WidthSliderHigh:SetText("800")

-- Height slider
local heightSlider = CreateFrame("Slider", "HeightSlider", settingsFrame, "OptionsSliderTemplate")
heightSlider:SetMinMaxValues(10, 50)
heightSlider:SetValue(MainMenuExpBar:GetHeight())
heightSlider:SetValueStep(1)
heightSlider:SetPoint("TOP", widthSlider, "BOTTOM", 0, -30) -- Adjusted position
heightSlider:SetScript("OnValueChanged", function(self, value)
    MainMenuExpBar:SetHeight(value)
    MyExpBarSettings.height = value
    saveSettings()
end)
_G["HeightSliderText"]:SetText("Height")
_G["HeightSliderLow"]:SetText("10")
_G["HeightSliderHigh"]:SetText("50")

-- Alpha slider
local alphaSlider = CreateFrame("Slider", "AlphaSlider", settingsFrame, "OptionsSliderTemplate")
alphaSlider:SetMinMaxValues(0, 1)
alphaSlider:SetValue(MainMenuExpBar:GetAlpha())
alphaSlider:SetValueStep(0.01)
alphaSlider:SetPoint("TOP", heightSlider, "BOTTOM", 0, -30) -- Adjusted position
alphaSlider:SetScript("OnValueChanged", function(self, value)
    MainMenuExpBar:SetAlpha(value)
    MyExpBarSettings.alpha = value
    saveSettings()
end)
AlphaSliderText:SetText("Alpha")
AlphaSliderLow:SetText("0")
AlphaSliderHigh:SetText("1")

-- Ensure myExpText remains visible when settings frame is closed
settingsFrame:HookScript("OnHide", function()
    myExpText:Show()
    MainMenuBarExpText:Hide() -- Ensure it stays hidden
    updateExpText()
end)

-- Hook the update function to the experience events
MainMenuExpBar:HookScript("OnEvent", function(self, event, ...)
    updateExpText()
end)
MainMenuExpBar:RegisterEvent("PLAYER_XP_UPDATE")
MainMenuExpBar:RegisterEvent("PLAYER_LEVEL_UP")

-- Dynamically move Blizzard's MainMenuBarExpText based on MainMenuExpBar's scale, width, and height
if MainMenuBarExpText then
    MainMenuExpBar:HookScript("OnSizeChanged", function(self)
        MainMenuBarExpText:ClearAllPoints()
        local scale = self:GetScale()
        local width = self:GetWidth()
        local height = self:GetHeight()
        MainMenuBarExpText:SetPoint("CENTER", self, "CENTER", 0, 0)
    end)
end

-- Reset button
local resetButton = CreateFrame("Button", "ResetButton", settingsFrame, "GameMenuButtonTemplate")
resetButton:SetSize(80, 30)
resetButton:SetPoint("BOTTOM", settingsFrame, "BOTTOM", 0, 10)
resetButton:SetText("Reset")
resetButton:SetScript("OnClick", function()
    MainMenuExpBar:SetWidth(512)
    MainMenuExpBar:SetHeight(20)
    MainMenuExpBar:SetAlpha(1)
    MainMenuExpBar:ClearAllPoints()
    MainMenuExpBar:SetPoint("CENTER", UIParent, "CENTER")
    widthSlider:SetValue(512)
    heightSlider:SetValue(20)
    alphaSlider:SetValue(1)
    myExpText:Show()
    MainMenuBarExpText:Show() -- Show Blizzard's XP text
    MyExpBarSettings = {
        width = 512,
        height = 20,
        alpha = 1,
        point = {"CENTER", UIParent, "CENTER", 0, 0}
    }
    saveSettings()
end)

-- Right-click to open settings
MainMenuExpBar:SetScript("OnMouseUp", function(self, button)
    if button == "RightButton" then
        if settingsFrame:IsShown() then
            settingsFrame:Hide()
        else
            settingsFrame:Show()
        end
    end
end)

-- Initial update
updateExpText()

-- Register event to save settings when the player logs out or the UI is reloaded
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGOUT")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "MyExpBar" then
        -- Ensure settings are loaded
        if not MyExpBarSettings then
            MyExpBarSettings = {
                width = 512,
                height = 20,
                alpha = 1,
                point = {"CENTER", UIParent, "CENTER", 0, 0}
            }
        end

        -- Apply the saved settings
        MainMenuExpBar:SetWidth(MyExpBarSettings.width)
        MainMenuExpBar:SetHeight(MyExpBarSettings.height)
        MainMenuExpBar:SetAlpha(MyExpBarSettings.alpha)
        MainMenuExpBar:ClearAllPoints()
        MainMenuExpBar:SetPoint(unpack(MyExpBarSettings.point))

        widthSlider:SetValue(MyExpBarSettings.width)
        heightSlider:SetValue(MyExpBarSettings.height)
        alphaSlider:SetValue(MyExpBarSettings.alpha)

    elseif event == "PLAYER_LOGOUT" then
        saveSettings()
    end
end)


