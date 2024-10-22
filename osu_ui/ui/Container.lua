local UiElement = require("osu_ui.ui.UiElement")

---@class osu.ui.Container : osu.ui.UiElement
---@field parent osu.ui.Container?
---@field children {[string]: osu.ui.UiElement}
---@field childrenOrder string[]
---@field childContainers osu.ui.Container[]
---@field eventListeners {[InputEvent]: osu.ui.UiElement}
---@field automaticSizeCalc boolean
local Container = UiElement + {}

function Container:load()
	self.blockMouseFocus = self.blockMouseFocus or false
	self.automaticSizeCalc = true
	self.children = {}
	self.childrenOrder = {}
	self.childContainers = {}
	self.eventListeners = {}

	if self.parent then
		self.parent:registerChildContainer(self)
	end

	UiElement.load(self)
end

---@param id string
---@param child osu.ui.UiElement
---@return osu.ui.UiElement
function Container:addChild(id, child)
	assert(self.children, debug.traceback("Wrong usage of Container class. load() it first. Maybe you forgot to call a base load()?"))
	if self.children[id] then
		error(("Children with the id %s already exist"):format(id))
	end
	self.children[id] = child
	child.parent = self
	child:load()
	return child
end

---@param id string
function Container:removeChild(id)
	self.children[id] = nil
end

---@param child osu.ui.Container
function Container:registerChildContainer(child)
	table.insert(self.childContainers, child)
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
end

local gfx = love.graphics

---@param dt number
function Container:update(dt)
	local mouse_focus = self.mouseOver

	for _, id in ipairs(self.childrenOrder) do
		local child = self.children[id]
		gfx.push()
		gfx.applyTransform(child.transform)
		mouse_focus = not child:setMouseFocus(mouse_focus)
		child:update(dt)
		gfx.pop()
	end
end

function Container:draw()
	for i = #self.childrenOrder, 1, -1 do
		local child = self.children[self.childrenOrder[i]]
		gfx.push()
		gfx.applyTransform(child.transform)
		if child.alpha > 0 then
			local c = child.color
			gfx.setColor(c[1], c[2], c[3], c[4] * child.alpha)
			child:draw()
		end
		gfx.pop()
		gfx.push()
		gfx.applyTransform(child.transform)
		child:debugDraw()
		gfx.pop()
	end
end

---@param event_name InputEvent
---@param event table
function Container:callbackFirstChild(event_name, event)
	if not self.eventListeners[event_name] then
		return false
	end
	for _, child in ipairs(self.eventListeners[event_name]) do
		if child.mouseOver then
			local handled = child[event_name](child, event)
			assert(handled ~= nil, ("%s event did not return a `handled` boolean"):format(event_name))
			if handled then
				return true
			end
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
		return self:callbackFirstChild("mousePressed", event)
	end,
	mousereleased = function(self, event)
		return self:callbackForEachChild("mouseReleased", event)
	end,
	keypressed = function(self, event)
		return self:callbackFirstChild("keyPresseed", event)
	end,
	keyreleased = function(self, event)
		return self:callbackForEachChild("keyReleased", event)
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
