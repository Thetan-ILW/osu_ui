local Component = require("ui.Component")

local math_util = require("math_util")
local flux = require("flux")

---@class osu.ui.Slider : ui.Component
---@operator call: osu.ui.Slider
---@field min number
---@field max number
---@field step number
---@field setValue fun(v: number)
---@field getValue fun(): number
local Slider = Component + {}

local radius = 8

function Slider:load()
	self.height = self.height or 37
	self.dragging = false
	self.value = 0
	self.target = 0

	self.mouseOrigin = { x = 0, y = 0 }

	self.circle = self:addChild("circle", Component({
		y = self.height / 2,
		width = radius * 2,
		height = radius * 2,
		origin = { x = 0.5, y = 0.5 },
		color = { 0.89, 0.47, 0.56, 1 },
		z = 1,
		draw = function ()
			love.graphics.setLineStyle("smooth")
			love.graphics.setLineWidth(1)
			love.graphics.circle("line", radius, radius, radius)
		end
	}))

	self:addChild("line1", Component({
		y = self.height / 2,
		color = { 0.89, 0.47, 0.56, 1 },
		draw = function ()
			love.graphics.setLineStyle("rough")
			love.graphics.setLineWidth(1)
			love.graphics.line(0,0, math.max(0, self.circle.x-radius),0)
		end
	}))

	self:addChild("line2", Component({
		y = self.height / 2,
		color = { 0.89, 0.47, 0.56, 0.6 },
		draw = function ()
			love.graphics.setLineStyle("rough")
			love.graphics.setLineWidth(1)
			love.graphics.line(math.min(self.width, self.circle.x+radius),0, self.width, 0)
		end
	}))

	self.sliderBar = self.shared.assets:loadAudio("sliderbar")
end

function Slider:bindEvents()
	self.parent:bindEvent(self, "mousePressed")
	self.parent:bindEvent(self, "mouseReleased")
	self.parent:bindEvent(self, "keyPressed")
	self.parent:bindEvent(self, "mouseClick")
end

function Slider:mousePressed()
	if self.mouseOver then
		self.dragging = true
		self.allowDrag = false
		self.mouseOrigin.x = love.mouse.getX()
		self.mouseOrigin.y = love.mouse.getY()
		return true
	end
	return false
end

function Slider:mouseReleased()
	self.dragging = false
end

function Slider:keyPressed(event)
	if not self.mouseOver then
		return false
	end

	local key = event[2]
	local direction = 0

	if key == "left" then
		direction = -1
	elseif key == "right" then
		direction = 1
	else
		return false
	end

	self.setValue(math_util.clamp(self.getValue() + direction, self.min, self.max))
	self.playSound(self.sliderBar, 0.065)
	return true
end

function Slider:mouseClick()
	if self.mouseOver then
		self.pleaseDragToX = love.mouse.getX()
		return true
	end
	return false
end

function Slider:drag(mx)
	local imx, imy = love.graphics.inverseTransformPoint(mx, 0)
	local p = math_util.clamp((imx - radius) / (self.width - radius * 2), 0, 1)
	local target = math_util.round(p * (self.max - self.min) + self.min, self.step)

	if self.target ~= target then
		if self.tween then
			self.tween:stop()
		end
		self.tween = flux.to(self, 0.1, { value = target }):ease("quadout"):onupdate(function ()
			self.setValue(self.value)
			self.sliderBar:setRate(1 + ((self.value - self.min) / (self.max - self.min)) * 0.2)
			self.playSound(self.sliderBar, 0.065)
		end)
		self.target = target
	end
end

function Slider:update()
	if self.pleaseDragToX then
		self:drag(self.pleaseDragToX)
		self.pleaseDragToX = nil
	elseif self.dragging then
		local mx, my = love.mouse.getPosition()

		local dx, dy = mx - self.mouseOrigin.x, my - self.mouseOrigin.y
		local angle = math.atan2(dy, dx)
		local epsilon = 0.5

		local adx = math.abs(dx)

		if adx > 2 and not self.allowDrag then
			if math.abs(angle) < epsilon or math.abs(math.pi - angle) < epsilon then
				self.allowDrag = true
				self:getViewport():receive( { name = "loseFocus" } )
			end
			if adx > 5 then
				self.dragging = false
			end
		end

		if self.allowDrag then
			self:drag(mx)
		end
	end

	local p = (self.getValue() - self.min) / (self.max - self.min)
	self.circle.x = radius + ((self.width - radius * 2) * p)
end

return Slider
