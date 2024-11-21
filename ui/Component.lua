local class = require("class")

local EventHandler = require("ui.EventHandler")

---@class ui.Component
---@operator call: ui.Component
---@field id string
---@field parent ui.Component
---@field eventListeners {[ui.ComponentEvent]: ui.Component[]}
local Component = class()

---@param params table?
function Component:new(params)
	if params then
		for k, v in pairs(params) do
			self[k] = v
		end
	end

	self.alpha = 1
	self.color = self.color or { 1, 1, 1, 1 }
	if not self.color[4] then
		self.color[4] = 1
	end

	self.children = {}
	self.childrenOrder = {}
	self.eventListeners = {}
	self.eventHandler = self.eventHandler or EventHandler()

	self.mouseOver = false
	self.blockMouseFocus = self.blockMouseFocus or false
	self.canUpdateChildren = true

	self.z = self.z or 0.0
	self.x = self.x or 0.0
	self.y = self.y or 0.0
	self.angle = self.angle or 0.0
	self.scale = self.scale or 1.0
	self.scaleX = self.scaleX or self.scale
	self.scaleY = self.scaleY or self.scale
	self.origin = self.origin or { x = 0.0, y = 0.0 }
	self.origin.x = self.origin.x or 0
	self.origin.y = self.origin.y or 0
	self.width = self.width or 0
	self.height = self.height or 0
	self.transform = love.math.newTransform()
	self:updateTransform()

	self.deferBuild = false
end

function Component:load() end

---@param delta_time number
function Component:update(delta_time) end

---@param mx number
---@param my number
function Component:setMouseFocus(mx, my)
	local imx, imy = love.graphics.inverseTransformPoint(mx, my)
	self.mouseOver = imx >= 0 and imx < self.width and imy >= 0 and imy < self.height
end

---@return boolean
function Component:isParentFocused()
	return self.parent.mouseOver
end

---@param state ui.FrameState
function Component:updateTree(state)
	if self.deferBuild then
		self:build()
	end

	self.transform:setTransformation(self.x, self.y, self.angle, self.scaleX, self.scaleY, self:getOrigin())
	love.graphics.applyTransform(self.transform)

	if
		state.mouseFocus
		and self.alpha * self.color[4] > 0
		and self:isParentFocused()
	then
		local was_over = self.mouseOver
		self:setMouseFocus(state.mouseX, state.mouseY)
		if not was_over then
			self:justHovered()
		end
		if self.mouseOver and self.blockMouseFocus then
			state.mouseFocus = false
		end
	else
		self.mouseOver = false
	end

	self:update(state.deltaTime)
	self:getViewport():inspect(self)

	if not self.canUpdateChildren then
		return
	end

	for _, id in ipairs(self.childrenOrder) do
		local child = self.children[id]
		love.graphics.push()
		child:updateTree(state)
		love.graphics.pop()
	end
end

function Component:draw() end

---@return number
---@return number
---@return number
---@return number
function Component:mixColors()
	local r, g, b, a = love.graphics.getColor()
	r = r * self.color[1]
	g = g * self.color[2]
	b = b * self.color[3]
	a = a * self.color[4] * self.alpha
	return r, g, b, a
end

---@param r number
---@param g number
---@param b number
---@param a number
function Component:drawChildren(r, g, b, a)
	for i = #self.childrenOrder, 1, -1 do
		local child = self.children[self.childrenOrder[i]]
		love.graphics.push()
		child:drawTree()
		love.graphics.pop()
		love.graphics.push()
		love.graphics.applyTransform(child.transform)
		love.graphics.setColor(1, 0, 0, 1)
		love.graphics.rectangle("line", 0, 0, child.width, child.height)
		love.graphics.setColor(r, g, b, a)
		love.graphics.pop()
	end
end

function Component:drawTree()
	local r, g, b, a = self:mixColors()
	if a <= 0 then
		return
	end

	love.graphics.setColor(r, g, b, a)
	love.graphics.applyTransform(self.transform)
	self:draw()
	self:drawChildren(r, g, b, a)
end

---@return number
---@return number
function Component:getOrigin()
	return self.width * self.origin.x, self.height * self.origin.y
end

function Component:updateTransform()
	self.transform:setTransformation(self.x, self.y, self.angle, self.scaleX, self.scaleY, self:getOrigin())
end

---@param id string
---@param child ui.Component
---@return ui.Component
function Component:addChild(id, child)
	if self.children[id] then
		print(("Duplicate child with the id %s added to %s"):format(id, self.id))
	end
	child.id = id
	child.parent = self
	child:load()
	self.children[id] = child
	self.deferBuild = true
	return child
end

function Component:removeChild(id)
	self.children[id] = nil
	self:build()
end

---@param id string
---@return ui.Component?
function Component:getChild(id)
	return self.children[id]
end

---@param child ui.Component
---@param event ui.ComponentEvent
function Component:bindEvent(child, event)
	self.eventListeners[event] = self.eventListeners[event] or {}
	table.insert(self.eventListeners[event], child)
end

function Component:bindEvents() end

function Component:build()
	---@type ui.Component[]
	local sorted = {}

	for _, child in pairs(self.children) do
		table.insert(sorted, child)
	end
	table.sort(sorted, function(a, b)
		return a.z > b.z
	end)

	self.childrenOrder = {}
	self.eventListeners = {}
	for _, child in ipairs(sorted) do
		table.insert(self.childrenOrder, child.id)
		child:bindEvents()
	end

	self.deferBuild = false
end

---@param child ui.Component
---@param new_id string
function Component:renameChild(child, new_id)
	child.id = new_id
	self.children[child.id] = nil
	self.children[new_id] = child.id
	self:build()
end

---@return ui.Viewport
function Component:getViewport()
	return self.parent:getViewport()
end

function Component:justHovered() end

function Component:error(message)
	message = ("%s :: %s"):format(self.id, message)
	self.parent:error(message)
end

function Component:assert(thing, message)
	if not thing then
		self:error(message)
	end
end

---@param event_name ui.ComponentEvent
---@param event table
function Component:callbackFirstChild(event_name, event)
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

function Component:callbackForEachChild(event_name, event)
	if not self.eventListeners[event_name] then
		return false
	end
	for _, child in pairs(self.eventListeners[event_name]) do
		child[event_name](child, event)
	end
	return false
end

---@param event table
---@return boolean handled
function Component:receive(event)
	local f = self.eventHandler[event.name]
	if f then
		local handled = f(self, event)
		if handled then
			return true
		end
	end

	if not self.canUpdateChildren then
		return false
	end

	for _, id in ipairs(self.childrenOrder) do
		local child = self.children[id]
		local handled = child:receive(event)
		if handled then
			return true
		end
	end

	return false
end

function Component:getDimensions()
	return self.width, self.height
end

return Component
