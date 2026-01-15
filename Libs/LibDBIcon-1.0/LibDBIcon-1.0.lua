-----------------------------------------------------------------------
-- LibDBIcon-1.0
--
-- Allows addons to easily create a lightweight minimap icon as an alternative to heavier LDB displays.
--
local DBICON10 = "LibDBIcon-1.0"
local DBICON10_MINOR = 44 -- Bump on changes
if not LibStub then error(DBICON10 .. " requires LibStub.") end
local ldb = LibStub("LibDataBroker-1.1", true)
if not ldb then error(DBICON10 .. " requires LibDataBroker-1.1.") end
local lib = LibStub:NewLibrary(DBICON10, DBICON10_MINOR)
if not lib then return end

lib.objects = lib.objects or {}
lib.callbackRegistered = lib.callbackRegistered or nil
lib.callbacks = lib.callbacks or LibStub("CallbackHandler-1.0"):New(lib)
lib.notCreated = lib.notCreated or {}
lib.radius = lib.radius or 5
lib.tooltip = lib.tooltip or CreateFrame("GameTooltip", "LibDBIconTooltip", UIParent, "GameTooltipTemplate")
local next, pairs, type = next, pairs, type

local function getAnchors(frame)
	local x, y = frame:GetCenter()
	if not x or not y then return "CENTER" end
	local hhalf = (x > UIParent:GetWidth()*2/3) and "RIGHT" or (x < UIParent:GetWidth()/3) and "LEFT" or ""
	local vhalf = (y > UIParent:GetHeight()/2) and "TOP" or "BOTTOM"
	return vhalf..hhalf, frame, (vhalf == "TOP" and "BOTTOM" or "TOP")..hhalf
end

local function updatePosition(button, position)
	if not button.dataObject then return end
	local minimapShape = GetMinimapShape and GetMinimapShape() or "ROUND"
	local isRound = true
	if minimapShape == "SQUARE" then isRound = false end
	if minimapShape == "CORNER-TOPRIGHT" then isRound = false end
	if minimapShape == "CORNER-TOPLEFT" then isRound = false end
	if minimapShape == "CORNER-BOTTOMRIGHT" then isRound = false end
	if minimapShape == "CORNER-BOTTOMLEFT" then isRound = false end
	if minimapShape == "TRICORNER-TOPRIGHT" then isRound = false end
	if minimapShape == "TRICORNER-TOPLEFT" then isRound = false end
	if minimapShape == "TRICORNER-BOTTOMRIGHT" then isRound = false end
	if minimapShape == "TRICORNER-BOTTOMLEFT" then isRound = false end
	
	local angle = math.rad(position or 225)
	local x, y
	local cos = math.cos(angle)
	local sin = math.sin(angle)
	local round = isRound
	if round then
		x = cos * lib.radius
		y = sin * lib.radius
	else
		x = 110 * cos
		y = 110 * sin
		if cos < 0 then x = x - 10 end
		if sin < 0 then y = y - 10 end
	end
	button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function onClick(self, b)
	if self.dataObject.OnClick then
		self.dataObject.OnClick(self, b)
	end
end

local function onEnter(self)
	if self.dataObject.OnTooltipShow then
		lib.tooltip:SetOwner(self, "ANCHOR_NONE")
		lib.tooltip:SetPoint(getAnchors(self))
		self.dataObject.OnTooltipShow(lib.tooltip)
		lib.tooltip:Show()
	elseif self.dataObject.OnEnter then
		self.dataObject.OnEnter(self)
	end
end

local function onLeave(self)
	lib.tooltip:Hide()
	if self.dataObject.OnLeave then
		self.dataObject.OnLeave(self)
	end
end

local function onMouseDown(self)
	self.isMouseDown = true
	self.icon:UpdateCoord()
end

local function onMouseUp(self)
	self.isMouseDown = false
	self.icon:UpdateCoord()
end

local function onDragStart(self)
	self:LockHighlight()
	self.isMouseDown = true
	self.icon:UpdateCoord()
	self:SetScript("OnUpdate", function(self)
		local mx, my = Minimap:GetCenter()
		local px, py = GetCursorPosition()
		local scale = Minimap:GetEffectiveScale()
		px, py = px / scale, py / scale
		local pos = 225
		if px and py and mx and my then
			pos = math.deg(math.atan2(py - my, px - mx)) % 360
		end
		lib:SetButtonToPosition(self, pos)
	end)
end

local function onDragStop(self)
	self:SetScript("OnUpdate", nil)
	self.isMouseDown = false
	self.icon:UpdateCoord()
	self:UnlockHighlight()
end

