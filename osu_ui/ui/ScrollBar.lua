local Component = require("ui.Component")

---@alias osu.ui.ScrollBarParams { container: osu.ui.ScrollAreaContainer, windowHeight: number, startY: number }

---@class osu.ui.ScrollBar : ui.Component
---@overload fun(params: osu.ui.ScrollBarParams): osu.ui.ScrollBar
---@field container osu.ui.ScrollAreaContainer
---@field windowHeight number
---@field position number
---@field startY number
local ScrollBar = Component + {}

---@param dt number
function ScrollBar:update(dt)
	local c = self.container
	local scroll_limit = c.scrollLimit * 2
	local ratio = self.windowHeight / scroll_limit
	self.y = c.scrollPosition * ((self.windowHeight - self.height) / c.scrollLimit) + self.startY
	self.height = math.max(5, self.windowHeight * ratio)
end

function ScrollBar:draw()
	love.graphics.rectangle("fill", 0, 0, self.width, self.height)
end

return ScrollBar
