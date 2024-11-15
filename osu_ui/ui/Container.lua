local UiElement = require("osu_ui.ui.UiElement")

local actions = require("osu_ui.actions")

---@class osu.ui.Container : osu.ui.UiElement
---@field parent osu.ui.Container?
---@field children {[string]: osu.ui.UiElement}
---@field childrenOrder string[]
---@field childContainers osu.ui.Container[]
---@field eventListeners {[InputEvent]: osu.ui.UiElement}
---@field textScale number
---@field automaticSizeCalc boolean
local Container = UiElement + {}

function Container:load()
	self.blockMouseFocus = self.blockMouseFocus or false
	self.automaticSizeCalc = self.automaticSizeCalc or true
	self.children = {}
	self.childrenOrder = {}
	self.childContainers = {}
	self.eventListeners = {}
	self.textScale = 1

	self.handleClicks = self.handleClicks or false
	self.mouseKeyDown = 0
	self.mouseTotalMovement = 0
	self.mouseLastX = 0
	self.mouseLastY = 0

	if self.parent then
		self.parent:registerChildContainer(self)
		self.textScale = self.parent.textScale
	end

	UiElement.load(self)
	self:addTags({ "container" })
end

function Container:unload()
	if self.parent then
		self.parent:removeChildContainer(self)
	end
end

---@param id string
---@param child osu.ui.UiElement
---@return osu.ui.UiElement
function Container:addChild(id, child)
	assert(self.children, debug.traceback("Wrong usage of Container class. load() it first. Maybe you forgot to call a base load()?"))
	if self.children[id] then
		error(("Children with the id %s already exist"):format(id))
	end
	child.id = id
	child.parent = self
	child:load()
	self.children[id] = child
	return child
end

---@param id string
function Container:removeChild(id)
	self.children[id]:unload()
	self.children[id] = nil
end

---@param child osu.ui.Container
function Container:registerChildContainer(child)
	table.insert(self.childContainers, child)
end

function Container:removeChildContainer(child)
	for i, v in ipairs(self.childContainers) do
		if v == child then
			table.remove(self.childContainers, i)
			return
		end
	end
end

---@return osu.ui.Viewport
function Container:getViewport()
	if self:hasTag("viewport") then
		---@cast self osu.ui.Viewport
		return self
	end
	assert(self.parent, ("%s does not have a parent, can't get viewport"):format(self.id or "NO_ID"))
	return self.parent:getViewport()
end

---@param child osu.ui.UiElement
---@param event InputEvent
function Container:bindEvent(child, event)
	self.eventListeners[event] = self.eventListeners[event] or {}
	table.insert(self.eventListeners[event], child)
end

--- Sorts own children by depth
function Container:build()
	---@type { id: number, child:  osu.ui.UiElement }[]
	local sorted = {}

	for id, child in pairs(self.children) do
		table.insert(sorted, { id = id, child = child })
		if self.automaticSizeCalc then
			local x, y = child:getPosition()
			self.totalW = math.max(self.totalW, x + child.totalW)
			self.totalH = math.max(self.totalH, y + child.totalH)
		end
	end
	table.sort(sorted, function (a, b)
		return a.child.depth > b.child.depth
	end)

	self.childrenOrder = {}
	for _, v in ipairs(sorted) do
		table.insert(self.childrenOrder, v.id)
		v.child:bindEvents()
	end

	self:applyTransform()
	self.hoverWidth = self.totalW
	self.hoverHeight = self.totalH
end

---@param id string
---@return osu.ui.UiElement?
function Container:getChild(id)
	return self.children[id]
end

---@param f fun(child: osu.ui.UiElement)
function Container:forEachChild(f)
	for _, child in pairs(self.children) do
		f(child)
	end
	for _, container in ipairs(self.childContainers) do
		container:forEachChild(f)
	end
end

---@param f fun(child: osu.ui.UiElement)
function Container:forEachChildGlobally(f)
	if self.parent then
		self.parent:forEachChildGlobally(f)
		return
	end

	self:forEachChild(f)
end

local gfx = love.graphics

