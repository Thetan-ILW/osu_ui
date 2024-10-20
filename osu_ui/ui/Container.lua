local class = require("class")

---@class osu.ui.Container
---@field depth number -- 1 at the top | 0 at the bottom
---@field transform love.Transform
---@field children {[string]: osu.ui.Container}
---@field childrenOrder string[]
local Container = class()

---@param depth number?
---@param transform love.Transform?
function Container:new(depth, transform)
	self.depth = depth or 0
	self.children = {}
	self:setTransform(transform or love.math.newTransform())
end

---@param transform love.Transform
function Container:setTransform(transform)
	self.originalTransform = transform:clone()
	self.transform = transform:clone()
end

function Container:load() end

---@param id string
---@param child osu.ui.Container
---@return osu.ui.Container
function Container:addChild(id, child)
	if self.children[id] then
		error(("Children with the id %s already exist"):format(id))
	end
	self.children[id] = child
	return child
end

---@param id string
function Container:removeChild(id)
	self.children[id] = nil
end

function Container:sortChildren()
	local sorted = {}
	for id, child in pairs(self.children) do
		table.insert(sorted, { id = id, depth = child.depth or 0 })
	end
	table.sort(sorted, function (a, b)
		return a.depth > b.depth
	end)

	self.childrenOrder = {}
	for _, v in ipairs(sorted) do
		table.insert(self.childrenOrder, v.id)
	end
end

---@param id string
---@return osu.ui.Container?
function Container:getChild(id)
	return self.children[id]
end

---@param has_focus  boolean
---@return boolean clicked
function Container:mouseInput(has_focus) return false end

---@param has_focus  boolean
---@return boolean pressed
function Container:keyboardInput(has_focus) return false end

local gfx = love.graphics

---@param dt number
function Container:update(dt)
	gfx.push()

	local mouse_focus, keyboard_focus = true, true

	for _, id in ipairs(self.childrenOrder) do
		local child = self.children[id]
		gfx.push()
		child:updateTransform()
		gfx.applyTransform(child.transform)
		if child:mouseInput(mouse_focus) then
			mouse_focus = false
		end
		if child:keyboardInput(keyboard_focus) then
			keyboard_focus = false
		end
		child:update(dt)
		gfx.pop()
	end

	gfx.pop()
end

function Container:draw()
	gfx.push()
	for i = #self.childrenOrder, 1, -1 do
		local child = self.children[self.childrenOrder[i]]
		gfx.push()
		gfx.applyTransform(child.transform)
		gfx.setColor(1, 1, 1)
		child:draw()
		child:resetTransform()
		gfx.pop()
	end
	gfx.pop()
end

function Container:updateTransform() end

function Container:resetTransform()
	self.transform = self.originalTransform:clone()
end

local function emptyUpdate() end

---@param f function
---@param depth number?
---@param transform love.transform?
function Container.drawFunction(f, depth, transform)
	local c = Container(depth, transform)
	c.draw = f
	c.update = emptyUpdate
	return c
end

return Container
