local Component = require("ui.Component")

---@class ui.Rectangle : ui.Component
---@operator call: ui.Rectangle
---@field rounding number
local Rectangle = Component + {}

function Rectangle:draw()
	love.graphics.rectangle("fill", 0, 0, self.width, self.height, self.rounding, self.rounding)
end

return Rectangle
