local Component = require("ui.Component")

---@class ui.Rectangle : ui.Component
---@operator call: ui.Rectangle
---@field rounding number
---@field mode "fill" | "line" 
---@field lineWidth number
local Rectangle = Component + {}

function Rectangle:load()
	self.mode = self.mode or "fill"
	self.lineWidth = self.lineWidth or 1
end

function Rectangle:draw()
	if self.mode == "line" then
		love.graphics.setLineWidth(self.lineWidth)
		love.graphics.rectangle("line", 0, 0, self.width, self.height, self.rounding, self.rounding)
	else
		love.graphics.rectangle("fill", 0, 0, self.width, self.height, self.rounding, self.rounding)
	end
end

return Rectangle
