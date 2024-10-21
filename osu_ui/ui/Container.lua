local UiElement = require("osu_ui.ui.UiElement")

---@class osu.ui.Container : osu.ui.UiElement
---@field children {[string]: osu.ui.UiElement}
---@field childrenOrder string[]
---@field automaticSizeCalc boolean
local Container = UiElement + {}

function Container:load()
	self.blockMouseFocus = self.blockMouseFocus or false
	self.automaticSizeCalc = true
	self.children = {}
	self.childrenOrder = {}
	UiElement.load(self)
end

---@param id string
---@param child osu.ui.UiElement
---@return osu.ui.UiElement
function Container:addChild(id, child)
	if self.children[id] then
		error(("Children with the id %s already exist"):format(id))
	end
	self.children[id] = child
	child:load()
	return child
end

---@param id string
function Container:removeChild(id)
	self.children[id] = nil
end

--- Sorts own children by depth
function Container:build()
	local sorted = {}

	for id, child in pairs(self.children) do
		table.insert(sorted, { id = id, depth = child.depth or 0 })
		if self.automaticSizeCalc then
			local x, y = child:getPosition()
			self.totalW = math.max(self.totalW, x + child.totalW)
			self.totalH = math.max(self.totalH, y + child.totalH)
		end
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
---@return osu.ui.UiElement?
function Container:getChild(id)
	return self.children[id]
end

local gfx = love.graphics

---@param dt number
function Container:update(dt)
	gfx.push()

	local mouse_focus = true

	for _, id in ipairs(self.childrenOrder) do
		local child = self.children[id]
		gfx.push()
		gfx.applyTransform(child.transform)
		mouse_focus = child:setMouseFocus(mouse_focus)
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
		child:draw()
		child:debugDraw()
		gfx.pop()
	end
	gfx.pop()
end

return Container
