local UiElement = require("osu_ui.ui.UiElement")

---@class osu.ui.ScrollBar : osu.ui.UiElement
---@operator call: osu.ui.ScrollBar
---@field container osu.ui.ScrollAreaContainer
---@field windowHeight number
local ScrollBar = UiElement + {}

---@param params { container: osu.ui.ScrollAreaContainer, windowHeight: number }
function ScrollBar:new(params)
	UiElement.new(self, params)
	self.container = params.container
	self.windowHeight = params.windowHeight
end

local gfx = love.graphics

function ScrollBar:draw()
	local c = self.container
	local scroll_limit = c.scrollLimit * 2
	local ratio = self.windowHeight / scroll_limit
	local size = self.windowHeight * ratio
	local position = c.scrollPosition * ((self.windowHeight - size) / c.scrollLimit)
	gfx.setColor(1, 1, 1)
	gfx.rectangle("fill", 0, position, 10, size)
end

return ScrollBar
