local UiElement = require("osu_ui.ui.UiElement")

---@class osu.ui.Spacing : osu.ui.UiElement
---@operator call: osu.ui.Spacing
local Spacing = UiElement + {}

function Spacing:new(size)
	self.totalH = size
end

function Spacing:draw()
	love.graphics.translate(0, self.totalH)
end

return Spacing
