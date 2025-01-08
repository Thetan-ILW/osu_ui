local class = require("class")

local flux = require("flux")

---@class ui.HoverState
---@operator call: ui.HoverState
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

	if state == "idle" then
		if mouse_over then
			self:fadeIn()
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
		end
	end
end

---@param w number
---@param h number
---@param mx number
---@param my number
---@return boolean
function HoverState:checkMouseFocus(w, h, mx, my)
	local imx, imy = love.graphics.inverseTransformPoint(mx, my)
	local over = imx >= 0 and imx < w and imy >= 0 and imy < h
	self:processState(over)
	return over
end

function HoverState:loseFocus()
	return self:processState(false)
end

return HoverState
