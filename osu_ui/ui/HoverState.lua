local class = require("class")

local flux = require("flux")

---@class osu.ui.HoverState
---@operator call: osu.ui.HoverState
---@field state "idle" | "fade_in" | "fade_out" | "visible"
---@field progress number
---@field ease string
---@field tweenDuration number
---@field tween table?
local HoverState = class()

---@param ease string
---@param tween_duration number
function HoverState:new(ease, tween_duration)
	self.ease = ease
	self.tweenDuration = tween_duration
	self.state = "idle"
	self.progress = 0
end

function HoverState:fadeIn()
	if self.tween then
		self.tween:stop()
	end
	self.tween = flux.to(self, self.tweenDuration, { progress = 1 }):ease(self.ease)
	self.state = "fade_in"
end

function HoverState:fadeOut()
	if self.tween then
		self.tween:stop()
	end
	self.tween = flux.to(self, self.tweenDuration, { progress = 0 }):ease(self.ease)
	self.state = "fade_out"
end

function HoverState:processState(mouse_over)
	local state = self.state
	local just_hovered = false

	if state == "idle" then
		if mouse_over then
			self:fadeIn()
			just_hovered = true
		end
	elseif state == "fade_in" then
		if self.progress == 1 then
			self.state = "visible"
		end
		if not mouse_over then
			self:fadeOut()
		end
	elseif state == "visible" then
		if not mouse_over then
			self:fadeOut()
		end
	elseif state == "fade_out" then
		if self.progress == 0 then
			self.state = "idle"
		end
		if mouse_over then
			self:fadeIn()
			just_hovered = true
		end
	end

	return mouse_over, just_hovered
end

---@param w number
---@param h number
---@param x number?
---@param y number?
---@return boolean
---@return boolean
function HoverState:check(w, h, x, y)
	local mx, my = love.graphics.inverseTransformPoint(love.mouse.getPosition())
	local over = mx >= x and mx < w and my >= y and my < h
	return self:processState(over)
end

function HoverState:loseFocus()
	return self:processState(false)
end

return HoverState