local function createButton(name, object, db)
	local button = CreateFrame("Button", "LibDBIcon10_"..name, Minimap)
	button.dataObject = object
	button.db = db
	button:SetFrameStrata("MEDIUM")
	button:SetSize(31, 31)
	button:SetFrameLevel(8)
	button:RegisterForClicks("anyUp")
	button:RegisterForDrag("LeftButton")
	button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
	
	local overlay = button:CreateTexture(nil, "OVERLAY")
	overlay:SetSize(53, 53)
	overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
	overlay:SetPoint("TOPLEFT")
	
	local background = button:CreateTexture(nil, "BACKGROUND")
	background:SetSize(20, 20)
	background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
	background:SetPoint("TOPLEFT", 7, -5)
	
	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetSize(17, 17)
	icon:SetTexture(object.icon)
	icon:SetPoint("TOPLEFT", 7, -6)
	button.icon = icon
	
	button.isMouseDown = false
	
	local r, g, b = icon:GetVertexColor()
	icon.UpdateCoord = function(self)
		local coords = object.iconCoords or {0, 1, 0, 1}
		if button.isMouseDown then
			self:SetTexCoord(coords[1] + 0.05, coords[2] - 0.05, coords[3] + 0.05, coords[4] - 0.05)
		else
			self:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
		end
		self:SetVertexColor(r, g, b)
	end
	
	icon:UpdateCoord()
	
	button:SetScript("OnEnter", onEnter)
	button:SetScript("OnLeave", onLeave)
	button:SetScript("OnClick", onClick)
	button:SetScript("OnMouseDown", onMouseDown)
	button:SetScript("OnMouseUp", onMouseUp)
	button:SetScript("OnDragStart", onDragStart)
	button:SetScript("OnDragStop", onDragStop)
	
	lib.objects[name] = button
	
	if lib.callbacks then
		lib.callbacks:Fire("LibDBIcon_IconCreated", button, name)
	end
end

function lib:Register(name, object, db)
	if not object.icon then error("Can't register LDB objects without icons set!") end
	if lib.objects[name] or lib.notCreated[name] then error("Already registered: "..name) end
	if not db or not db.hide then
		createButton(name, object, db)
		updatePosition(lib.objects[name], db and db.minimapPos or 225)
		if not db or not db.hide then
			lib.objects[name]:Show()
		else
			lib.objects[name]:Hide()
		end
	else
		lib.notCreated[name] = {object, db}
	end
end

function lib:Lock(name)
	local button = lib.objects[name]
	if button then
		button:SetScript("OnDragStart", nil)
		button:SetScript("OnDragStop", nil)
		if button.db then
			button.db.lock = true
		end
	end
end

function lib:Unlock(name)
	local button = lib.objects[name]
	if button then
		button:SetScript("OnDragStart", onDragStart)
		button:SetScript("OnDragStop", onDragStop)
		if button.db then
			button.db.lock = nil
		end
	end
end

function lib:Hide(name)
	local button = lib.objects[name]
	if button then
		button:Hide()
	end
end

function lib:Show(name)
	local button = lib.objects[name]
	if button then
		button:Show()
		updatePosition(button, button.db and button.db.minimapPos or 225)
	elseif lib.notCreated[name] then
		local object, db = unpack(lib.notCreated[name])
		createButton(name, object, db)
		updatePosition(lib.objects[name], db and db.minimapPos or 225)
		lib.notCreated[name] = nil
		lib.objects[name]:Show()
	end
end

function lib:IsRegistered(name)
	return (lib.objects[name] or lib.notCreated[name]) and true or false
end

function lib:Refresh(name, db)
	local button = lib.objects[name]
	if button then
		button.db = db
		updatePosition(button, db and db.minimapPos or 225)
		if db and db.hide then
			button:Hide()
		elseif not db or not db.hide then
			button:Show()
		end
		if db and db.lock then
			lib:Lock(name)
		else
			lib:Unlock(name)
		end
	end
end

function lib:GetMinimapButton(name)
	return lib.objects[name]
end

function lib:SetButtonToPosition(button, position)
	if button.db then
		button.db.minimapPos = position
		updatePosition(button, position)
	end
end

function lib:SetButtonRadius(radius)
	lib.radius = radius
	for _, button in pairs(lib.objects) do
		updatePosition(button, button.db and button.db.minimapPos or 225)
	end
end

function lib:GetButtonList()
	local list = {}
	for name in pairs(lib.objects) do
		list[name] = true
	end
	return list
end

function lib:SetButtonSize(name, size)
	local button = lib.objects[name]
	if button then
		button:SetSize(size, size)
	end
end
