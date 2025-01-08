local Component = require("ui.Component")

local flux = require("flux")

---@class osu.ui.Screen : ui.Component
---@operator call: osu.ui.Screen
---@field transititionTween table?
local Screen = Component + {}

---@param params? { time: number?, ease: string?, onComplete: function? }
function Screen:transitOut(params)
	if not self.handleEvents then
		return
	end
	self.handleEvents = false

	if self.transitionTween then
		self.transitionTween:stop()
	end

	local time = 0.4
	local ease = "quadout"
	local on_complete ---@type function?
	if params then
		time = params.time or time
		ease = params.ease or ease
		on_complete = params.onComplete
	end

	self.transitionTween = flux.to(self, time, { alpha = 0 }):ease(ease):oncomplete(function()
		self.disabled = true
		if on_complete then
			on_complete()
		end
	end)
end

---@param params? { time: number?, ease: string }
function Screen:transitIn(params)
	self.disabled = false
	self.handleEvents = true

	if self.transitionTween then
		self.transitionTween:stop()
	end

	local time = 0.4
	local ease = "quadout"
	if params then
		time = params.time or time
		ease = params.ease or ease
	end
	self.transitionTween = flux.to(self, time, { alpha = 1 }):ease(ease)
end

return Screen