---@param dt number
---@param mouse_focus boolean
function Container:update(dt, mouse_focus)
	if self.handleClicks and self.mouseOver ~= 0 then
		local mx, my = love.mouse.getPosition()
		local nx, ny = math.abs(mx - self.mouseLastX), math.abs(my - self.mouseLastY)
		self.mouseTotalMovement = self.mouseTotalMovement + (math.sqrt(nx*nx + ny*ny))
		self.mouseLastX, self.mouseLastY = mx, my
	end

	if self.alpha == 0 then
		return
	end

	for _, id in ipairs(self.childrenOrder) do
		local child = self.children[id]
		gfx.push()
		gfx.applyTransform(child.transform)
		mouse_focus = not child:setMouseFocus(mouse_focus)
		local c = child:update(dt, mouse_focus)
		if c ~= nil then
			mouse_focus = c
		end
		gfx.pop()
	end

	return mouse_focus
end

---@param child osu.ui.UiElement
function Container:drawChild(child)
	if child.alpha > 0 then
		local c = child.color
		gfx.setColor(c[1], c[2], c[3], c[4] * child.alpha)
		child:draw()
	end
end

function Container:draw()
	for i = #self.childrenOrder, 1, -1 do
		local child = self.children[self.childrenOrder[i]]
		gfx.push()
		gfx.applyTransform(child.transform)
		self:drawChild(child)
		gfx.pop()
		--[[
		gfx.push()
		gfx.applyTransform(child.transform)
		child:debugDraw()
		gfx.pop()
		]]
	end
end

---@param event_name InputEvent
---@param event table
function Container:callbackFirstChild(event_name, event)
	if not self.eventListeners[event_name] then
		return false
	end
	for _, child in ipairs(self.eventListeners[event_name]) do
		local handled = child[event_name](child, event)
		assert(handled ~= nil, ("%s %s event did not return a `handled` boolean"):format(child.id, event_name))
		if handled then
			return true
		end
	end
	return false
end

function Container:callbackForEachChild(event_name, event)
	if not self.eventListeners[event_name] then
		return false
	end
	for _, child in pairs(self.eventListeners[event_name]) do
		child[event_name](child, event)
	end
	return false
end

---@type {[string]: fun(self: osu.ui.Container, event: table): boolean}
local events = {
	wheelmoved = function(self, event)
		if event[2] == 1 then
			return self:callbackFirstChild("wheelUp", event)
		else
			return self:callbackFirstChild("wheelDown", event)
		end
	end,
	mousepressed = function(self, event)
		if self.handleClicks then
			self.mouseKeyDown = event[3]
			self.mouseLastX, self.mouseLastY = love.mouse.getPosition()
			self.mouseTotalMovement = 0
		end
		local handled = self:callbackFirstChild("mousePressed", event)
		if handled then
			self:getViewport().mouseKeyDown = 0
		end
		return handled
	end,
	mousereleased = function(self, event)
		local handled = self:callbackForEachChild("mouseReleased", event)
		if self.handleClicks then
			if self.mouseTotalMovement < 6 and self.mouseKeyDown == event[3] then
				self:receive({ name = "mouseClick", key = event[3] })
			end
			self.mouseKeyDown = 0
		end
		return handled
	end,
	keypressed = function(self, event)
		local action = actions.getAction()
		if action then
			return self:callbackFirstChild(action .. "Action", event)
		end
		return self:callbackFirstChild("keyPressed", event)
	end,
	keyreleased = function(self, event)
		return self:callbackForEachChild("keyReleased", event)
	end,
	textinput = function (self, event)
		return self:callbackFirstChild("textInput", event)
	end,
	mouseClick = function (self, event)
		return self:callbackFirstChild("mouseClick", event)
	end
}

---@param event table
---@return boolean handled
function Container:receive(event)
	local f = events[event.name]
	if f then
		local handled = f(self, event)
		if handled then
			return true
		end
	end

	for _, child in ipairs(self.childContainers) do
		local handled = child:receive(event)
		if handled then
			return true
		end
	end
	return false
end

return Container
