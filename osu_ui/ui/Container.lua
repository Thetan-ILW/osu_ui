local class = require("class")

local just = require("just")
local flux = require("flux")
local math_util = require("math_util")

local Container = class()

Container.scrollLimit = math.huge

local name = ""
local xIndent = 15
local yIndent = 5

function Container:new(id)
	name = id

	self.scroll = 0
	self.scrollTarget = 0
	self.tween = flux.to(self, 0, { scroll = 0 })
end

function Container:reset()
	self.scroll = 0
	self.scrollTarget = 0
	self.tween:stop()
	just.reset()
end

function Container:startDraw(w, h)
	local delta = just.wheel_over(name, just.is_over(w, h))

	if delta then
		self.scrollTarget = self.scrollTarget + (delta * 80)
		self.scrollTarget = math_util.clamp(-self.scrollLimit - yIndent, self.scrollTarget, 0)
		self.tween = flux.to(self, 0.25, { scroll = self.scrollTarget }):ease("quartout")
	end

	just.clip(love.graphics.rectangle, "fill", 0, 0, w, h)
	love.graphics.translate(xIndent, self.scroll + yIndent)
end

function Container:stopDraw()
	just.clip()
end

return Container
