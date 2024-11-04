local UiElement = require("osu_ui.ui.UiElement")

---@alias ScrollBarParams { container: osu.ui.ScrollAreaContainer, windowHeight: number, totalW: number, startY: number }

---@class osu.ui.ScrollBar : osu.ui.UiElement
---@overload fun(params: ScrollBarParams): osu.ui.ScrollBar
---@field container osu.ui.ScrollAreaContainer
---@field windowHeight number
---@field position number
---@field totalW number
---@field totalH number
---@field startY number
local ScrollBar = UiElement + {}

local gfx = love.graphics

---@param dt number
function ScrollBar:update(dt)
	local c = self.container
	local scroll_limit = c.scrollLimit * 2
	local ratio = self.windowHeight / scroll_limit
	self.y = c.scrollPosition * ((self.windowHeight - self.totalH) / c.scrollLimit) + self.startY
	self.totalH = math.max(5, self.windowHeight * ratio)
	self:applyTransform()
end

function ScrollBar:draw()
	gfx.rectangle("fill", 0, 0, self.totalW, self.totalH)
end

return ScrollBar
