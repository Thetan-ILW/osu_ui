local class = require("class")

---@alias Color [number, number, number, number]
---@alias ProtoOrigin { x: number, y: number }

---@class osu.ui.UiElement
---@operator call: osu.ui.UiElement
---@field transform love.Transform
---@field originalTransform love.Transform
---@field origin ProtoOrigin
---@field depth number
---@field totalW number
---@field totalH number
---@field color Color
---@field alpha number
---@field mouseOver boolean
---@field blockMouseFocus boolean
local UiElement = class()

function UiElement:load()
	self.transform = self.transform or love.math.newTransform()
	self.originalTransform = self.transform:clone()
	self.origin = self.origin or { x = 0, y = 0 }
	self.depth = self.depth or 0
	self.color = self.color or { 1, 1, 1, 1 }
	self.alpha = self.alpha or 1
	self.totalW, self.totalH = self.totalW or 0, self.totalH or 0
	self.mouseOver = false
	self.blockMouseFocus = true
end

---@param tf love.Transform
function UiElement:replaceTransform(tf)
	tf:apply(love.math.newTransform(0, 0, 0, 1, 1, self:getOrigin()))
	self.transform = tf:clone()
	self.originalTransform = tf:clone()
end

---@return number
---@return number
function UiElement:getOrigin()
	assert(self.totalW > 0 and self.totalH > 0, "Size of the UI Element is not defined")
	return self.totalW * self.origin.x, self.totalH * self.origin.y
end

function UiElement:resetTransform()
	self.transform = self.originalTransform:clone()
end

--- Use to animate the properties
function UiElement:updateTransform() end

---@return number
---@return number
function UiElement:getDimensions()
	return self.totalW, self.totalH
end

---@return number
function UiElement:getWidth()
	return self.totalW
end

---@return number
function UiElement:getHeight()
	return self.totalH
end

---@return number
---@return number
function UiElement:getPosition()
	return self.transform:transformPoint(0, 0)
end

---@param has_focus boolean
---@return boolean blocking_focus
function UiElement:setMouseFocus(has_focus)
	if not has_focus then
		self.mouseOver = false
		return false
	end

	local mx, my = love.graphics.inverseTransformPoint(love.mouse.getPosition())
	self.mouseOver = mx >= 0 and mx < self.totalW and my >= 0 and my < self.totalH
	return not (self.mouseOver and self.blockMouseFocus)
end

---@param dt number
function UiElement:update(dt) end
function UiElement:draw() end

local gfx = love.graphics

function UiElement:debugDraw()
	gfx.setColor(1, 0, 0)
	if not self.mouseOver then
		gfx.setColor(1, 0, 0, 0.2)
	end

	gfx.setLineWidth(2)
	gfx.rectangle("line", 0, 0, self.totalW, self.totalH)
	local ox, oy = self:getOrigin()
	gfx.circle("line", ox, oy, 5)

	gfx.setColor(0, 1, 0, 0.8)
	gfx.circle("line", 0, 0, 2)
end

return UiElement
