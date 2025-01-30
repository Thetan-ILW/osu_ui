local class = require("class")

---@class ui.Component
---@operator call: ui.Component
---@field id string
---@field parent ui.Component
---@field children {[string]: ui.Component}
---@field killed boolean
local Component = class()

---@param params table?
function Component:new(params)
	if params then
		for k, v in pairs(params) do
			self[k] = v
		end
	end

	self.alpha = self.alpha or 1
	self.color = self.color or { 1, 1, 1, 1 }
	if not self.color[4] then
		self.color[4] = 1
	end

	self.children = {}
	self.childrenOrder = {}

	self.mouseOver = false
	self.blockMouseFocus = self.blockMouseFocus or false

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
	self.disabled = self.disabled or false
	self.handleEvents = self.handleEvents or true
	self.killed = false
end

function Component:load() end

function Component:reload()
	self:clearTree()
	self:load()
end

---@param delta_time number
function Component:update(delta_time) end

---@param mx number
---@param my number
function Component:setMouseFocus(mx, my)
	local imx, imy = love.graphics.inverseTransformPoint(mx, my)
	self.mouseOver = imx >= 0 and imx < self.width and imy >= 0 and imy < self.height
end

function Component:noMouseFocus()
	self.mouseOver = false
end

---@param state ui.FrameState
function Component:updateChildren(state)
	for _, id in ipairs(self.childrenOrder) do
		local child = self.children[id]
		love.graphics.push()
		child:updateTree(state)
		love.graphics.pop()
	end
end

---@param state ui.FrameState
function Component:updateTree(state)
	if self.deferBuild then
		self:build()
	end
	if self.disabled then
		return
	end

	love.graphics.applyTransform(self.transform)

	if
		state.mouseFocus
		and self.handleEvents
		and self.alpha * self.color[4] > 0
	then
		local was_over = self.mouseOver
		self:setMouseFocus(state.mouseX, state.mouseY)
		if not was_over and self.mouseOver then
			self:justHovered()
		end
		if self.mouseOver and self.blockMouseFocus then
			state.mouseFocus = false
		end
	else
		self:noMouseFocus()
	end

	self:update(state.deltaTime)
	self:updateChildren(state)

	self.transform:setTransformation(self.x, self.y, self.angle, self.scaleX, self.scaleY, self:getOrigin())
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

function Component:drawChildren()
	for i = #self.childrenOrder, 1, -1 do
		local child = self.children[self.childrenOrder[i]]
		love.graphics.push("all")
		child:drawTree()
		love.graphics.pop()

		if child.debug then
			love.graphics.push("all")
			love.graphics.applyTransform(child.transform)
			love.graphics.setColor(1, 0, 0, 1)
			love.graphics.rectangle("line", 0, 0, child.width, child.height)
			love.graphics.pop()
		end
	end
end

function Component:drawTree()
	local r, g, b, a = self:mixColors()
	if a <= 0 or self.disabled then
		return
	end

	love.graphics.setColor(r, g, b, a)
	love.graphics.applyTransform(self.transform)
	self:draw()
	love.graphics.setColor(r, g, b, a)
	self:drawChildren()
end

---@return number
---@return number
function Component:getOrigin()
	return self.width * self.origin.x, self.height * self.origin.y
end

function Component:updateTransform()
	self.transform:setTransformation(self.x, self.y, self.angle, self.scaleX, self.scaleY, self:getOrigin())
end

function Component:bindEvents() end
function Component:unbindEvents() end

---@generic T : ui.Component
---@param id string
---@param child T
---@return T
function Component:addChild(id, child)
	if self.children[id] then
		print(("Duplicate child with the id %s added to %s"):format(id, self.id))
	end
	child.id = id
	child.parent = self
	child:load()
	child:bindEvents()
	child.killed = false
	self.children[id] = child
	self.deferBuild = true
	return child
end

function Component:removeChild(id)
	local child = self.children[id]
	if child then
		child:unbindEvents()
		child.parent = nil
		child.killed = true
		self.children[id] = nil
		self:build()
	end
end

function Component:kill()
	self:clearTree()
	self.parent:removeChild(self.id)
end

function Component:clearTree()
	self.eventListeners = {}
	self.children = {}
	self.childrenOrder = {}
end

---@param id string
---@return ui.Component?
function Component:getChild(id)
	return self.children[id]
end

---@param id string
---@return ui.Component?
function Component:findComponent(id)
	if self.id == id then
		return self
	end
	return self.parent:findComponent(id)
end

---@param old_id string
---@param new_id string
function Component:renameChild(old_id, new_id)
	local child = self.children[old_id]
	child.id = new_id
	self.children[old_id] = nil
	self.children[new_id] = child
	self:build()
end

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
	for _, child in ipairs(sorted) do
		table.insert(self.childrenOrder, child.id)
	end
	self.deferBuild = false
end

function Component:autoSize()
	local w, h = 0, 0
	for _, child in pairs(self.children) do
		w = math.max(w, child.x + child.width * child.scaleX)
		h = math.max(h, child.y + child.height * child.scaleY)
	end
	self.width, self.height = w, h
end

---@return ui.Viewport
function Component:getViewport()
	return self.parent:getViewport()
end

function Component:justHovered() end

function Component:error(message)
	message = ("%s :: %s"):format(self.id, message)
	if self.parent then
		self.parent:error(message)
	else
		error(message)
	end
end

function Component:assert(thing, message)
	if not thing then
		self:error(message)
	end
end

---@param event table
---@return boolean blocked
function Component:receive(event)
	if self.disabled or not self.handleEvents then
		return false
	end

	if self[event.name] then
		if self[event.name](self, event) then
			return true
		end
	end

	for _, id in ipairs(self.childrenOrder) do
		local child = self.children[id]
		local blocked = child:receive(event)
		if blocked then
			return true
		end
	end

	return false
end

---@return number
function Component:getWidth()
	return self.width
end

---@return number
function Component:getHeight()
	return self.height
end

---@return number
---@return number
function Component:getDimensions()
	return self:getWidth(), self:getHeight()
end

local sound_play_time = {}

---@param sound audio.Source
---@param limit number?
function Component.playSound(sound, limit)
	if not sound then
		return
	end

	limit = limit or 0.05

	local prev_time = sound_play_time[sound] or 0
	local current_time = love.timer.getTime()

	if current_time > prev_time + limit then
		sound:stop()
		sound_play_time[sound] = current_time
	end

	sound:play()
end

return Component
