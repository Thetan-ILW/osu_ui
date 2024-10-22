local UiElement = require("osu_ui.ui.UiElement")

---@alias RectangleParams { totalW: number, totalH: number, rounding: number }

---@class osu.ui.Rectangle : osu.ui.UiElement
---@overload fun(params: RectangleParams): osu.ui.Rectangle
---@field rounding number
local Rectangle = UiElement + {}

function Rectangle:draw()
	love.graphics.rectangle("fill", 0, 0, self.totalW, self.totalH, self.rounding, self.rounding)
end

return Rectangle
